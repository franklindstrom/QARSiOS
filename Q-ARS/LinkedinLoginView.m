//
//  LinkedinLoginView.m
//  Q-ARS
//
//  Created by FrankLindstrom on 4/29/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LinkedinLoginView.h"
#import "ScanViewController.h"
#import <sys/utsname.h>

@interface LinkedinLoginView() {
    NSMutableData *responseData;
    NSUserDefaults *database;
    
    NSString *oauth_url;
    NSString *code, *client_id, *redirect_url;
    
    NSInteger request_type;
}

@end

@implementation LinkedinLoginView

-(void) viewDidLoad {
    [super viewDidLoad];
    
    responseData = [[NSMutableData alloc] init];
    database = [NSUserDefaults standardUserDefaults];
    oauth_url = [database objectForKey: @"oauth_url"];
    
    client_id = @"77gio39d6ggfoa";
    redirect_url = @"https://api.linkedin.com/v1/people/~?format=json";
    
    [self.loading_view setHidden: true];
    
    [self.oauth_web_view setDelegate: self];
    [self.oauth_web_view loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: oauth_url]]];
}

- (void) webView: (UIWebView *) webView didFailLoadWithError: (NSError *) error {
    UIAlertController * alert = [UIAlertController alertControllerWithTitle: @"Q-ARS Says" message: @"An error has occurred" preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle: @"OK" style: UIAlertActionStyleDefault handler: ^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated: YES completion: nil];
        [self.navigationController popViewControllerAnimated: true];
    }];
    
    [alert addAction: ok];
    [self presentViewController:alert animated: YES completion: nil];
}

- (BOOL) webView: (UIWebView *) webView shouldStartLoadWithRequest: (NSURLRequest *) request navigationType: (UIWebViewNavigationType) navigationType {
    NSURL *url = request.URL;
    NSArray *url_params = [url.absoluteString componentsSeparatedByString: @"&"];
    for (NSString *url_param in url_params) {
        NSArray *param = [url_param componentsSeparatedByString:@"="];
        if (param.count > 1) {
            NSString *key = param[0];
            NSString *value = param[1];
            
            if (code == nil && [key isEqualToString: @"code"]) code = value;
        }
    }
    
    if (code != NULL) {
        NSString *authUrl = [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/accessToken?grant_type=authorization_code&code=%@&redirect_uri=%@&client_id=%@&client_secret=%@", code, redirect_url, client_id, @"dKbuJDaCY2iv9wPI"];
        
        authUrl = [authUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *url = [NSURL URLWithString: authUrl];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 180.0];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod: @"POST"];
        
        request_type = 0;
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: request delegate:self];
        [connection start];
    }
    
    return true;
}

// get linkedin profile data
-(void) getLIAccountData: (NSString *) server_url {
    NSURL *url = [NSURL URLWithString: server_url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 180.0];
    [request addValue: @"json" forHTTPHeaderField: @"x-li-format"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod: @"GET"];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: request delegate:self];
    [connection start];
}

// connect to server with the social user information
-(void) onConnectToServer: (NSString *) param {
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

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.loading_view setHidden: true];
    
    // convert to JSON
    NSError *myError = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData: responseData options: NSJSONReadingMutableLeaves error: &myError];
    
    if (request_type == 0) {
        if ([data objectForKey: @"access_token"] != nil) {
            request_type = 1;
            [self getLIAccountData:
             [NSString stringWithFormat:
              @"https://api.linkedin.com/v1/people/~:(id,first-name,last-name,num-connections,location,email-address)?oauth2_access_token=%@&format=json",
              [data objectForKey: @"access_token"]]];
        }
    } else if (request_type == 1) {
        if ([data objectForKey: @"id"] != nil) {
            [self.oauth_web_view setHidden: true];
            [self.loading_view setHidden: false];
            
            NSDictionary *location = [data objectForKey: @"location"];
            NSString *country = [[location objectForKey: @"name"] stringByReplacingOccurrencesOfString: @", " withString: @","];
            
            request_type = 2;
            
            NSString *request_param = [NSString stringWithFormat: @"socialType=fb&firstName=%@&lastName=%@&gender=&email=%@&dob=&deviceID=%@&country=%@&education=&relationship=&friends_count=&followers_count=&profession=&device_info=%@&OS=iOS&social_friend=",
                             [data objectForKey: @"firstName"], [data objectForKey: @"lastName"], [data objectForKey: @"emailAddress"], [database objectForKey: @"device_id"], country, [database objectForKey: @"device_name"]];
            [self onConnectToServer: request_param];
        }
    } else if (request_type == 2) {
        [self.loading_view setHidden: true];
        
        NSString *user_id = [data objectForKey: @"uid"];
        [database setObject: user_id forKey: @"user_id"];
        
        ScanViewController *scanVC = [[ScanViewController alloc] init];
        [self.navigationController pushViewController: scanVC animated: true];
        
        NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: self.navigationController.viewControllers];
        NSInteger self_index = [navigationArray indexOfObject: self];
        [navigationArray removeObjectAtIndex: self_index];
        self.navigationController.viewControllers = navigationArray;
    }
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end