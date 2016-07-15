//
//  RegisterAndQuestion.m
//  Q-ARS
//
//  Created by FrankLindstrom on 4/28/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegisterAndQuestion.h"
#import "RadioButton.h"
#import "AudienceLogin.h"

@interface RegisterAndQuestion() {
    CGSize size;
    NSMutableData *responseData;
    NSUserDefaults *database;
    NSString *user_id;
    NSString *session_id;
    NSString *request_param;
    float marginX, marginY;
    NSInteger request_type;
    NSMutableArray *answer_key_ary;
    NSMutableDictionary *answer;
    NSInteger question_counts;
    BOOL is_survey;
}

@end

@implementation RegisterAndQuestion

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear: (BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewDidDisappear:animated];
}

-(void) viewDidLoad {
    [super viewDidLoad];
    
    size = [[UIScreen mainScreen] bounds].size;
    
    if ([database objectForKey: @"logo_url"] != NULL) {
        [self.connecting_layout setHidden: false];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL: [NSURL URLWithString: [database objectForKey: @"logo_url"]]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the UI
                [self.connecting_layout setHidden: true];
                [self.mark setImage: [UIImage imageWithData: imageData]];
            });
        });
    }
    
    self.btn_vote.hidden = true;
    self.btn_try_again.hidden = true;
    self.btn_next_question.hidden = true;
    
    self.btn_log_out.layer.cornerRadius = 5;
    self.btn_vote.layer.cornerRadius = 5;
    self.btn_try_again.layer.cornerRadius = 5;
    self.btn_next_question.layer.cornerRadius = 5;
    self.btn_survey_done.layer.cornerRadius = 5;
    self.btn_skip_survey.layer.cornerRadius = 5;
    
    is_survey = true;
    
    marginX = 10;
    marginY = 10;
    request_type = 0;
    question_counts = 0;
    answer_key_ary = [[NSMutableArray alloc] init];
    answer = [[NSMutableDictionary alloc] init];
    
    responseData = [[NSMutableData alloc] init];
    database = [NSUserDefaults standardUserDefaults];
    
    user_id = [database objectForKey: @"user_id"];
    session_id = [database objectForKey: @"selected_session_id"];
    
    request_param = [NSString stringWithFormat: @"sesID=%@", session_id];
    
    [self onConnectWithServer: @"https://q-ars.com/api/survey.php?" : request_param];
}

- (IBAction)onButtonClicked:(UIButton *)sender {
    if (sender == self.btn_log_out) {
        request_type = 2;
        request_param = [NSString stringWithFormat: @"logout&sesID=%@&uuid=%@", session_id, user_id];
        [self onConnectWithServer: @"https://q-ars.com/polling.php?" : request_param];
    } else if (sender == self.btn_survey_done) {
        request_type = 1;
        if (answer_key_ary.count < question_counts) {
            [self onCreateAlertDialog: @"There are one or more missing answers"];
        } else {
            NSMutableDictionary *survey_answer = [[NSMutableDictionary alloc] init];
            NSMutableArray *ary = [[NSMutableArray alloc] init];
            for (NSString *ary_key in answer_key_ary) {
                [ary addObject: [answer objectForKey: ary_key]];
            }
            
            [survey_answer setObject: ary forKey: @"SurveyAnswers"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject: survey_answer options: 0 error: nil];
            request_param = [[NSString alloc] initWithData: jsonData encoding: NSUTF8StringEncoding];
            [self onConnectWithServer: @"https://q-ars.com/api/surveyAnswers.php" : request_param];
        }
    } else if (sender == self.btn_skip_survey) {
        self.btn_skip_survey.hidden = true;
        self.btn_survey_done.hidden = true;
        [self onRequestQuestions];
    } else if (sender == self.btn_try_again) {
        [self onRequestQuestions];
    } else if (sender == self.btn_vote) {
        request_type = 4;
        [self onConnectWithServer: @"https://q-ars.com/polling.php?" : request_param];
    } else if (sender == self.btn_next_question) {
        [self onRequestQuestions];
    }
}

