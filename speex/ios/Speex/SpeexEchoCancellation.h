//
//  SpeexEchoCancellation.h
//  Speex
//
//  Created by user on 14-7-18.
//  Copyright (c) 2014年 WuHan JiuChongTian. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "speex_echo.h"
#import "speex_preprocess.h"


#define DEFAULT_FRAME_SIZE 160
#define DEFAULT_FILTER_LENGTH DEFAULT_FRAME_SIZE*10
#define DEFAULT_SAMPLING_RATE 8000


@interface SpeexEchoCancellation : NSObject
{

@private
    BOOL m_bHasInit;
    SpeexEchoState* m_pState;
    SpeexPreprocessState* m_pPreprocessorState;
    int     m_nFrameSize;
    int     m_nFilterLen;
    int     m_nSampleRate;
}

-(id) init;

-(void) initACE:(int)frame_size FilterLength:(int)filter_length SamplingRate:(int)sampling_rate;

-(void) doACE:(short*)mic Echo:(short*)ref Out:(short*)dest FrameSize:(int)sz;

-(void) reset;

@end
