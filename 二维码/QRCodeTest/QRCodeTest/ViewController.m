//
//  ViewController.m
//  QRCodeTest
//
//  Created by user on 16-1-13.
//  Copyright (c) 2016年 zhengxuefeng. All rights reserved.
//

#import "ViewController.h"





@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    qrView = [[UIQRScanView alloc] initWithFrame:self.view.bounds AndScannRegion:CGRectMake(40, (self.view.bounds.size.height-(self.view.bounds.size.width - 80))/2 , self.view.bounds.size.width - 80, self.view.bounds.size.width - 80)];
    qrView.delegate = self;
    [self.view addSubview:qrView];
}


-(void)UIQRScanView:(UIQRScanView *)view ScannString:(NSString *)result {
    
    [self performSelectorOnMainThread:@selector(reportScanResult:) withObject:result waitUntilDone:NO];
    AudioServicesPlaySystemSound(1057);
}


-(void)reportScanResult:(NSString *)result
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"二维码扫描"
                                                    message:result
                                                   delegate:nil
                                          cancelButtonTitle:@"取消"
                                          otherButtonTitles: nil];
    alert.delegate = self;
    [alert show];
    
    
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if(buttonIndex == 0) {
        
    }
    
    [qrView reset];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end
