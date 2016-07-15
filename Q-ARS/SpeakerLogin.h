//
//  SpeakerLogin.h
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpeakerLogin : UIViewController <UITextFieldDelegate, NSURLConnectionDataDelegate>
@property (weak, nonatomic) IBOutlet UIView *connecting_view;
@property (weak, nonatomic) IBOutlet UIImageView *mark;
@property (weak, nonatomic) IBOutlet UITextField *txt_email;
@property (weak, nonatomic) IBOutlet UITextField *txt_password;
@property (weak, nonatomic) IBOutlet UIButton *btn_signin;
@property (weak, nonatomic) IBOutlet UIButton *btn_signup;

- (IBAction)onButtonClicked:(UIButton *)sender;

@end
