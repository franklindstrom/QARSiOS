//
//  PresentationTime.h
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PresentationTime : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txt_pre_time;
@property (weak, nonatomic) IBOutlet UITextField *txt_qa_time;
@property (weak, nonatomic) IBOutlet UIButton *btn_test_session;

- (IBAction)onButtonClicked:(UIButton *)sender;

@end
