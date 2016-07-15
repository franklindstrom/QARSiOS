//
//  ScanViewController.m
//  QRCodeScanner
//
//  Created by Shah, Chintan on 4/13/15.
//  Copyright (c) 2015 Shah, Chintan. All rights reserved.
//

#import "ScanViewController.h"

@interface ScanViewController ()

@property (strong, nonatomic) AVCaptureDevice* device;
@property (strong, nonatomic) AVCaptureDeviceInput* input;
@property (strong, nonatomic) AVCaptureMetadataOutput* output;
@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer* prevLayer;

@property (strong, nonatomic) UIView *highlightView;
@property (strong, nonatomic) UIView *scanView;
@property (strong, nonatomic) UIView *lineView;

@end

@implementation ScanViewController

- (id)initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil {
    self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil];
    if (self) {}
    return self;
}

- (void)viewWillAppear: (BOOL) animated {
    [super viewWillAppear: animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupScanner];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)touchesBegan: (NSSet *) touches withEvent: (UIEvent *) evt {
    if(self.touchToFocusEnabled) {
        UITouch *touch = [touches anyObject];
        CGPoint pt = [touch locationInView: self.view];
        [self focus: pt];
    }
}

#pragma mark -
#pragma mark NoCamAvailable

- (void) setupNoCameraView {
    UILabel *labelNoCam = [[UILabel alloc] init];
    labelNoCam.text = @"No Camera available";
    labelNoCam.textColor = [UIColor blackColor];
    [self.view addSubview: labelNoCam];
    [labelNoCam sizeToFit];
    labelNoCam.center = self.view.center;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate {
    return (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]));
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {}

#pragma mark -
#pragma mark AVFoundationSetup

- (void) setupScanner {
    divHeight = self.view.bounds.size.height;
    divTop = 0;
    
    CGFloat scanWidth = [self getScanSize:self.view.bounds.size.width];
    CGFloat scanHeight = [self getScanSize:self.view.bounds.size.width];
    
    
    NSLog(@"scanWidth: %f scanHeight: %f", scanWidth, scanHeight);
    
    CGFloat scanX = (self.view.bounds.size.width - scanWidth)/2;
    CGFloat scanY = ((divHeight - scanHeight)/2 ) + divTop;
    CGRect frameRect = CGRectMake(scanX, scanY, scanWidth, scanHeight);
    
    
    _highlightView = [[UIView alloc] init];
    _highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleBottomMargin;
    _highlightView.layer.borderColor = [UIColor greenColor].CGColor;
    _highlightView.layer.borderWidth = 3;
    _highlightView.tag = 100;
    [self.view addSubview: _highlightView];
    
    
    _scanView = [[UIView alloc] init];
    _scanView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleBottomMargin;
    _scanView.tag = 99;
    _scanView.frame = frameRect;
    _scanView.backgroundColor = [UIColor whiteColor];
    _scanView.alpha = 0.50;
    [self.view addSubview: _scanView];
    
    
    CGFloat lineWidth = scanWidth;
    CGFloat lineHeight = 4;
    CGFloat lineX = scanX;
    CGFloat lineY = (scanHeight / 2) - 2 + scanY;
    CGRect lineRect = CGRectMake(lineX, lineY, lineWidth, lineHeight);
    
    _lineView = [[UIView alloc] init];
    _lineView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleBottomMargin;
    _lineView.tag = 98;
    _lineView.frame = lineRect;
    _lineView.backgroundColor = [UIColor blackColor];
    _lineView.alpha = 0.5;
    [self.view addSubview: _lineView];
    
    
    _session = [[AVCaptureSession alloc] init];
    _device = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
    NSError *error = nil;
    
    _input = [AVCaptureDeviceInput deviceInputWithDevice: _device error: &error];
    
    
    if (_input) {
        [_session addInput: _input];
    } else {
        NSLog(@"Error: %@", error);
    }
    
    _output = [[AVCaptureMetadataOutput alloc] init];
    [_output setMetadataObjectsDelegate: self queue: dispatch_get_main_queue()];
    
    
    [_session addOutput: _output];
    _output.metadataObjectTypes = [_output availableMetadataObjectTypes];
    _output.rectOfInterest = frameRect;
    
    _prevLayer = [AVCaptureVideoPreviewLayer layerWithSession: _session];
    CGRect bounds = CGRectMake(0, divTop, self.view.bounds.size.width, divHeight);
    
    _prevLayer.frame = bounds;
    _prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    
    frameRect = CGRectMake(scanX, scanY - divTop, scanWidth, scanHeight);
    [_output metadataOutputRectOfInterestForRect: frameRect];
    CGRect visibleMetadataOutputRect = [_prevLayer metadataOutputRectOfInterestForRect: frameRect];
    
    NSLog(@"visibleMetadataOutputRect --- x %f, y %f, height %f, width %f", visibleMetadataOutputRect.origin.x, visibleMetadataOutputRect.origin.y, visibleMetadataOutputRect.size.height, visibleMetadataOutputRect.size.width);
    
    _output.rectOfInterest = visibleMetadataOutputRect;

    [self.view.layer addSublayer: _prevLayer];
    [_session startRunning];
    [self.view bringSubviewToFront: _highlightView];
    [self.view bringSubviewToFront: _scanView];
    [self.view bringSubviewToFront: _lineView];
    
    
}

