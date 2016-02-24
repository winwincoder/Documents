//
//  UIQRScanView.h
//  QRCodeTest
//
//  Created by user on 16-1-13.
//  Copyright (c) 2016年 zhengxuefeng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

static const char *kScanQRCodeQueueName = "ScanQRCodeQueue";


@class UIQRScanView;

@protocol UIQRScanViewDelegate <NSObject>

-(void)UIQRScanView:(UIQRScanView*)view ScanningString:(NSString*)result;

@end


@interface UIQRScanView : UIView <AVCaptureMetadataOutputObjectsDelegate> {
    
    id <UIQRScanViewDelegate> delegate;
    
    CGRect scannerRect;
}

@property (nonatomic) UIImageView *line;
@property (assign) BOOL isQRCodeCaptured;

@property (nonatomic, retain) id <UIQRScanViewDelegate> delegate;

-(id)initWithFrame:(CGRect)frame AndScannRegion:(CGRect)scannRegion;

-(void) reset;

@end
