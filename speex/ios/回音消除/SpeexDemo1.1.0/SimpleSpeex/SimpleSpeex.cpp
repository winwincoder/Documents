//
//  SimpleSpeex.cpp
//  SpeexDemo
//
//  Created by user on 14-10-16.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#include "SimpleSpeex.h"


//===========================================================
// 预处理

SimplePreprocessor::SimplePreprocessor(SS_SamplingRate sampleRate, int frame_size)
{
    pre_sampling_rate = sampleRate;
    
    //it is recommended to use the same value for frame_size as is used by the encoder (20 ms)
    pre_frame_size = frame_size; //0.02 * (float)pre_sampling_rate;
    
    m_pPreprocessorState = speex_preprocess_state_init(pre_frame_size, pre_sampling_rate);
    
}

SimplePreprocessor::~SimplePreprocessor()
{
    speex_preprocess_state_destroy(m_pPreprocessorState);
}


void SimplePreprocessor::setEchoState(SpeexEchoState* echoState)
{
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_ECHO_STATE, echoState);
}

SS_RET SimplePreprocessor::setDenoise(int open, int suppress)
{
    int denoise = open;
    int noiseSuppress = - suppress; //取负数
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_DENOISE, &denoise); //降噪
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress); //设置噪声的dB

    return SS_ERROR_NONE;
}

SS_RET SimplePreprocessor::setAgc(int open, int level)
{
    int agc = open;
    float agcLevel = level;//24000;
    //actually default is 8000(0,32768),here make it louder for voice is not loudy enough by default. 8000
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_AGC, &agc);//增益
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_AGC_LEVEL,&agcLevel);
    
    return SS_ERROR_NONE;
   
}

SS_RET SimplePreprocessor::setVad(int open, int probStart, int probContinue)
{
    int vad = open;
    int vadProbStart = probStart;
    int vadProbContinue = probContinue;
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_VAD, &vad); //静音检测
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_PROB_START , &vadProbStart); //Set probability required for the VAD to go from silence to voice
    speex_preprocess_ctl(m_pPreprocessorState, SPEEX_PREPROCESS_SET_PROB_CONTINUE, &vadProbContinue); //Set probability required for the VAD to stay in the voice state (integer percent)
    
    return SS_ERROR_NONE;
}


void SimplePreprocessor::run(short* pIn_frame)
{
    //if(pInSize < pre_frame_size || pInSize%pre_frame_size != 0)  //采样数据大小必须为最小音频帧大小的倍数
    //    return SS_ERROR_FAIL;

    
    //spx_int16_t * ptr=(spx_int16_t *)pIn_frame;
    //int nsamples = pInSize/pre_frame_size;
    
    //for(int i = 0; i < nsamples; i++)
    //{
    //    speex_preprocess_run(m_pPreprocessorState, ptr + pre_frame_size*i);
    //}
    
    spx_int16_t * ptr=(spx_int16_t *)pIn_frame;
    speex_preprocess_run(m_pPreprocessorState, ptr);
    
    
    return;
}

int SimplePreprocessor::get_frame_size()
{
    return pre_frame_size;
}

//=================================================================
//回音消除

SimpleEcho::SimpleEcho(SS_SamplingRate sampleRate, int filter_length, int frame_size)
{
    echo_sampling_rate = sampleRate;
    
    //it is recommended to use the same value for frame_size as is used by the encoder (20 ms)
    echo_frame_size = frame_size; //0.02 * (float)echo_sampling_rate;
    
    m_pState = speex_echo_state_init(echo_frame_size, filter_length);
    speex_echo_ctl(m_pState, SPEEX_ECHO_SET_SAMPLING_RATE, &echo_sampling_rate);
    
    if(pthread_mutex_init(&mutex,NULL) != 0 )
    {
        printf("Init metux error.");
    }

}

SimpleEcho::~SimpleEcho()
{
    
    if(pthread_mutex_destroy(&mutex) != 0 )
    {
        printf("destroy metux error.");
    }
    
     speex_echo_state_destroy(m_pState);
}

void SimpleEcho::cancel_echo(short *mic_frame, short *echo_frame, short *no_echo_frame)
{
    /*if(size < echo_frame_size || size%echo_frame_size != 0)  //采样数必须字节对齐
        return SS_ERROR_FAIL;
    
    int nsamples = size/echo_frame_size;
    
    for(int i = 0; i < nsamples; i++)
    {
        speex_echo_cancellation(m_pState, (const spx_int16_t *)micBuf + echo_frame_size*i, (const spx_int16_t *)echoBuf + echo_frame_size*i, (spx_int16_t *)no_echoBuf + echo_frame_size*i);
    }*/
    
    speex_echo_cancellation(m_pState, (const spx_int16_t *)mic_frame, (const spx_int16_t *)echo_frame, (spx_int16_t *)no_echo_frame);
    
    return;
}


//一种简单的处理同步机制的回音消除处理接口
void SimpleEcho::echo_playback(short *echo_frame)
{
    pthread_mutex_lock(&mutex);
    
    speex_echo_playback(m_pState, echo_frame);
    
    pthread_mutex_unlock(&mutex);
    
}

