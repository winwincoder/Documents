//
//  ViewController.m
//  x264Demo
//
//  Created by user on 14-12-4.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import "ViewController.h"

#import "xh264.h"



@interface ViewController ()

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    //[self performSelector:@selector(x264Func) withObject:nil afterDelay:0.5];
    
    
    [self performSelector:@selector(test) withObject:nil afterDelay:0.1];
    /*
     int w = 352, h = 240;
     int yuv420Sz = w*h*3/2;
     for( int i = 1; i <= 10; i++)
     {
     NSString *yuvName = [NSString stringWithFormat:@"tt%03d", i];
     NSString * path = [[NSBundle mainBundle]pathForResource:yuvName ofType:@"yuv"];
     NSData * data =[NSData dataWithContentsOfFile:path];
     
     NSMutableString *yuvBufArraStr = [[NSMutableString alloc] init];
     unsigned char *p = (unsigned char*)[data bytes];
     
     [yuvBufArraStr appendFormat:@"yuv%02d = {", i];
     for(int j = 0; j < yuv420Sz; j++)
     {
     
     if(j == yuv420Sz-1)
     [yuvBufArraStr appendFormat:@"0x%02x", (int)p[j]];
     else
     {
     [yuvBufArraStr appendFormat:@"0x%02x, ", (int)p[j]];
     
     }
     
     }
     
     [yuvBufArraStr appendString:@"};"];
     
     NSLog(yuvBufArraStr);
     
     }
     */

}


-(void) test
{
    int w = 352, h = 240;
    int yuv420Sz = w*h*3/2;
    xh264 *xh = [[xh264 alloc] init];
    [xh begin:w Height:h];

    unsigned char buf[yuv420Sz];
    
    for( int i = 1; i <= 112; i++)
    {
        NSString *yuvName = [NSString stringWithFormat:@"tt%03d", i];
        NSString * path = [[NSBundle mainBundle]pathForResource:yuvName ofType:@"yuv"];
        NSData * data =[NSData dataWithContentsOfFile:path];
        unsigned char *p = (unsigned char*)[data bytes];
        
        [xh compress:p Out:buf];
    }


    
    [xh end];
}



-(void)viewDidAppear:(BOOL)animated
{
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
