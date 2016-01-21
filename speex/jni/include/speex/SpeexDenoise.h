//
//  SpeexDenoise.h
//  JiaYIn
//
//  Created by user on 14-7-25.
//  Copyright (c) 2014年 WuHan JiuChongTian. All rights reserved.
//

#ifndef SPEEXDENOISE_H
#define SPEEXDENOISE_H

#include "speex/speex_preprocess.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifndef NULL 
#define NULL 0 
#endif
    
#define DEFAULT_DENOISE_FRAME_SIZE 160
#define DEFAULT_DENOISE_SAMPLING_RATE 8000

void initDenoise(int frame_size, int sampling_rate);
void doDenoise(short*far_Mic, int sz);
void reset();
    
#ifdef __cplusplus
}
#endif

#endif
