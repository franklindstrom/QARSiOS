//
//  TimeEditLayout.h
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimeEditLayout : UIView <UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UIView *main_layout;
@property (nonatomic, strong) IBOutlet UIView *transparent_layout;
@property (nonatomic, strong) IBOutlet UILabel *pre_label;
@property (nonatomic, strong) IBOutlet UILabel *qa_label;
@property (nonatomic, strong) IBOutlet UITextField *txt_pre_time;
@property (nonatomic, strong) IBOutlet UITextField *txt_qa_time;
@property (nonatomic, strong) IBOutlet UIButton *btn_done;
@property (nonatomic, strong) IBOutlet UIButton *btn_cancel;

@end