-(CGFloat) getScanSize: (CGFloat) screenWidth {
    CGFloat width = screenWidth/2.2;
    CGFloat height = divHeight/2.6;
    return width<height?width:height;
}

#pragma mark -
#pragma mark Helper Methods

- (BOOL) isCameraAvailable {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
    NSLog(@"isCameraAvailable: %d", [videoDevices count] > 0);
    return [videoDevices count] > 0;
}

- (void)startScanning {
    [self.session startRunning];
}

- (void) stopScanning {
    [self.session stopRunning];
}

- (void) setTorch:(BOOL) aStatus {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
    [device lockForConfiguration: nil];
    if ([device hasTorch]) {
        if (aStatus) {
            [device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
    }
    [device unlockForConfiguration];
}

- (void) focus: (CGPoint) aPoint {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType: AVMediaTypeVideo];
    if([device isFocusPointOfInterestSupported] && [device isFocusModeSupported: AVCaptureFocusModeAutoFocus]) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        double screenWidth = screenRect.size.width;
        double screenHeight = screenRect.size.height;
        double focus_x = aPoint.x / screenWidth;
        double focus_y = aPoint.y / screenHeight;
        if([device lockForConfiguration:nil]) {
            if([self.delegate respondsToSelector: @selector(scanViewController: didTapToFocusOnPoint:)]) {
                [self.delegate scanViewController: self didTapToFocusOnPoint: aPoint];
            }
            [device setFocusPointOfInterest: CGPointMake(focus_x, focus_y)];
            [device setFocusMode: AVCaptureFocusModeAutoFocus];
            if ([device isExposureModeSupported: AVCaptureExposureModeAutoExpose]){
                [device setExposureMode: AVCaptureExposureModeAutoExpose];
            }
            [device unlockForConfiguration];
        }
    }
}

- (void)resumeScan {
    divHeight = self.view.bounds.size.height;
    divTop = 0;
    
    CGFloat scanWidth = [self getScanSize: self.view.bounds.size.width];
    CGFloat scanHeight = [self getScanSize: self.view.bounds.size.width];
    CGFloat scanX = (self.view.bounds.size.width - scanWidth) / 2;
    CGFloat scanY = ((divHeight - scanHeight) / 2) + divTop;
    CGRect frameRect = CGRectMake(scanX, scanY, scanWidth, scanHeight);
    
    CGFloat lineWidth = scanWidth;
    CGFloat lineHeight = 4;
    CGFloat lineX = scanX;
    CGFloat lineY = (scanHeight / 2) - 2 + scanY;
    CGRect lineRect = CGRectMake(lineX, lineY, lineWidth, lineHeight);
    
    _prevLayer.bounds = CGRectMake(0, divTop, self.view.bounds.size.width, divHeight);
    _prevLayer.frame = CGRectMake(0, divTop, self.view.bounds.size.width, divHeight);
    
    _scanView.frame = frameRect;
    _lineView.frame = lineRect;
    
    frameRect = CGRectMake(scanX, scanY - divTop, scanWidth, scanHeight);
    
    [_output metadataOutputRectOfInterestForRect: frameRect];
    CGRect visibleMetadataOutputRect = [_prevLayer metadataOutputRectOfInterestForRect: frameRect];
    
    _output.rectOfInterest = visibleMetadataOutputRect;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _highlightView.frame = CGRectZero;
        [_session startRunning];
    });
}


#pragma mark -
#pragma mark AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    CGRect highlightViewRect = CGRectZero;
    AVMetadataMachineReadableCodeObject *barCodeObject;
    NSString *detectionString = nil;
    NSArray *barCodeTypes = @[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];
    
    for (AVMetadataObject *metadata in metadataObjects) {
        for (NSString *type in barCodeTypes) {
            if ([metadata.type isEqualToString: type]) {
                barCodeObject = (AVMetadataMachineReadableCodeObject *) [_prevLayer transformedMetadataObjectForMetadataObject: (AVMetadataMachineReadableCodeObject *) metadata];
                highlightViewRect = barCodeObject.bounds;
                highlightViewRect.origin.y += divTop;
                detectionString = [(AVMetadataMachineReadableCodeObject *) metadata stringValue];
                
                AudioServicesPlaySystemSound(1256);
                [_session stopRunning];
                
                break;
            }
        }
        
        if (detectionString != nil) {
            NSString *must_contained = @"http://www.q-ars.com/polling.php?sesID=";
            NSString *responseString = detectionString;
            if ([responseString containsString: must_contained]) {
                NSArray *ary = [responseString componentsSeparatedByString: must_contained];
                NSUserDefaults *database = [NSUserDefaults standardUserDefaults];
                [database setObject: [ary objectAtIndex: 1] forKey: @"selected_session_id"];
                [database synchronize];
                
                UIStoryboard *storyboard;
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                    storyboard = [UIStoryboard storyboardWithName:@"Pad" bundle:nil];
                } else {
                    storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                }
                
                [self.navigationController pushViewController: [storyboard instantiateViewControllerWithIdentifier: @"RegisterAndQuestion"] animated: true];
            } else {
                UIAlertController * alert=   [UIAlertController
                                              alertControllerWithTitle: @"Q-ARS Says"
                                              message: @"Please try again"
                                              preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* ok = [UIAlertAction
                                     actionWithTitle: @"OK"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action) {
                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                         [self resumeScan];
                                     }];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            }
            break;
        }
    }
    _highlightView.frame = highlightViewRect;
}

@end