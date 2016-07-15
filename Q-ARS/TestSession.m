//
//  TestSession.m
//  Q-ARS
//
//  Created by FrankLindstrom on 4/27/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestSession.h"
#import "TimeEditLayout.h"

@interface TestSession() {
    NSTimer *timer;
    NSMutableData *responseData;
    NSUserDefaults *database;
    NSInteger pre_time, qa_time, selected_session_id;
    BOOL timer_on, lamp_on;
    
    TimeEditLayout *layout;
}

@end

@implementation TestSession

-(void) viewDidLoad {
    [super viewDidLoad];
    
    responseData = [[NSMutableData alloc] init];
    database = [NSUserDefaults standardUserDefaults];
    pre_time = [database integerForKey: @"presentation_time"] * 60;
    qa_time = [database integerForKey: @"qa_time"] * 60;
    selected_session_id = [database integerForKey: @"selected_session_id"];
    
    timer_on = false;
    lamp_on = true;
    
    [self.btn_edit_time.layer setCornerRadius: 5];
    [self.btn_stop_time.layer setCornerRadius: 5];
    [self.btn_go_slide.layer setCornerRadius: 15];
    [self.control_ppt_layout.layer setCornerRadius: 8];
    [self.go_slide_layout.layer setCornerRadius: 8];
    
    [self.btn_pause setHidden: true];
    [self.connecting_layout setHidden: true];
    
    [self.txt_slide_number setDelegate: self];
    [self.txt_slide_number setReturnKeyType: UIReturnKeyDone];
    [self.txt_slide_number setAutocorrectionType: UITextAutocorrectionTypeNo];
    
    [self onShowPreTime];
    [self onCountPreTime];
}

-(BOOL) textFieldShouldBeginEditing: (UITextField *) textField {
    self.view.frame = CGRectMake(0, -300, self.view.frame.size.width, self.view.frame.size.height);
    return true;
}

-(BOOL) textFieldShouldEndEditing: (UITextField *) textField {
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    return true;
}

-(BOOL) textFieldShouldReturn: (UITextField *) textField {
    [textField endEditing: true];
    return true;
}

- (IBAction)onControlTime:(UIButton *)sender {
    if (sender == self.btn_edit_time) {
        layout = [[TimeEditLayout alloc] initWithFrame: [UIScreen mainScreen].bounds];
        [self.view addSubview: layout];
        [self setPropertyOfStopTimeButton];
        timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector:@selector(onRefreshTime) userInfo: nil repeats:true];
    } else if (sender == self.btn_stop_time) {
        [self setPropertyOfStopTimeButton];
    }
}

- (IBAction)onControlPPT:(UIButton *)sender {
    if (sender == self.btn_play) {
        self.btn_play.hidden = true;
        self.btn_pause.hidden = false;
        [self onConnectToSoapServer: @"PS"];
    } else if (sender == self.btn_pause) {
        self.btn_play.hidden = false;
        self.btn_pause.hidden = true;
        [self onConnectToSoapServer: @"SS"];
    } else if (sender == self.btn_backward) {
        [self onConnectToSoapServer: @"PV"];
    } else if (sender == self.btn_foreward) {
        [self onConnectToSoapServer: @"NT"];
    } else if (sender == self.btn_lamp) {
        if (lamp_on) {
            lamp_on = false;
            [self.btn_lamp setBackgroundImage: [UIImage imageNamed: @"lamp_image_dark.png"] forState: UIControlStateNormal];
            [self onConnectToSoapServer: @"BS"];
        } else {
            lamp_on = true;
            [self.btn_lamp setBackgroundImage: [UIImage imageNamed: @"lamp_image_light.png"] forState: UIControlStateNormal];
            [self onConnectToSoapServer: @"UBS"];
        }
    }
}

- (IBAction)onGoSlideNumber:(UIButton *)sender {
    [self.txt_slide_number endEditing:YES];
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    
    if ([self.txt_slide_number.text isEqualToString: @""] || [self.txt_slide_number.text isEqualToString: @"0"]) {
        [self onCreateAlertDialog: @"Please enter slide number" : self.txt_slide_number];
    } else if ([self.txt_slide_number.text rangeOfCharacterFromSet:notDigits].location != NSNotFound) {
        [self onCreateAlertDialog: @"Slide number must be numerical value" : self.txt_slide_number];
    } else {
        [self onConnectToSoapServer: [NSString stringWithFormat: @"GO-%d", self.txt_slide_number.text.integerValue]];
    }
}

