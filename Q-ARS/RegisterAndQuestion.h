//
//  RegisterAndQuestion.h
//  Q-ARS
//
//  Created by FrankLindstrom on 4/28/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterAndQuestion : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *mark;
@property (weak, nonatomic) IBOutlet UIButton *btn_log_out;
@property (weak, nonatomic) IBOutlet UIScrollView *question_container;
@property (weak, nonatomic) IBOutlet UIButton *btn_survey_done;
@property (weak, nonatomic) IBOutlet UIButton *btn_skip_survey;
@property (weak, nonatomic) IBOutlet UIButton *btn_vote;
@property (weak, nonatomic) IBOutlet UIButton *btn_try_again;
@property (weak, nonatomic) IBOutlet UIButton *btn_next_question;
@property (weak, nonatomic) IBOutlet UIView *connecting_layout;

- (IBAction)onButtonClicked:(UIButton *)sender;

@end