-(void) onConnectWithServer: (NSString *) server_url : (NSString *) param {
    self.connecting_layout.hidden = false;
    
    NSLog(@"%ld", request_type);
    
    NSLog(@"request url: %@%@", server_url, param);
    
    NSString *url_str = @"";
    if (request_type == 1) {
        url_str = server_url;
    } else {
        url_str = [NSString stringWithFormat: @"%@%@", server_url, param];
    }
    
    NSURL *url = [NSURL URLWithString: url_str];
    NSString *request_length = [NSString stringWithFormat:@"%lu", (unsigned long)[param length]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 180.0];
    [request addValue: @"text/xml; charset=utf-8" forHTTPHeaderField: @"Content-Type"];
    [request addValue: request_length forHTTPHeaderField: @"Content-Length"];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: [param dataUsingEncoding: NSUTF8StringEncoding]];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest: request delegate:self];
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.connecting_layout.hidden = true;
    
    // convert to JSON
    NSError *myError = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData: responseData options: NSJSONReadingMutableLeaves error: &myError];
    
    NSLog(@"%@", data);
    
    if (request_type == 0) {
        // get question and answer array from JSON response
        NSArray *surveyAry = [data objectForKey: @"questiondetails"];
        
        for (NSDictionary *survey in surveyAry) {
            [self onAddQuestions: [survey objectForKey: @"question"]];
            
            // radio group
            NSMutableArray* buttons = [NSMutableArray arrayWithCapacity: 5];
            
            // add answer radio button to radio group
            for (int i = 1; i <= 5; i++) {
                // radio button title label
                NSString *answer_str = [survey objectForKey: [NSString stringWithFormat: @"ans%d", i]];
                if (![answer_str isEqualToString: @""]) {
                    [self onAddAnswers: buttons : [survey objectForKey: @"qid"] : answer_str : i];
                }
            }
            
            [buttons[0] setGroupButtons: buttons]; // Setting buttons into the group
            [self.question_container setContentSize: CGSizeMake(size.width - 20, marginY)];
            
            question_counts++;
        }
    } else if (request_type == 1) {
        self.btn_skip_survey.hidden = true;
        self.btn_survey_done.hidden = true;
        [self onRequestQuestions];
    } else if (request_type == 2) {
        UIStoryboard *storyboard;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            storyboard = [UIStoryboard storyboardWithName:@"Pad" bundle:nil];
        } else {
            storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        }
        
        AudienceLogin *audienceView = (AudienceLogin *) [storyboard instantiateViewControllerWithIdentifier:@"AudienceLogin"];
        [self.navigationController pushViewController: audienceView animated: true];
    } else if (request_type == 3) {
        marginX = 10;
        marginY = 10;
        NSString *status = [data objectForKey: @"status"];
        if ([status integerValue] == 1) {
            [self onAddQuestions: [data objectForKey: @"question"]];
            
            NSArray *ans_ary = [data objectForKey: @"answers"];
            
            NSMutableArray *ans_radio_group = [NSMutableArray arrayWithCapacity: 10];
            
            for (NSInteger i = 0; i < ans_ary.count; i++) {
                if (![[ans_ary objectAtIndex: i] isEqualToString: @""]) {
                    [self onAddAnswers: ans_radio_group : [data objectForKey: @"qID"] : [ans_ary objectAtIndex: i] : i];
                }
            }
            
            [ans_radio_group[0] setGroupButtons: ans_radio_group]; // Setting buttons into the group
            [self.question_container setContentSize: CGSizeMake(self.question_container.frame.size.width, marginY)];
            
            self.btn_try_again.hidden = true;
            self.btn_vote.hidden = false;
            self.btn_next_question.hidden = true;
        } else {
            self.btn_try_again.hidden = false;
            self.btn_vote.hidden = true;
            self.btn_next_question.hidden = true;
            NSString *message = [data objectForKey: @"msg"];
            [self onAddQuestions: message];
            [self onCreateAlertDialog: message];
        }
    } else if (request_type == 4) {
        NSString *status = [data objectForKey: @"status"];
        if ([status integerValue] == 1) {
            [self.btn_vote setHidden: true];
            [self.btn_try_again setHidden: true];
            [self.btn_next_question setHidden: false];
        } else {
            [self.btn_vote setHidden: false];
            [self.btn_try_again setHidden: true];
            [self.btn_next_question setHidden: true];
        }
        
        [self onCreateAlertDialog: [data objectForKey: @"msg"]];
    }
}

