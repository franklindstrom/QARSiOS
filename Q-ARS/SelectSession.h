//
//  SelectSession.h
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface SelectSession : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *btn_create_session;
@property (weak, nonatomic) IBOutlet UIButton *btn_refresh;
@property (weak, nonatomic) IBOutlet UIScrollView *session_container;
@property (weak, nonatomic) IBOutlet UIView *connecting_layout;

- (IBAction)onRefreshData:(UIButton *)sender;

- (IBAction)onCreateSession:(UIButton *)sender;

@end