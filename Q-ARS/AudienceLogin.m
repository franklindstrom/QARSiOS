//
//  AudienceLogin.m
//  Q-ARS
//
//  Created by FrankLindstrom on 4/28/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudienceLogin.h"
#import "ScanViewController.h"
#import <sys/utsname.h>

@interface AudienceLogin() {
    NSMutableData *responseData;
    NSUserDefaults *database;
    NSString *request_param;
    NSString *device_id;
    NSString *device_name;
    NSInteger request_type;
    
    NSString *firstName, *lastName, *gender, *birthday, *email, *country, *friendsCount, *friendName;
}

@end

@implementation AudienceLogin

-(void) viewDidLoad {
    [super viewDidLoad];
    
    responseData = [[NSMutableData alloc] init];
    database = [NSUserDefaults standardUserDefaults];
    
    if ([database objectForKey: @"logo_url"] != NULL) {
        [self.connecting_layout setHidden: false];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL: [NSURL URLWithString: [database objectForKey: @"logo_url"]]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the UI
                [self.connecting_layout setHidden: true];
                [self.mark setImage: [UIImage imageWithData: imageData]];
            });
        });
    }
    
    [self.facebook_layout.layer setCornerRadius: 5];
    [self.google_layout.layer setCornerRadius: 5];
    [self.twitter_layout.layer setCornerRadius: 5];
    [self.linkedin_layout.layer setCornerRadius: 5];
    [self.btn_email_login.layer setCornerRadius: 5];
    
    [self.connecting_layout setHidden: true];
    
    [self.txt_email setDelegate: self];
    [self.txt_email setReturnKeyType: UIReturnKeyDone];
    [self.txt_email setAutocorrectionType: UITextAutocorrectionTypeNo];
    
    device_id = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    device_name = [NSString stringWithFormat: @"%@-%@-%@", [UIDevice currentDevice].name, [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
    device_name = [device_name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    [database setObject: device_id forKey: @"device_id"];
    [database setObject: device_name forKey: @"device_name"];
    [database synchronize];
}

// get device info
NSString* deviceName() {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

-(BOOL) textFieldShouldBeginEditing: (UITextField *) textField {
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) self.view.frame = CGRectMake(0, -200, self.view.frame.size.width, self.view.frame.size.height);
    return true;
}

-(BOOL) textFieldShouldEndEditing: (UITextField *) textField {
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    return true;
}

-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    [textField endEditing: true];
    return true;
}

// login with Facebook
- (IBAction)onFacebookLogin:(UIButton *)sender {
    [self.connecting_layout setHidden: false];
    [self.connecting_title setText: @"Connecting with Facebook account..."];
    
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logInWithReadPermissions: @[@"public_profile", @"user_friends", @"user_birthday", @"user_about_me", @"email", @"user_location"] fromViewController:self handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            [self onCreateAlertDialog: @"An error has occured" : nil];
        } else if (result.isCancelled) {
            [self onCreateAlertDialog: @"User cancelled Facebook SignIn" : nil];
        } else {
            // get user information
            NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
            [parameters setValue:@"id,first_name,last_name,email,birthday,gender,location,friends" forKey:@"fields"];
            [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                [self.connecting_layout setHidden: false];
                
                if (error) {
                    [self onCreateAlertDialog: @"An error has occured" : nil];
                } else {
                    firstName = [result objectForKey: @"first_name"];
                    lastName = [result objectForKey: @"last_name"];
                    gender = [result objectForKey: @"gender"];
                    email = [result objectForKey: @"email"];
                    birthday = [result objectForKey: @"birthday"];
                    
                    NSDictionary *country_data = [result objectForKey: @"location"];
                    country = [[country_data objectForKey: @"name"] stringByReplacingOccurrencesOfString: @", " withString: @","];
                    
                    NSDictionary *friends_data = [result objectForKey: @"friends"];
                    
                    friendName = @"";
                    NSArray *friends_list = [friends_data objectForKey: @"data"];
                    for (NSDictionary *friend in friends_list) {
                        friendName = [friendName stringByAppendingString: [[friend objectForKey: @"name"] stringByReplacingOccurrencesOfString: @" " withString: @""]];
                        friendName = [friendName stringByAppendingString: @","];
                    }
                    
                    NSDictionary *friends_counts = [friends_data objectForKey: @"summary"];
                    friendsCount = [friends_counts objectForKey: @"total_count"];
                    
                    request_param = [NSString stringWithFormat: @"socialType=fb&firstName=%@&lastName=%@&gender=%@&email=%@&dob=%@&deviceID=%@&country=%@&education=&relationship=&friends_count=%@&followers_count=&profession=&device_info=%@&OS=iOS&social_friend=%@",
                                     firstName, lastName, gender, email, birthday, device_id, country, friendsCount, device_name, friendName];
                    [self onConnectToServer: request_param];
                }
            }];
        }
    }];
    
    [login logOut];
}

