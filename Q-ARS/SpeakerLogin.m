//
//  SpeakerLogin.m
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpeakerLogin.h"

@interface SpeakerLogin() {
    NSUserDefaults *database;
    NSMutableData *responseData;
}

@end

@implementation SpeakerLogin

-(void) viewDidLoad {
    [super viewDidLoad];
    
    database = [NSUserDefaults standardUserDefaults];
    responseData = [[NSMutableData alloc] init];
    
    if ([database objectForKey: @"logo_url"] == NULL) {
        [self.connecting_view setHidden: true];
        [self.txt_email becomeFirstResponder];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL: [NSURL URLWithString: [database objectForKey: @"logo_url"]]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the UI
                [self.connecting_view setHidden: true];
                [self.mark setImage: [UIImage imageWithData: imageData]];
                [self.txt_email becomeFirstResponder];
            });
        });
    }
    
    [self.btn_signin.layer setCornerRadius: 5];
    [self.btn_signup.layer setCornerRadius: 5];
    
    [self.txt_email setDelegate: self];
    [self.txt_email setReturnKeyType: UIReturnKeyNext];
    [self.txt_email setAutocorrectionType: UITextAutocorrectionTypeNo];
    
    [self.txt_password setDelegate: self];
    [self.txt_password setReturnKeyType: UIReturnKeyDone];
    [self.txt_password setAutocorrectionType: UITextAutocorrectionTypeNo];
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    if (textField == self.txt_email) {
        [self.txt_password becomeFirstResponder];
    } else {
        [textField endEditing:YES];
    }
    return YES;
}

- (IBAction)onButtonClicked:(UIButton *)sender {
    [self.txt_email endEditing: true];
    [self.txt_password endEditing: true];
    
    if (sender == self.btn_signin) {
        if ([self onCheckTexts]) {
            [self onLoginToSpeaker];
        }
    } else if (sender == self.btn_signup) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://q-ars.com/signup"]];
    }
}

// show alert dialog
-(void) onCreateAlertDialog: (NSString *)message : (UITextField *) text_field {
    UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"Q-ARS Says" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
        if (text_field != nil) [text_field becomeFirstResponder];
    }];
    
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// check the text content of email and password
-(BOOL) onCheckTexts {
    if ([self.txt_email.text isEqualToString: @""]) {
        [self onCreateAlertDialog: @"Please Enter Your Email Address" : self.txt_email];
        return false;
    } else if (![self.txt_email.text containsString: @"@"] && ![self.txt_email.text containsString: @".com"]) {
        [self onCreateAlertDialog: @"This is not an email address" : self.txt_email];
        return false;
    } else if ([self.txt_password.text isEqualToString: @""]) {
        [self onCreateAlertDialog: @"Please Enter the Password" : self.txt_password];
        return false;
    }
    
    return true;
}

// log into the server by speaker
-(void) onLoginToSpeaker {
    [self.connecting_view setHidden: false];
    
    NSString *server_url = @"https://q-ars.com/PowerpointApi/login.php?";
    NSString *request_param = [NSString stringWithFormat: @"userName=%@&pwd=%@", self.txt_email.text, self.txt_password.text];
    
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"%@%@", server_url, request_param]];
    NSString *request_length = [NSString stringWithFormat:@"%lu", (unsigned long)[request_param length]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 180.0];
    [request addValue: @"application/json;charset=UTF-8" forHTTPHeaderField: @"Content-Type"];
    [request addValue: request_length forHTTPHeaderField: @"Content-Length"];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: [request_param dataUsingEncoding: NSUTF8StringEncoding]];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: request delegate:self];
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.connecting_view setHidden: true];
    
    // convert to JSON
    NSError *myError = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData: responseData options: NSJSONReadingMutableLeaves error: &myError];
    
    NSLog(@"%@", data);
    
    // check login result
    NSInteger status = [[data objectForKey: @"status"] integerValue];
    if (status == 0) {
        // login failed, invalid login info...
        NSString *msg = [data objectForKey: @"msg"];
        [self onCreateAlertDialog: msg : nil];
    } else {
        // login success
        NSArray *results = [data objectForKey:@"Accounts"];
        
        for (NSDictionary *result in results) {
            NSString *client_id = [result objectForKey:@"ClientID"];
            NSString *uId = [result objectForKey: @"uID"];
            NSString *sName = [result objectForKey: @"sName"];
            
            NSString *session_data = [NSString stringWithFormat: @"%@,%@,%@", client_id, uId, sName];
            [database setObject: session_data forKey: [NSString stringWithFormat: @"session_%d", (int)[results indexOfObject: result] + 1]];
            NSString *logo_path = [result objectForKey: @"LogoFullPath"];
            if (logo_path != nil && ![logo_path isEqualToString: @""] && ![[[logo_path componentsSeparatedByString: @"/"] objectAtIndex: 3] isEqualToString:@""]) {
                [database setObject: [NSString stringWithFormat: @"https://%@", [result objectForKey: @"LogoFullPath"]] forKey: @"logo_url"];
            }
            [database synchronize];
        }
        
        [database setInteger: [results count] forKey: @"session_counts"];
        [database setObject: self.txt_email.text forKey: @"speaker_email"];
        [database setObject: self.txt_password.text forKey: @"speaker_pwd"];
        [database synchronize];
        
        // move to next screen
        [self.txt_email setText: @""];
        [self.txt_password setText: @""];
        [self.navigationController pushViewController: [self.storyboard instantiateViewControllerWithIdentifier: @"SelectSession"] animated: true];
        
        [self.mark setImage: [UIImage imageNamed: @"mark.png"]];
    }
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end