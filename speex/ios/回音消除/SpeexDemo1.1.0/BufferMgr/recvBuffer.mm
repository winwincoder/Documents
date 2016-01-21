//
//  recvBuffer.m
//  SpeexDemo
//
//  Created by user on 14-11-14.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import "recvBuffer.h"

@implementation recvBuffer


- (instancetype) init
{
    self = [super init];
    
    if (self) {
        
        bufMgr = [[bufferList alloc] init];
        
    }
    
    return self;
}


-(void) put:(short*)data Size:(int)sz {
    
    [bufMgr put_back:data size:sz];
}


-(void) pop:(short*)data Size:(int)sz {
    
    UInt64 st = 0;
    if(![bufMgr pop_front:data size:sz sampleTime:&st])
    {
        memset(data, 0, sz);
    }
}


-(void) reset
{
    [bufMgr reset];
}



@end
