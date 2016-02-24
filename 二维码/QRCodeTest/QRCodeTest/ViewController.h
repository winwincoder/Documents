//
//  ViewController.h
//  QRCodeTest
//
//  Created by user on 16-1-13.
//  Copyright (c) 2016年 zhengxuefeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIQRScanView.h"


@interface ViewController : UIViewController <UIQRScanViewDelegate, UIAlertViewDelegate> {
    
    UIQRScanView *qrView;
}





@end

