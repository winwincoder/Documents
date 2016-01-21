//
//  SpeexDenoise.h
//  JiaYIn
//
//  Created by user on 14-7-25.
//  Copyright (c) 2014年 WuHan JiuChongTian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "speex_preprocess.h"

#define DEFAULT_DENOISE_FRAME_SIZE 160
#define DEFAULT_DENOISE_SAMPLING_RATE 8000
#define DEFAULT_DENOISE_NOISE_SUPPRESS -60
#define DEFAULT_DENOISE_AGC_LEVEL 8000



@interface SpeexDenoise : NSObject
{
@private
    BOOL m_bHasInit;
    SpeexPreprocessState* m_pPreprocessorState;
    int     m_nFrameSize;
    int     m_nSampleRate;
    int     m_nNoiseSuppress;
    float   m_fAgcLevel;
}

-(id) init;

-(void) initDenoise:(int)frame_size SamplingRate:(int)sampling_rate NoiseSuppress:(int)noise_suppress AgcLevel:(float)agc_level;

-(void) doDenoise:(short*)far_Mic FrameSize:(int)sz;

-(void) reset;



@end
