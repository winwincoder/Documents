//
//  SimpleSpeex.h
//  SpeexDemo
//
//  Created by user on 14-10-16.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#ifndef __SpeexDemo__SimpleSpeex__
#define __SpeexDemo__SimpleSpeex__

#include <stdio.h>
#include <string.h>

#include "SimpleSpeex_Define.h"

#include "speex_preprocess.h"
#include "speex_echo.h"
#include "speex.h"
#include "speex_jitter.h"

#include "pthread.h"  //添加互斥锁



using namespace std;

class SimpleSpeex {
    
    
};


//预处理
class SimplePreprocessor {
    
private:
    SpeexPreprocessState* m_pPreprocessorState;
    int pre_frame_size;
    int pre_sampling_rate;
    
public:
    //it is recommended to use the same value for frame_size as is used by the encoder (20 ms)
    SimplePreprocessor(SS_SamplingRate sampleRate, int frame_size);
    ~SimplePreprocessor();

public:
    
    //Set the associated echo canceller for residual echo suppression (pointer or NULL for no residual echo suppression) 关联回音消除模块
    void setEchoState(SpeexEchoState* echoState);
    
    //设置各项预处理功能
    
    //噪音抑制
    SS_RET setDenoise(int open, int suppress);
    //音量增益
    SS_RET setAgc(int open, int level);
    //静音检测
    SS_RET setVad(int open, int probStart, int probContinue);
    
    //进行预处理
    void run(short* pIn_frame);
    
    //获取最小处理样本数据大小
    int    get_frame_size();
};

//回音消除
class SimpleEcho {
    
private:
    SpeexEchoState* m_pState;
    int echo_frame_size;
    int echo_sampling_rate;
    
    pthread_mutex_t mutex;

public:
    //The recommended tail length is approximately the third of the room reverberation time. For example, in a small room, reverberation time is in the order of 300 ms, so a tail length of 100 ms is a good choice (800 samples at 8000 Hz sampling rate).
    //it is recommended to use the same value for frame_size as is used by the encoder (20 ms)
    SimpleEcho(SS_SamplingRate sampleRate, int filter_length, int frame_size);
    ~SimpleEcho();
    
public:
    
    //针对已做好同步机制的回音消除处理接口
    void cancel_echo(short *mic_frame, short *echo_frame, short*no_echo_frame);
    
    //一种简单的处理同步机制的回音消除处理接口,此处的接口数据长度均为一个帧长度，可通过get_echo_frame_size()接口获得
    void echo_playback(short *echo_frame);
    void echo_capture(short *input_frame, short *output_frame);
    void echo_reset();
    
    int get_frame_size();
    
    SpeexEchoState* get_echo_state();
};

//编解码
class SimpleCodec {
    
private:
    //编解码
    
    int dec_frame_size;
    int enc_frame_size;
    
    SpeexBits ebits, dbits;
    
    void *enc_state;
    void *dec_state;

public:
    /* quality
     * 1 : 4kbps (very noticeable artifacts, usually intelligible)
     * 2 : 6kbps (very noticeable artifacts, good intelligibility)
     * 4 : 8kbps (noticeable artifacts sometimes)
     * 6 : 11kpbs (artifacts usually only noticeable with headphones)
     * 8 : 15kbps (artifacts not usually noticeable)
     
     complexity 1~10
     In practice, the best trade-off is between complexity 2 and 4, though higher settings are often useful when encoding non-speech sounds like DTMF tones.
     */
    
    SimpleCodec(int quality, int complexity, SS_SamplingRate samplingRate = SAMPLING_RATE_8000);
    ~SimpleCodec();

private:
    SS_RET init(int quality, int complexity, SS_SamplingRate samplingRate);
    void   unInit();

public:
    //每次只处理一帧，编码解码配合使用
    void encode( short* pIn_frame, char *pOut_frame , int *pOut_frame_size);
    
    void decode( char* pIn_frame, int in_frame_size, short *pOut_frame);
    
    int  get_enc_framesize();
    
    int  get_dec_framesize();
    
};


//抖动缓冲
class SimpleJitterBuffer{
    
private:
    JitterBuffer *state;
    
    pthread_mutex_t mutex;
    
public:
    SimpleJitterBuffer(int step_size);
    ~SimpleJitterBuffer();
    
public:
    //写入
    void put(const JitterBufferPacket* packet);
    
    //读出
    int  get(JitterBufferPacket* packet, int desired_span, int *start_offset);
    void tick();
    //The argument is used to specify that we are still holding data that has not been written to the playback device. For instance, if 256 samples were needed by the soundcard (specified by desired_span), but jitter_buffer_get() returned 320 samples, we would have remaining=64.
    void remaining_span(int remaining);
    
    void reset();
    
};



#endif /* defined(__SpeexDemo__SimpleSpeex__) */
