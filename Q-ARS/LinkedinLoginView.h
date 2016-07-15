//
//  LinkedinLoginView.h
//  Q-ARS
//
//  Created by FrankLindstrom on 4/29/16.
//  Copyright © 2016 FrankLindstrom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LinkedinLoginView : UIViewController <UIWebViewDelegate, NSURLConnectionDataDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *oauth_web_view;
@property (weak, nonatomic) IBOutlet UIView *loading_view;

@end
