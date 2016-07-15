//
//  TimeEditLayout.m
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TimeEditLayout.h"

@interface TimeEditLayout() {
    NSUserDefaults *database;
    NSInteger counts, dPosX;
    BOOL move_flag;
}

@end

@implementation TimeEditLayout

-(id) initWithFrame: (CGRect) frame {
    self = [super initWithFrame: frame];
    
    database = [NSUserDefaults standardUserDefaults];
    
    counts = 0;
    move_flag = false;
    
    self.transparent_layout = [[UIView alloc] initWithFrame: frame];
    [self.transparent_layout setBackgroundColor: [UIColor blackColor]];
    [self.transparent_layout setAlpha: 0.8];
    [self addSubview: self.transparent_layout];
    
    self.main_layout = [[UIView alloc] initWithFrame: CGRectMake((frame.size.width - 250) / 2, -300, 250, 250)];
    [self.main_layout setBackgroundColor: [UIColor colorWithRed: 0.933 green: 0.933 blue: 0.933 alpha: 1]];
    [self.main_layout.layer setCornerRadius: 8];
    
    self.pre_label = [[UILabel alloc] initWithFrame: CGRectMake(10, 30, 230, 20)];
    [self.pre_label setText: @"Presentation Time"];
    [self.pre_label setFont: [UIFont boldSystemFontOfSize: 20]];
    [self.pre_label setTextColor: [UIColor blackColor]];
    [self.main_layout addSubview: self.pre_label];
    
    self.txt_pre_time = [[UITextField alloc] initWithFrame: CGRectMake(10, 60, 230, 30)];
    [self.txt_pre_time setBorderStyle: UITextBorderStyleRoundedRect];
    [self.txt_pre_time setKeyboardType: UIKeyboardTypeNumbersAndPunctuation];
    [self.txt_pre_time setReturnKeyType: UIReturnKeyNext];
    [self.txt_pre_time setAutocorrectionType: UITextAutocorrectionTypeNo];
    [self.txt_pre_time setDelegate: self];
    [self.main_layout addSubview: self.txt_pre_time];
    
    self.qa_label = [[UILabel alloc] initWithFrame: CGRectMake(10, 120, 230, 20)];
    [self.qa_label setText: @"Q&A Time"];
    [self.qa_label setFont: [UIFont boldSystemFontOfSize: 20]];
    [self.qa_label setTextColor: [UIColor blackColor]];
    [self.main_layout addSubview: self.qa_label];
    
    self.txt_qa_time = [[UITextField alloc] initWithFrame: CGRectMake(10, 150, 230, 30)];
    [self.txt_qa_time setBorderStyle: UITextBorderStyleRoundedRect];
    [self.txt_qa_time setKeyboardType: UIKeyboardTypeNumbersAndPunctuation];
    [self.txt_qa_time setReturnKeyType: UIReturnKeyDone];
    [self.txt_qa_time setAutocorrectionType: UITextAutocorrectionTypeNo];
    [self.txt_qa_time setDelegate: self];
    [self.main_layout addSubview: self.txt_qa_time];
    
    self.btn_cancel = [[UIButton alloc] initWithFrame: CGRectMake(10, 200, 110, 40)];
    [self.btn_cancel setTitle:  @"Cancel" forState: UIControlStateNormal];
    [self.btn_cancel.titleLabel setFont: [UIFont boldSystemFontOfSize: 15]];
    [self.btn_cancel setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [self.btn_cancel setBackgroundColor: [UIColor colorWithRed: 0.827 green: 0.282 blue: 0.212 alpha: 1]];
    [self.btn_cancel.layer setCornerRadius: 8];
    [self.btn_cancel addTarget: self action: @selector(onButtonClicked:) forControlEvents: UIControlEventTouchUpInside];
    [self.main_layout addSubview: self.btn_cancel];
    
    self.btn_done = [[UIButton alloc] initWithFrame: CGRectMake(130, 200, 110, 40)];
    [self.btn_done setTitle:  @"OK" forState: UIControlStateNormal];
    [self.btn_done.titleLabel setFont: [UIFont boldSystemFontOfSize: 15]];
    [self.btn_done setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
    [self.btn_done setBackgroundColor: [UIColor colorWithRed: 0.827 green: 0.282 blue: 0.212 alpha: 1]];
    [self.btn_done.layer setCornerRadius: 8];
    [self.btn_done addTarget: self action: @selector(onButtonClicked:) forControlEvents: UIControlEventTouchUpInside];
    [self.main_layout addSubview: self.btn_done];
    
    [self addSubview: self.main_layout];
    
    [self onOpenLayout];
    
    return self;
}

-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    if (textField == self.txt_pre_time) {
        [self.txt_qa_time becomeFirstResponder];
    } else {
        [textField endEditing: true];
    }
    return true;
}

// Done button clicked event
-(void) onButtonClicked: (UIButton *) button {
    if (button == self.btn_done) {
        if ([self onCheckTextContent]) {
            [database setInteger: self.txt_pre_time.text.integerValue forKey: @"presentation_time"];
            [database setInteger: 1 forKey: @"time_changed"];
            [database synchronize];
            
            [self onCloseLayout];
        }
    } else if (button == self.btn_cancel) {
        [database setInteger: 0 forKey: @"time_changed"];
        [database synchronize];
        
        [self onCloseLayout];
    }
}

// validate the text content
-(void) validateTextContent: (UITextField *) textField {
    textField.layer.cornerRadius = 5.0f;
    textField.layer.masksToBounds = YES;
    textField.layer.borderColor = [[UIColor redColor]CGColor];
    textField.layer.borderWidth = 0.5f;
    
    [UIView animateWithDuration: 0.05 animations: ^{
        dPosX = 5;
        
        if (!move_flag) {
            textField.frame = CGRectMake(textField.frame.origin.x - dPosX, textField.frame.origin.y, 230, 30);
            move_flag = true;
        } else {
            textField.frame = CGRectMake(textField.frame.origin.x + dPosX, textField.frame.origin.y, 230, 30);
            move_flag = false;
        }
    } completion: ^(BOOL completed) {
        if (counts < 11) {
            counts++;
            [self validateTextContent: textField];
        } else {
            textField.frame = CGRectMake(10, textField.frame.origin.y, 230, 30);
            textField.layer.borderWidth = 0;
            [textField becomeFirstResponder];
            counts = 0;
        }
    }];
}

// check the text content is blank
-(BOOL) onCheckTextContent {
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    
    if ([self.txt_pre_time.text isEqualToString: @""]) {
        [self validateTextContent: self.txt_pre_time];
        return false;
    } else if ([self.txt_pre_time.text rangeOfCharacterFromSet:notDigits].location != NSNotFound) {
        [self validateTextContent: self.txt_pre_time];
        return false;
    } else if ([self.txt_qa_time.text isEqualToString: @""]) {
        [self validateTextContent: self.txt_qa_time];
        return false;
    } else if ([self.txt_qa_time.text rangeOfCharacterFromSet:notDigits].location != NSNotFound) {
        [self validateTextContent: self.txt_qa_time];
        return false;
    }
    
    return true;
}

// open main layout
-(void) onOpenLayout {
    [UIView animateWithDuration: 1.0 animations: ^{
        self.main_layout.frame = CGRectMake(self.main_layout.frame.origin.x, 100, 250, 250);
    } completion: ^(BOOL completed) {
        [self.txt_pre_time becomeFirstResponder];
    }];
}

// close main layout
-(void) onCloseLayout {
    [UIView animateWithDuration: 1.0 animations: ^{
        self.main_layout.frame = CGRectMake(self.main_layout.frame.origin.x, -300, 250, 250);
    } completion: ^(BOOL completed) {
        [self.txt_pre_time endEditing: true];
        [self.txt_qa_time endEditing: true];
        
        [self setHidden: true];
        [self removeFromSuperview];
    }];
}

@end