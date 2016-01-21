//
//  SpeexEchoCancellation.m
//  Speex
//
//  Created by user on 14-7-18.
//  Copyright (c) 2014年 WuHan JiuChongTian. All rights reserved.
//

#import "SpeexEchoCancellation.h"

@implementation SpeexEchoCancellation

-(id) init
{
    if(self = [super init])
    {
        m_bHasInit   = false;
        m_pState   = NULL;
        m_pPreprocessorState  = NULL;
        m_nFrameSize   = DEFAULT_FRAME_SIZE;
        m_nFilterLen   = DEFAULT_FRAME_SIZE;
        m_nSampleRate  = DEFAULT_SAMPLING_RATE;
    }
    
    return self;
}

-(void) initACE:(int)frame_size FilterLength:(int)filter_length SamplingRate:(int)sampling_rate
{
    [self reset];
    
    if(frame_size < 0 || filter_length < 0 || sampling_rate < 0)
    {
        m_nFrameSize = DEFAULT_FRAME_SIZE;
        m_nFilterLen = DEFAULT_FILTER_LENGTH;
        m_nSampleRate = DEFAULT_SAMPLING_RATE;
    }
    else
    {
        m_nFrameSize = frame_size;
        m_nFilterLen = filter_length;
        m_nSampleRate = sampling_rate;
    }
    
    m_pState = speex_echo_state_init(m_nFrameSize, m_nFilterLen);
    //m_pPreprocessorState = speex_preprocess_state_init(m_nFrameSize, m_nSampleRate);
    
    //speex_echo_ctl(m_pState, SPEEX_ECHO_SET_SAMPLING_RATE, &m_nSampleRate);
    //speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_ECHO_STATE, m_pState);
    
//    int denoise = 1;
//    int noiseSuppress = - 50;
//    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_DENOISE, &denoise); //降噪
//    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress); //设置噪声的dB
//    
    
    m_bHasInit = YES;
        
}

-(void) doACE:(short*)mic Echo:(short*)ref Out:(short*)dest FrameSize:(int)sz
{
    if(!m_bHasInit)
    {
        return;
    }
    
    if(sz%m_nFrameSize != 0)  //采样数必须字节对齐
    {
        NSLog(@"doACE: FrameSize is illegal...");
        return;
    }
    
    int xCount = sz/m_nFrameSize;
    for(int i = 0; i < xCount; i++)
    {
        speex_echo_cancellation(m_pState, (const spx_int16_t *)mic+m_nFrameSize*i, (const spx_int16_t *)ref+m_nFrameSize*i, (spx_int16_t *)dest+m_nFrameSize*i);
        
        //speex_preprocess_run(m_pPreprocessorState, dest+m_nFrameSize*i);
    }
   
}

-(void)reset
{
    if(m_pState != NULL)
    {
        speex_echo_state_destroy(m_pState);
        m_pState = NULL;
    }
    
    /*if (m_pPreprocessorState != NULL)
    {
        speex_preprocess_state_destroy(m_pPreprocessorState);
        m_pPreprocessorState = NULL;
    }*/
    
    m_bHasInit = false;
}

@end