void SimpleEcho::echo_capture(short *input_frame, short *output_frame)
{
    pthread_mutex_lock(&mutex);
    
    speex_echo_capture(m_pState, input_frame, output_frame);
    
    pthread_mutex_unlock(&mutex);
    
}

void SimpleEcho::echo_reset()
{
    speex_echo_state_reset(m_pState);
}

int SimpleEcho::get_frame_size()
{
    return echo_frame_size;
}

SpeexEchoState* SimpleEcho::get_echo_state()
{
    return m_pState;
}


//===============================================================

//编解码

SimpleCodec::SimpleCodec(int quality, int complexity, SS_SamplingRate samplingRate) {
    
    this->init(quality, complexity, samplingRate);
    
}


SimpleCodec::~SimpleCodec() {
    
    this->unInit();
}

SS_RET SimpleCodec::init(int quality, int complexity, SS_SamplingRate samplingRate) {
    
    if (quality < 0 || quality > 10)
        return SS_ERROR_FAIL;
    
    speex_bits_init(&ebits);
    speex_bits_init(&dbits);
    
    //For wideband coding, speex_nb_mode will be replaced by speex_wb_mode
    if(samplingRate == SAMPLING_RATE_8000) //for narrowband
    {
        enc_state = speex_encoder_init(&speex_nb_mode);
        dec_state = speex_decoder_init(&speex_nb_mode);
    }
    else //for wideband
    {
        enc_state = speex_encoder_init(&speex_wb_mode);
        dec_state = speex_decoder_init(&speex_wb_mode);
    }
    
    int tmp = quality;
    speex_encoder_ctl(enc_state, SPEEX_SET_QUALITY, &tmp);
    
    tmp = complexity;
    speex_encoder_ctl(enc_state, SPEEX_SET_COMPLEXITY, &tmp);
    
    tmp = 1;
    speex_encoder_ctl(enc_state, SPEEX_SET_VBR, &tmp);
    
    float q = 4;
    speex_encoder_ctl(enc_state, SPEEX_SET_VBR_QUALITY, &q);
    
    
    
    //to use a perceptual enhancer
    int enh = 1;
    speex_decoder_ctl(dec_state, SPEEX_SET_ENH, &enh);
    speex_encoder_ctl(enc_state, SPEEX_GET_FRAME_SIZE, &enc_frame_size);
    
    speex_decoder_ctl(dec_state, SPEEX_GET_FRAME_SIZE, &dec_frame_size);
    
    
    return SS_ERROR_NONE;
}

void   SimpleCodec::unInit() {

    speex_bits_destroy(&ebits);
    speex_bits_destroy(&dbits);
    speex_decoder_destroy(dec_state);
    speex_encoder_destroy(enc_state);
    
    return;

}


//每次只处理一帧
void SimpleCodec::encode( short* pIn_frame, char *pOut_frame , int *pOut_frame_size)
{
    short buffer[enc_frame_size];
    int encode_bytes = 0;
    
    memcpy(buffer, pIn_frame, enc_frame_size*sizeof(short));
    
    speex_bits_reset(&ebits);
    speex_encode_int(enc_state, buffer, &ebits);
    encode_bytes = speex_bits_write(&ebits, pOut_frame, enc_frame_size);
    
    *pOut_frame_size = encode_bytes;
    
    return;
}

void SimpleCodec::decode( char* pIn_frame, int in_frame_size, short *pOut_frame)
{
    char buffer[dec_frame_size];
    short output_buffer[dec_frame_size];
    
    memcpy(buffer, pIn_frame, in_frame_size);
    
    speex_bits_read_from(&dbits, buffer, in_frame_size);
    speex_decode_int(dec_state, &dbits, output_buffer);
    
    memcpy(pOut_frame, output_buffer, dec_frame_size*sizeof(short));
    
    return;
}

int SimpleCodec::get_enc_framesize()
{
    return enc_frame_size;
}

int SimpleCodec::get_dec_framesize()
{
    return dec_frame_size;
}


//================================================
//抖动缓冲
SimpleJitterBuffer::SimpleJitterBuffer(int step_size)
{
    state = jitter_buffer_init(step_size);
    
    if(pthread_mutex_init(&mutex,NULL) != 0 )
    {
        printf("Init metux error.");
    }
}

SimpleJitterBuffer::~SimpleJitterBuffer()
{
    if(pthread_mutex_destroy(&mutex) != 0 )
    {
        printf("destroy metux error.");
    }

    jitter_buffer_destroy(state);
}


void SimpleJitterBuffer::put(const JitterBufferPacket *packet)
{
    pthread_mutex_lock(&mutex);
    
    jitter_buffer_put(state, packet);
    
    pthread_mutex_unlock(&mutex);
}


int SimpleJitterBuffer::get(JitterBufferPacket* packet, int desired_span, int *start_offset)
{
    pthread_mutex_lock(&mutex);
    
    int ret = jitter_buffer_get(state, packet, desired_span, start_offset);
    
    pthread_mutex_unlock(&mutex);
    
    return ret;
}


void SimpleJitterBuffer::tick()
{
    jitter_buffer_tick(state);
}


void SimpleJitterBuffer::remaining_span(int remaining)
{
    jitter_buffer_remaining_span(state, remaining);
}


void SimpleJitterBuffer::reset()
{
    jitter_buffer_reset(state);
}





