//
//  RecordBuffer.m
//  SpeexDemo
//
//  Created by user on 14-11-14.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import "echoCancelBuffer.h"

@implementation echoCancelBuffer

-(id) init
{
    if(self = [super init])
    {
        for(int i = 0; i < 2; i++)
        {
            bufMgr[i] = [[bufferList alloc] init];
        }
    }
    
    return self;
}


-(void) put_record_data:(short*)data Size:(int)sz
{
    [bufMgr[recIndex] put_back:data size:sz];
}


-(void) put_playback_data:(short*)data Size:(int)sz
{
    [bufMgr[plyIndex] put_back:data size:sz];
}

-(BOOL) pop:(short*)data1 EchoData:(short*)data2 Size:(int)sz
{
    
    if([bufMgr[recIndex] is_data_enough:sz] && [bufMgr[plyIndex] is_data_enough:sz])
    {
        UInt64 st1 = 0, st2 = 0;
        [bufMgr[recIndex] pop_front:data1 size:sz sampleTime:&st1];
        [bufMgr[plyIndex] pop_front:data2 size:sz sampleTime:&st2];
        
        assert(st1 == st2);
        
        return YES;
    }
    
    return NO;
}


-(void) reset
{
    for(int i = 0; i < 2; i++)
    {
        [bufMgr[i] reset];
    }
}



@end
