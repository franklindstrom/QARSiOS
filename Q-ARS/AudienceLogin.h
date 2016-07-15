//
//  AudienceLogin.h
//  Q-ARS
//
//  Created by FrankLindstrom on 4/28/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKLoginKit/FBSDKLoginManager.h>
#import <FBSDKLoginKit/FBSDKLoginManagerLoginResult.h>
#import <FBSDKCoreKit/FBSDKGraphRequest.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <TwitterKit/TwitterKit.h>
#import <TwitterCore/TwitterCore.h>

@interface AudienceLogin : UIViewController <UITextFieldDelegate, UIWebViewDelegate, NSURLConnectionDataDelegate, GIDSignInDelegate,GIDSignInUIDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *mark;
@property (weak, nonatomic) IBOutlet UIView *facebook_layout;
@property (weak, nonatomic) IBOutlet UIView *google_layout;
@property (weak, nonatomic) IBOutlet UIView *twitter_layout;
@property (weak, nonatomic) IBOutlet UIView *linkedin_layout;
@property (weak, nonatomic) IBOutlet UIButton *btn_email_login;
@property (weak, nonatomic) IBOutlet UITextField *txt_email;
@property (weak, nonatomic) IBOutlet UIView *connecting_layout;
@property (weak, nonatomic) IBOutlet UILabel *connecting_title;

- (IBAction)onFacebookLogin:(UIButton *)sender;
- (IBAction)onGoogleLogin:(UIButton *)sender;
- (IBAction)onTwitterLogin:(UIButton *)sender;
- (IBAction)onLinkedinLogin:(UIButton *)sender;
- (IBAction)onEmailLogin:(UIButton *)sender;

@end
