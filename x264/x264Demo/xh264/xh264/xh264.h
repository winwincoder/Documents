//
//  xh264.h
//  xh264
//
//  Created by user on 14-12-12.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface xh264 : NSObject

//-(void) x264Func;

-(void) begin:(int)width Height:(int)h;
-(int)  compress:(unsigned char *)inBuf Out:(unsigned char *)buf;
-(void) end;

@end