// add questions to UIScrollView - survey_container
-(void) onAddQuestions: (NSString *) question_str {
    // add question label inside the UIScrollView - survey_container
    UILabel *question_label = [[UILabel alloc] init];
    question_label.text = question_str;
    question_label.font = [UIFont systemFontOfSize:17];
    question_label.textColor = [UIColor blackColor];
    question_label.numberOfLines = 100;
    [question_label setLineBreakMode: NSLineBreakByWordWrapping];
    
    CGRect label_frame = CGRectMake(marginX, marginY, self.question_container.frame.size.width - marginX, question_label.intrinsicContentSize.height);
    question_label.frame = label_frame;
    
    [question_label sizeToFit];
    
    [self.question_container addSubview: question_label];
    
    CGSize labelSize = [question_label.text sizeWithFont: question_label.font constrainedToSize: question_label.frame.size lineBreakMode: NSLineBreakByWordWrapping];
    marginY += labelSize.height + 10;
}

// add answers to UIScrollView - survey_container
-(void) onAddAnswers: (NSMutableArray *) parent_buttons : (NSString *) qid : (NSString *) answer_str : (NSInteger) answer_index {
    // radio button frame
    CGRect frame = CGRectMake(marginX + 20, marginY, self.question_container.frame.size.width - marginX - 20, 30);
    
    // create radio button with the decleared frame
    RadioButton* btn = [[RadioButton alloc] initWithFrame:frame];
    
    [btn setTitle: answer_str forState: UIControlStateNormal];
    [btn setTitleColor: [UIColor darkGrayColor] forState: UIControlStateNormal];
    [btn.titleLabel setFont: [UIFont boldSystemFontOfSize: 15]];
    [btn.titleLabel setNumberOfLines: 100];
    
    [btn setImage: [UIImage imageNamed:@"unchecked.png"] forState: UIControlStateNormal];
    [btn setImage: [UIImage imageNamed:@"checked.png"] forState: UIControlStateSelected];
    
    [btn setTitleEdgeInsets: UIEdgeInsetsMake(0, 6, 0, 0)];
    [btn setContentHorizontalAlignment: UIControlContentHorizontalAlignmentLeft];
    [btn setTag: [qid integerValue] * 10 + answer_index];
    
    [btn addTarget: self action: @selector(onSelectAnswer:) forControlEvents: UIControlEventValueChanged];
    
    frame.size.height = btn.titleLabel.intrinsicContentSize.height + 10;
    [btn setFrame: frame];
    
    [parent_buttons addObject: btn];
    [self.question_container addSubview: btn];
    
    marginY += frame.size.height + 10;
}

// create alert dialog
-(void) onCreateAlertDialog: (NSString *) msg {
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle: @"Q-ARS Says"
                                  message: msg
                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle: @"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                         }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// survey answer button click event
-(void) onSelectAnswer: (RadioButton *) answer_button {
    if(answer_button.selected) {
        NSInteger qid = answer_button.tag / 10;
        NSInteger ans_index = answer_button.tag % 10;
        if (is_survey) {
            // make answer array
            NSMutableDictionary *answerAry = [[NSMutableDictionary alloc] init];
            [answerAry setObject: user_id forKey: @"uid"];
            [answerAry setObject: [NSString stringWithFormat: @"%ld", qid] forKey: @"qid"];
            [answerAry setObject: [NSString stringWithFormat: @"ans%ld", ans_index] forKey: @"answer"];
            
            // answer array key via qid
            NSString *ary_key = [NSString stringWithFormat: @"answer%ld", answer_button.tag / 10];
            
            [answer setObject: answerAry forKey: ary_key];
            
            if (![answer_key_ary containsObject: ary_key]) [answer_key_ary addObject: ary_key];
        } else {
            request_param = [NSString stringWithFormat: @"sesID=%@&qID=%ld&vote1=q%ld&uuid=%@", session_id, qid, ans_index + 1, user_id];
            NSLog(@"%@", request_param);
        }
    }
}

// request to get questions
-(void) onRequestQuestions {
    is_survey = false;
    marginY = 10;
    
    self.btn_vote.hidden = true;
    self.btn_try_again.hidden =true;
    self.btn_next_question.hidden = true;
    
    request_type = 3;
    
    for(UIView *subview in [self.question_container subviews]) {
        [subview removeFromSuperview];
    }
    request_param = [NSString stringWithFormat: @"get_qs&sesID=%@&uuid=%@", session_id, user_id];
    [self onConnectWithServer: @"https://q-ars.com/polling.php?" : request_param];
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end