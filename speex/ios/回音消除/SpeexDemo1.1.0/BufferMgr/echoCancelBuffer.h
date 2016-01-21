//
//  RecordBuffer.h
//  SpeexDemo
//
//  Created by user on 14-11-14.
//  Copyright (c) 2014年 jwl. All rights reserved.
//


/*
 功能：填充回放和录制的不定长度的音频数据（含时间戳信息），内部做对齐；
      可取出指长度的最早填充的录制和回放音频数据，以便speex做回音消除处理；
      当无法同时取出时，则返回失败，等待数据填充好
 
 */

#import <Foundation/Foundation.h>
#import "bufferList.h"


#define recIndex 0
#define plyIndex 1

@interface echoCancelBuffer : NSObject {
    
    bufferList *bufMgr[2];
}

-(void) put_record_data:(short*)data Size:(int)sz;
-(void) put_playback_data:(short*)data Size:(int)sz;

//获得对齐的数据,录音和回音数据
-(BOOL) pop:(short*)data1 EchoData:(short*)data2 Size:(int)sz;

-(void) reset;

@end
