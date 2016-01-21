//
//  SpeexDenoise.m
//  JiaYIn
//
//  Created by user on 14-7-25.
//  Copyright (c) 2014年 WuHan JiuChongTian. All rights reserved.
//

#import "SpeexDenoise.h"

@implementation SpeexDenoise

-(id) init
{
    if(self = [super init])
    {
        m_bHasInit   = false;
        m_pPreprocessorState  = NULL;
        m_nFrameSize   = DEFAULT_DENOISE_FRAME_SIZE;
        m_nSampleRate  = DEFAULT_DENOISE_SAMPLING_RATE;
    }
    
    return self;
}


-(void) initDenoise:(int)frame_size SamplingRate:(int)sampling_rate NoiseSuppress:(int)noise_suppress AgcLevel:(float)agc_level
{
    [self reset];
    
    if(frame_size < 0)
        m_nFrameSize = DEFAULT_DENOISE_FRAME_SIZE;
    else
        m_nFrameSize = frame_size;
    
    if(sampling_rate < 0)
        m_nSampleRate = DEFAULT_DENOISE_SAMPLING_RATE;
    else
        m_nSampleRate = sampling_rate;
    
    if(noise_suppress < 0)
        m_nNoiseSuppress = DEFAULT_DENOISE_NOISE_SUPPRESS;
    else
        m_nNoiseSuppress = -noise_suppress;
    
    if(agc_level < 0)
        m_fAgcLevel = DEFAULT_DENOISE_AGC_LEVEL;
    else
        m_fAgcLevel = agc_level;
    
    

     m_pPreprocessorState = speex_preprocess_state_init(m_nFrameSize, m_nSampleRate);
    
    
    int denoise = 1;
    int noiseSuppress = m_nNoiseSuppress;//- 60;
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_DENOISE, &denoise); //降噪
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress); //设置噪声的dB
    
    
    int agc = 1;
    float q = m_fAgcLevel;//24000;
    //actually default is 8000(0,32768),here make it louder for voice is not loudy enough by default. 8000
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_AGC, &agc);//增益
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_AGC_LEVEL,&q);
    
    
    /*int vad = 1;
    int vadProbStart = 60;
    int vadProbContinue = 50;
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_VAD, &vad); //静音检测
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_PROB_START , &vadProbStart); //Set probability required for the VAD to go from silence to voice
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_PROB_CONTINUE, &vadProbContinue); //Set probability required for the VAD to stay in the voice state (integer percent)*/
    
    
    
    m_bHasInit = true;
}

-(void) doDenoise:(short*)far_Mic FrameSize:(int)sz
{
    if(!m_bHasInit)
    {
        return;
    }
    
    if(sz%m_nFrameSize != 0)  //采样数必须字节对齐
    {
        NSLog(@"doDenoise: FrameSize is illegal...");
        return;
    }
    
    spx_int16_t * ptr=(spx_int16_t *)far_Mic;
    int xCount = sz/m_nFrameSize;
    for(int i = 0; i < xCount; i++)
    {
        speex_preprocess_run(m_pPreprocessorState, ptr + m_nFrameSize*i);
    }
}

-(void) reset
{
    if (m_pPreprocessorState != NULL)
    {
        speex_preprocess_state_destroy(m_pPreprocessorState);
        m_pPreprocessorState = NULL;
    }
    
    m_bHasInit = false;
}


@end
