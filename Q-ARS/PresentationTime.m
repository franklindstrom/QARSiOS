//
//  PresentationTime.m
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PresentationTime.h"

@interface PresentationTime() {
    NSUserDefaults *database;
}

@end

@implementation PresentationTime

-(void) viewDidLoad {
    [super viewDidLoad];
    
    database = [NSUserDefaults standardUserDefaults];
    
    [self.btn_test_session.layer setCornerRadius: 5];
    
    [self.txt_pre_time setDelegate: self];
    [self.txt_pre_time setReturnKeyType: UIReturnKeyNext];
    [self.txt_pre_time setAutocorrectionType: UITextAutocorrectionTypeNo];
    
    [self.txt_qa_time setDelegate: self];
    [self.txt_qa_time setReturnKeyType: UIReturnKeyDone];
    [self.txt_qa_time setAutocorrectionType: UITextAutocorrectionTypeNo];
    
    [self.txt_pre_time becomeFirstResponder];
}

-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    if (textField == self.txt_pre_time) {
        [self.txt_qa_time becomeFirstResponder];
    } else {
        [textField endEditing:YES];
    }
    return true;
}

- (IBAction)onButtonClicked:(UIButton *)sender {
    [self.txt_pre_time endEditing: true];
    [self.txt_qa_time endEditing: true];
    
    if ([self onCheckTexts]) {
        [database setInteger: self.txt_pre_time.text.integerValue forKey: @"presentation_time"];
        [database setInteger: self.txt_qa_time.text.integerValue forKey: @"qa_time"];
        [database synchronize];
        [self.navigationController pushViewController: [self.storyboard instantiateViewControllerWithIdentifier: @"TestSession"] animated: true];
        
        NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: self.navigationController.viewControllers];
        NSInteger self_index = [navigationArray indexOfObject: self];
        [navigationArray removeObjectAtIndex: self_index];
        self.navigationController.viewControllers = navigationArray;
    }
}

// show alert dialog
-(void) onCreateAlertDialog: (NSString *)message : (UITextField *) text_field {
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Q-ARS Says"
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             if (text_field != nil) {
                                 [text_field becomeFirstResponder];
                                 [text_field setText: @""];
                             }
                         }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// check the text content of email and password
-(BOOL) onCheckTexts {
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    
    if ([self.txt_pre_time.text isEqualToString: @""]) {
        [self onCreateAlertDialog: @"Please Enter the Presentation Time" : self.txt_pre_time];
        return false;
    } else if ([self.txt_pre_time.text rangeOfCharacterFromSet:notDigits].location != NSNotFound) {
        [self onCreateAlertDialog: @"Presentation time must be numerical value" : self.txt_pre_time];
        return false;
    } else if ([self.txt_qa_time.text isEqualToString: @""]) {
        [self onCreateAlertDialog: @"Please Enter the Q&A Time" : self.txt_qa_time];
        return false;
    } else if ([self.txt_qa_time.text rangeOfCharacterFromSet:notDigits].location != NSNotFound) {
        [self onCreateAlertDialog: @"Q&A time must be numerical value" : self.txt_qa_time];
        return false;
    }
    
    return true;
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end