// login with Google+
- (IBAction)onGoogleLogin: (UIButton *) sender {
    [self.connecting_layout setHidden: false];
    [self.connecting_title setText: @"Connecting with Google+ account..."];
    
    GIDSignIn *gppSignIn = [GIDSignIn sharedInstance];
    
    gppSignIn.uiDelegate = self;
    gppSignIn.delegate = self;
    gppSignIn.scopes = [NSArray arrayWithObjects: @"plus.login", @"plus.me", nil];
    gppSignIn.shouldFetchBasicProfile = true;
    gppSignIn.allowsSignInWithWebView = true;
    gppSignIn.allowsSignInWithBrowser = true;
    gppSignIn.scopes = [NSArray arrayWithObjects: @"https://www.googleapis.com/auth/plus.login", @"https://www.googleapis.com/auth/plus.me", nil];
    gppSignIn.clientID = @"651264949192-d8ctd5sgj9rhlb3ujal0oiv7s65c6tvl.apps.googleusercontent.com";
    
    // Uncomment to automatically sign in the user.
    [gppSignIn signIn];
}

// get Google+ profile data
- (void)signIn: (GIDSignIn *) signIn didSignInForUser: (GIDGoogleUser *) user withError: (NSError *) error {
    [self.connecting_layout setHidden: false];
    
    firstName = user.profile.givenName;
    lastName = user.profile.familyName;
    email = user.profile.email;
    
    request_type = 1;
    
    NSString *server_url = @"https://www.googleapis.com/plus/v1/people/me";
    server_url = [server_url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString: server_url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 180.0];
    [request addValue: [NSString stringWithFormat: @"Bearer %@", user.authentication.accessToken] forHTTPHeaderField: @"Authorization"];
    [request setHTTPMethod: @"GET"];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: request delegate:self];
    [connection start];
}

// Google+ login has canceled
- (void)signIn: (GIDSignIn *) signIn didDisconnectWithUser: (GIDGoogleUser *) user withError: (NSError *) error {
    [self.connecting_layout setHidden: true];
    
    [self onCreateAlertDialog: @"An error has occurred" : nil];
}

// login with Twitter
- (IBAction)onTwitterLogin:(UIButton *)sender {
    [self.connecting_layout setHidden: false];
    [self.connecting_title setText: @"Connecting with Twitter account..."];
    
    [[Twitter sharedInstance] logInWithMethods: TWTRLoginMethodWebBased completion: ^(TWTRSession *session, NSError *error) {
        if (!error) {
            // get Twitter profile data
            [self.connecting_layout setHidden: false];
            
            TWTRAPIClient *client = [TWTRAPIClient clientWithCurrentUser];
            NSURLRequest *request = [client URLRequestWithMethod: @"GET"
                                                                   URL: @"https://api.twitter.com/1.1/account/verify_credentials.json"
                                                            parameters: @{@"include_email": @"true", @"skip_status": @"true"}
                                                                 error: nil];
            
            [client sendTwitterRequest: request completion: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                [self.connecting_layout setHidden: false];
                
                NSError *error;
                NSDictionary *profile = [NSJSONSerialization JSONObjectWithData: data options:0 error: &error];
                
                firstName = [profile objectForKey: @"name"];
                lastName = [profile objectForKey: @"screen_name"];
                country = [[profile objectForKey: @"location"] stringByReplacingOccurrencesOfString: @", " withString: @""];
                country = [country stringByReplacingOccurrencesOfString: @" " withString: @""];
                
                request_param = [NSString stringWithFormat: @"socialType=fb&firstName=%@&lastName=%@&gender=&email=&dob=&deviceID=%@&country=&education=&relationship=&friends_count=&followers_count=&profession=&device_info=%@&OS=iOS&social_friend=",
                                 firstName, lastName, device_id, device_name];
                [self onConnectToServer: request_param];
                
                TWTRSessionStore *store = [[Twitter sharedInstance] sessionStore];
                [store logOutUserID: session.userID];
            }];
        } else {
            [self onCreateAlertDialog: @"An error has occured" : nil];
        }
    }];
}

