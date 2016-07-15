//
//  ScanViewController.h
//  QRCodeScanner
//
//  Created by Shah, Chintan on 4/13/15.
//  Copyright (c) 2015 Shah, Chintan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol ScanViewControllerDelegate;

@interface ScanViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>{
    int divHeight;
    int divTop;
}

@property (nonatomic, weak) id<ScanViewControllerDelegate> delegate;

@property (assign, nonatomic) BOOL touchToFocusEnabled;

- (BOOL) isCameraAvailable;
- (void) startScanning;
- (void) stopScanning;
- (void) setTorch:(BOOL) aStatus;

@end

@protocol ScanViewControllerDelegate <NSObject>

@optional

- (void) scanViewController:(ScanViewController *) aCtler didTapToFocusOnPoint:(CGPoint) aPoint;
- (void) scanViewController:(ScanViewController *) aCtler didSuccessfullyScan:(NSString *) aScannedValue;

@end