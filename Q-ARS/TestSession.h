//
//  TestSession.h
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestSession : UIViewController <UITextFieldDelegate, NSURLConnectionDataDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btn_edit_time;
@property (weak, nonatomic) IBOutlet UIButton *btn_stop_time;
@property (weak, nonatomic) IBOutlet UIButton *btn_lamp;
@property (weak, nonatomic) IBOutlet UILabel *time_label;

@property (weak, nonatomic) IBOutlet UIView *control_ppt_layout;
@property (weak, nonatomic) IBOutlet UIButton *btn_pause;
@property (weak, nonatomic) IBOutlet UIButton *btn_play;
@property (weak, nonatomic) IBOutlet UIButton *btn_backward;
@property (weak, nonatomic) IBOutlet UIButton *btn_foreward;

@property (weak, nonatomic) IBOutlet UIView *go_slide_layout;
@property (weak, nonatomic) IBOutlet UITextField *txt_slide_number;
@property (weak, nonatomic) IBOutlet UIButton *btn_go_slide;

@property (weak, nonatomic) IBOutlet UIView *connecting_layout;

- (IBAction)onControlTime:(UIButton *)sender;

- (IBAction)onControlPPT:(UIButton *)sender;

- (IBAction)onGoSlideNumber:(UIButton *)sender;
@end