// login with Linkedin
- (IBAction)onLinkedinLogin:(UIButton *)sender {
    NSString *authUrl = [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/authorization?response_type=code&client_id=%@&scope=%@&state=%@&redirect_uri=%@" ,
                         @"77gio39d6ggfoa",
                         @"r_basicprofile,r_emailaddress",
                         @"ASDKASIIWER23432KKQ",
                         @"https://api.linkedin.com/v1/people/~?format=json"];
    
    [database setObject: authUrl forKey: @"oauth_url"];
    [database synchronize];
    
    [self.navigationController pushViewController: [self.storyboard instantiateViewControllerWithIdentifier: @"LinkedinLoginView"] animated: true];
}

// login with Email
- (IBAction)onEmailLogin:(UIButton *)sender {
    [self.txt_email endEditing: true];
    [self.connecting_layout setHidden: true];
    
    if ([self.txt_email.text isEqualToString: @""]) {
        [self onCreateAlertDialog: @"Please enter your email address" : self.txt_email];
    } else {
        request_param = [NSString stringWithFormat: @"socialType=email&firstName=&lastName=&gender=&email=%@&dob=&deviceID=%@&country=&education=&relationship=&friends_count=&followers_count=&profession=&device_info=%@&OS=iOS&social_friend=", self.txt_email.text, device_id, device_name];
        [self.connecting_layout setHidden: false];
        [self onConnectToServer: request_param];
    }
}

// show alert dialog
-(void) onCreateAlertDialog: (NSString *)message : (UITextField *) text_field {
    UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"Q-ARS Says" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self.connecting_layout setHidden: true];
        [alert dismissViewControllerAnimated:YES completion:nil];
        if (text_field != nil) [text_field becomeFirstResponder];
    }];
    
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// connect to server with the social user information
-(void) onConnectToServer: (NSString *) param {
    [self.connecting_title setText: @"Connecting to server..."];
    
    request_type = 0;
    
    NSString *server_url = @"https://q-ars.com/api/account.php?";
    
    NSString *url_str = [NSString stringWithFormat: @"%@%@", server_url, param];
    url_str = [url_str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURL *url = [NSURL URLWithString: url_str];
    NSString *request_length = [NSString stringWithFormat:@"%lu", (unsigned long)[param length]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 180.0];
    [request addValue: @"text/xml; charset=utf-8" forHTTPHeaderField: @"Content-Type"];
    [request addValue: request_length forHTTPHeaderField: @"Content-Length"];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: [param dataUsingEncoding: NSUTF8StringEncoding]];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: request delegate:self];
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.connecting_layout setHidden: true];
    NSLog(@"Server error: %@", error);
    [self onCreateAlertDialog: @"An error has occurred" : nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // convert to JSON
    NSError *myError = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData: responseData options: NSJSONReadingMutableLeaves error: &myError];
    
    if (request_type == 1) {
        [[GIDSignIn sharedInstance] signOut];
        [self.connecting_layout setHidden: true];
        birthday = [data objectForKey: @"birthday"];
        gender = [data objectForKey: @"gender"];
        
        request_param = [NSString stringWithFormat: @"socialType=fb&firstName=%@&lastName=%@&gender=%@&email=%@&dob=%@&deviceID=%@&country=&education=&relationship=&friends_count=&followers_count=&profession=&device_info=%@&OS=iOS&social_friend=%@",
                         firstName, lastName, gender, email, birthday, device_id, device_name, friendName];
        [self onConnectToServer: request_param];
        
    } else {
        // check login result
        NSString *user_id = [data objectForKey: @"uid"];
        [database setObject: user_id forKey: @"user_id"];
        
        self.connecting_layout.hidden = true;
        self.txt_email.text = @"";
        
        ScanViewController *scanVC = [[ScanViewController alloc] init];
        [self.navigationController pushViewController: scanVC animated: true];
    }
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end