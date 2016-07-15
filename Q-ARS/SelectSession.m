//
//  SelectSession.m
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SelectSession.h"

@interface SelectSession() {
    NSMutableData *responseData;
    NSUserDefaults *database;
    NSString *email, *password;
}

@end

@implementation SelectSession

-(void) viewDidLoad {
    [super viewDidLoad];
    
    responseData = [[NSMutableData alloc] init];
    database = [NSUserDefaults standardUserDefaults];
    
    email = [database objectForKey: @"speaker_email"];
    password = [database objectForKey: @"speaker_pwd"];
    
    [self.btn_create_session.layer setCornerRadius: 5];
    
    [self onAddSession];
}

-(void) onAddSession {
    [self.connecting_layout setHidden: true];
    
    int session_counts = (int)[database integerForKey: @"session_counts"];
    for (int i = 0; i < session_counts; i++) {
        NSString *session_data = [database objectForKey: [NSString stringWithFormat: @"session_%d", i + 1]];
        NSArray *ary = [session_data componentsSeparatedByString: @","];
        
        // add session button to parent view
        UIButton *btn_session = [[UIButton alloc] init];
        
        [btn_session setTitle: [ary objectAtIndex: 2] forState: UIControlStateNormal];
        [btn_session.titleLabel setFont: [UIFont boldSystemFontOfSize: 15]];
        [btn_session setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
        [btn_session setBackgroundColor: [UIColor colorWithRed:0.149 green:0.651 blue:0.604 alpha:1]];
        [btn_session setTag: [[ary objectAtIndex: 1] integerValue]];
        [btn_session.layer setCornerRadius: 5];
        [btn_session setFrame: CGRectMake(0, 50 * i, self.session_container.frame.size.width, 40)];
        [btn_session setContentMode: UIViewContentModeScaleAspectFit];
        
        [btn_session addTarget: self action: @selector(onSessionSelected:) forControlEvents: UIControlEventTouchUpInside];
        
        [self.session_container addSubview: btn_session];
        [self.session_container setContentSize: CGSizeMake(self.session_container.frame.size.width, 50 * i)];
    }
}

-(void) onSessionSelected: (UIButton *) session {
    [database setInteger: session.tag forKey: @"selected_session_id"];
    [database synchronize];
    [self.navigationController pushViewController: [self.storyboard instantiateViewControllerWithIdentifier: @"PresentationTime"] animated: true];
}

- (IBAction)onRefreshData:(UIButton *)sender {
    [self.connecting_layout setHidden: false];
    
    NSString *server_url = @"https://q-ars.com/PowerpointApi/login.php?";
    NSString *request_param = [NSString stringWithFormat: @"userName=%@&pwd=%@", email, password];
    
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

- (IBAction)onCreateSession:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://q-ars.com/signin"]];
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.connecting_layout setHidden: true];
    
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
        [database synchronize];
        
        // move to next screen
        [self onAddSession];
    }
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end