//
//  xh264.m
//  xh264
//
//  Created by user on 14-12-12.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import "xh264.h"

#include "h264_encoder.h"

@implementation xh264

-(void) begin:(int)width Height:(int)h
{
    compress_begin(width, h);
}

-(int) compress:(unsigned char *)inBuf Out:(unsigned char *)buf
{
    return compress_frame_2(inBuf, buf);
}

-(void) end
{
    compress_end();
}


@end
