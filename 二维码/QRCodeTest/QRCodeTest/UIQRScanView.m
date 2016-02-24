//
//  UIQRScanView.m
//  QRCodeTest
//
//  Created by user on 16-1-13.
//  Copyright (c) 2016年 zhengxuefeng. All rights reserved.
//

#import "UIQRScanView.h"

@implementation UIQRScanView

@synthesize line;

@synthesize isQRCodeCaptured;

@synthesize delegate;


-(id)initWithFrame:(CGRect)frame AndScannRegion:(CGRect)scannRegion {
    
    if(self = [super initWithFrame:frame]) {
       
        scannerRect = scannRegion; //CGRectMake(30, 30, self.bounds.size.width - 60, self.bounds.size.width - 60);
        
        line = [[UIImageView alloc] initWithFrame: CGRectZero];
        line.image = [UIImage imageNamed:@"qr_code_Scanningline.png"];
    }
    
    
    
    //设置扫描中空区域
    UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    [self addSubview:maskView];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [maskPath appendPath:[[UIBezierPath bezierPathWithRoundedRect:scannerRect cornerRadius:1] bezierPathByReversingPath]];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = maskPath.CGPath;
    maskView.layer.mask = maskLayer;
    
    
    //设置扫描线
    line.frame = CGRectMake(CGRectGetMinX(scannerRect), CGRectGetMinY(scannerRect), CGRectGetWidth(scannerRect), 1);
    [self addSubview:line];
    
    [UIView animateWithDuration:2.5 delay:0.0 options:UIViewAnimationOptionRepeat animations:^{
        
        line.frame = CGRectMake(CGRectGetMinX(scannerRect), CGRectGetMinY(scannerRect) + CGRectGetHeight(scannerRect), CGRectGetWidth(scannerRect), 1);
        
    } completion:nil];
    
    [self startScanning];
    
    return self;
}


-(void) startScanning {
    
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler: ^(BOOL granted) {
                if (granted) {
                    [self startCapture];
                } else {
                    NSLog(@"%@", @"访问受限");
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            [self startCapture];
            break;
        }
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied: {
            NSLog(@"%@", @"访问受限");
            break;
        }
        default: {
            break;
        }
    }
}


-(void) startCapture {
    
    self.isQRCodeCaptured = NO;
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if(deviceInput) {
        
        [session addInput:deviceInput];
        AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [session addOutput:metadataOutput];                                                 //这行代码要在设置metadataObjectTypes前
        metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        
        AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        previewLayer.frame = self.bounds;
        [self.layer insertSublayer:previewLayer atIndex:0];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureInputPortFormatDescriptionDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock: ^(NSNotification *note) {
                                                          metadataOutput.rectOfInterest = [previewLayer metadataOutputRectOfInterestForRect:scannerRect];
                                                      }];
        
        [session startRunning];
        
    } else {
        
        NSLog(@"%@", error);
    }
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
    if ([metadataObject.type isEqualToString:AVMetadataObjectTypeQRCode] && !self.isQRCodeCaptured) { // 成功后系统不会停止扫描，可以用一个变量来控制
        
        self.isQRCodeCaptured = YES;
        
        if(delegate != nil) {
            
            [delegate UIQRScanView:self ScanningString:metadataObject.stringValue];
        }
    }
}

-(void) reset {
    
    self.isQRCodeCaptured = NO;
}

/*
-(void) releaseScanning {
    
    //扫描线
    [line removeFromSuperview];
    [line.layer removeAllAnimations];
    
    //停止会话
    //[captureSession stopRunning];
    //[videoPreviewLayer removeFromSuperlayer];
    //captureSession = nil;
    //videoPreviewLayer = nil;
    
    //刷新界面
    [self setNeedsDisplay];

    
}

- (void)addBorder:(CGRect)rect{

    //create path
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
    
    CAShapeLayer *borderLayer=[CAShapeLayer layer];
    borderLayer.path = path.CGPath;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
    borderLayer.strokeColor = [UIColor colorWithRed:0.081 green:0.648 blue:0.102 alpha:0.790].CGColor;
    borderLayer.lineWidth = 2;
    borderLayer.frame=self.bounds;
    
    //[videoPreviewLayer addSublayer:borderLayer];
    
}
*/

@end