-(void) setPropertyOfStopTimeButton {
    if (timer_on) {
        [timer invalidate];
        timer_on = false;
        [self.btn_stop_time setTitle: @"START" forState: UIControlStateNormal];
    } else {
        [self onCountPreTime];
        [self.btn_stop_time setTitle: @"STOP" forState: UIControlStateNormal];
    }
}

// count down the presentation time
-(void) onCountPreTime {
    timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector:@selector(onShowPreTime) userInfo: nil repeats:true];
    timer_on = true;
}

// count down the presentation time
-(void) onCountQATime {
    timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector:@selector(onShowQATime) userInfo: nil repeats:true];
    timer_on = true;
}

// show presentation time
-(void) onShowPreTime {
    pre_time--;
    
    if (timer_on) {
        NSInteger min = pre_time / 60;
        NSInteger sec = pre_time % 60;
        
        NSString *min_label = (min < 10 ? [NSString stringWithFormat: @"0%ld", (long)min] : [NSString stringWithFormat: @"%ld", (long)min]);
        NSString *sec_label = (sec < 10 ? [NSString stringWithFormat: @"0%ld", (long)sec] : [NSString stringWithFormat: @"%ld", (long)sec]);
        NSString *time_label = [NSString stringWithFormat: @"%@ : %@ Min", min_label, sec_label];
        self.time_label.text = time_label;
    }
    
    if (pre_time == 0) {
        [timer invalidate];
        timer_on = false;
        [self onShowQATime];
        [self onCountQATime];
    }
}

// show Q&Q time
-(void) onShowQATime {
    qa_time--;
    
    if (timer_on) {
        NSInteger min = qa_time / 60;
        NSInteger sec = qa_time % 60;
        
        NSString *min_label = (min < 10 ? [NSString stringWithFormat: @"0%ld", (long)min] : [NSString stringWithFormat: @"%ld", (long)min]);
        NSString *sec_label = (sec < 10 ? [NSString stringWithFormat: @"0%ld", (long)sec] : [NSString stringWithFormat: @"%ld", (long)sec]);
        NSString *time_label = [NSString stringWithFormat: @"%@ : %@ Min", min_label, sec_label];
        self.time_label.text = time_label;
    }
    
    if (qa_time == 0) {
        [timer invalidate];
        timer_on = false;
        [self onCreateAlertDialog: @"Time is Off" : nil];
    }
}

// refresh time to the edited time
-(void) onRefreshTime {
    if (layout.hidden) {
        [timer invalidate];
        timer_on = false;
        NSInteger time_changed = [database integerForKey: @"time_changed"];
        if (time_changed == 1) {
            pre_time = [database integerForKey: @"presentation_time"] * 60;
            qa_time = [database integerForKey: @"qa_time"] * 60;
        }
        
        [self onShowPreTime];
        [self onCountPreTime];
    }
}

// show alert dialog
-(void) onCreateAlertDialog: (NSString *)message : (UITextField *) textField {
    UIAlertController * alert=   [UIAlertController alertControllerWithTitle:@"Q-ARS Says" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
        if (textField != nil) {
            [textField becomeFirstResponder];
            [textField setText: @""];
        }
    }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// connect to server and control ppt plugin
-(void) onConnectToSoapServer: (NSString *) param {
    [self.connecting_layout setHidden: false];
    
    NSString *server_url = @"http://q-ars.com:8080/QarsServ/Qars?wsdl";
    NSString *soap_action = @"http://ws.qars/SetCommand";
    NSString *soap_str = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><ns2:SetCommand xmlns:ns2=\"http://ws.qars/\"><uid>%d</uid><comm>%@</comm></ns2:SetCommand>\n</soap:Body></soap:Envelope>\n", selected_session_id, param];
    
    NSURL *url = [NSURL URLWithString: server_url];
    NSString *request_length = [NSString stringWithFormat:@"%lu", (unsigned long)[soap_str length]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 180.0];
    [request addValue: @"text/xml; charset=utf-8" forHTTPHeaderField: @"Content-Type"];
    [request addValue: request_length forHTTPHeaderField: @"Content-Length"];
    [request addValue: soap_action forHTTPHeaderField:@"SOAPAction"];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: [soap_str dataUsingEncoding: NSUTF8StringEncoding]];
    
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
    [self.connecting_layout setHidden: true];
    
    NSLog(@"%@", responseData);
}

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end