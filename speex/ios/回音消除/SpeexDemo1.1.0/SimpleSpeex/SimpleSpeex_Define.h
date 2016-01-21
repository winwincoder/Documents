//
//  SimpleSpeex_Define.h
//  SpeexDemo
//
//  Created by user on 14-10-16.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#ifndef SimpleSpeex_Define_h
#define SimpleSpeex_Define_h


//函数返回值定义
typedef enum {
    SS_ERROR_FAIL = -1,   // 失败
    SS_ERROR_NONE = 0,    //成功
}SS_RET;


// Speex is mainly designed for three different sampling rates
typedef enum {
    SAMPLING_RATE_8000 = 8000,     //narrowband
    SAMPLING_RATE_16000 = 16000,   //wideband
    SAMPLING_RATE_32000 = 32000    //ultra-wideband
}SS_SamplingRate;


//In practice, frame_size will correspond to 20 ms when using 8, 16, or 32 kHz sampling rate
#define DEFAULT_FRAME_SIZE 0.02*SAMPLING_RATE_8000



#endif
