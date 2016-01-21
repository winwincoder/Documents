//
//  Speex.m
//  Speex
//
//  Created by user on 14-6-16.
//  Copyright (c) 2014年 WuHan JiuChongTian. All rights reserved.
//
#import "MySpeex.h"
#include "libspeex/speex.h"
#include "libspeex/speex/speex_echo.h"

#import "SpeexEchoCancellation.h"
#import "SpeexDenoise.h"

static int codec_open = 0;

static int dec_frame_size;
static int enc_frame_size;

static SpeexBits ebits, dbits;
void *enc_state;
void *dec_state;


SpeexEchoCancellation *speexAce = nil;  //回声消除对象
SpeexDenoise *farSpeexDenoise = nil; //远端音频降噪增益处理对象
SpeexDenoise *localSpeexDenoise = nil; //本地端采集音频降噪增益处理对象

@implementation MySpeex

+(int) open:(int)quality
{
    int tmp;
    if (codec_open++ != 0)
		return 0;
    
	speex_bits_init(&ebits);
	speex_bits_init(&dbits);
    
    enc_state = speex_encoder_init(&speex_nb_mode);
	dec_state = speex_decoder_init(&speex_nb_mode);
	tmp = quality;

    speex_encoder_ctl(enc_state, SPEEX_SET_QUALITY, &tmp);
	speex_encoder_ctl(enc_state, SPEEX_GET_FRAME_SIZE, &enc_frame_size);
	speex_decoder_ctl(dec_state, SPEEX_GET_FRAME_SIZE, &dec_frame_size);
    
    return 1;
}


+(int) encode:(short*)pInBuf Offset:(int)offset Encoded:(Byte*)pOutBuf Size:(int)sz
{
    short buffer[enc_frame_size];
    Byte output_buffer[enc_frame_size];
	int nsamples = (sz-1)/enc_frame_size + 1;
	int i, tot_bytes = 0, encode_bytes = 0;

	if (!codec_open)
		return 0;
    
    //NSLog(@"jni_encode size:%d, times:%d", sz, nsamples);
    
	speex_bits_reset(&ebits);
    
    for (i = 0; i < nsamples; i++) {
        memcpy(buffer, pInBuf + offset + i*enc_frame_size, enc_frame_size*sizeof(short));
		
        speex_bits_reset(&ebits);
		speex_encode_int(enc_state, buffer, &ebits);
        
        encode_bytes = speex_bits_write(&ebits, (char *)output_buffer,
                                        enc_frame_size);

        memcpy(pOutBuf+tot_bytes, output_buffer, encode_bytes);
        
        tot_bytes += encode_bytes;
    }
    
    return tot_bytes;
}


+(int) decodeEx:(Byte*)pInBuf Length:(int)len Decoded:(short*)pOutBuf Size:(int)sz
{
    char *buffer = (char *)pInBuf;
    short *outbuffer = pOutBuf;
    
    int nsamples = (len-1)/(dec_frame_size/8) + 1;
    
    
    if(sz < nsamples*dec_frame_size) return 0;
    
    int i, tot_bytes = 0;
    
    if (!codec_open)
        return 0;
    
    for (i = 0; i < nsamples; i++)
    {
        speex_bits_read_from(&dbits, buffer, dec_frame_size/8);
        speex_decode_int(dec_state, &dbits, outbuffer);
        
        buffer += dec_frame_size/8;
        outbuffer += dec_frame_size;
        
        tot_bytes += dec_frame_size*2;
    }
    
    
    return tot_bytes;
}

+(int) decode:(Byte*)pInBuf Length:(int)len Decoded:(short*)pOutBuf Size:(int)sz
{
    if(dec_frame_size < len)
        return 0;
    
    Byte buffer[dec_frame_size];
    short output_buffer[dec_frame_size];
    int encoded_length = sz;
    
	if (!codec_open)
		return 0;
    
    memcpy(buffer, pInBuf, encoded_length);
	//env->GetByteArrayRegion(encoded, 0, encoded_length, buffer);
    
	speex_bits_read_from(&dbits, (char *)buffer, len);
	speex_decode_int(dec_state, &dbits, output_buffer);
    
    memcpy(pOutBuf, output_buffer, dec_frame_size*sizeof(short));
	//env->SetShortArrayRegion(lin, 0, dec_frame_size, output_buffer);
    
	return dec_frame_size;
}

+(int) getFrameSize
{
    if (!codec_open)
		return 0;
	return enc_frame_size;
}

+(void) close
{
    if (--codec_open != 0)
		return;
    
	speex_bits_destroy(&ebits);
	speex_bits_destroy(&dbits);
	speex_decoder_destroy(dec_state);
	speex_encoder_destroy(enc_state);
}


//回声消除
+(void) initACE:(int)frame_size FilterLength:(int)filter_length SamplingRate:(int)sampling_rate
{
    if(speexAce == nil)
    {
        speexAce = [[SpeexEchoCancellation alloc] init];
    }
    
    [speexAce initACE:frame_size FilterLength:filter_length SamplingRate:sampling_rate];
}

+(void) doACE:(short*)mic Echo:(short*)ref Out:(short*)dest FrameSize:(int)sz
{
    if(speexAce == nil)
        return;
     
    [speexAce doACE:mic Echo:ref Out:dest FrameSize:sz];
}

+(void) unInitACE
{
    if(speexAce == nil)
        return;
    
    [speexAce reset];
    speexAce = nil;
}

//远端音频数据噪声抑制和增益控制
+(void) initFarMicDenoise
{
    if(farSpeexDenoise == nil)
    {
        farSpeexDenoise = [[SpeexDenoise alloc] init];
    }
    
    [farSpeexDenoise initDenoise:-1 SamplingRate:-1 NoiseSuppress:-1 AgcLevel:-1];
}

+(void) farMicDoDenoise:(short*)far_Mic FrameSize:(int)sz
{
    if(farSpeexDenoise == nil)
        return;
    
    [farSpeexDenoise doDenoise:far_Mic FrameSize:sz];
}

+(void) unInitFarMicDenoise
{
    if(farSpeexDenoise == nil)
        return;
    
    [farSpeexDenoise  reset];
    farSpeexDenoise = nil;
}

//本地端采集音频数据噪声抑制和增益控制
+(void) initLocalMicDenoise
{
    if(localSpeexDenoise == nil)
    {
        localSpeexDenoise = [[SpeexDenoise alloc] init];
    }
    
    [localSpeexDenoise initDenoise:-1 SamplingRate:-1 NoiseSuppress:-1 AgcLevel:12000];
}

+(void) localMicDoDenoise:(short*)far_Mic FrameSize:(int)sz
{
    if(localSpeexDenoise == nil)
        return;
    
    [localSpeexDenoise doDenoise:far_Mic FrameSize:sz];
}

+(void) unInitLocalMicDenoise
{
    if(localSpeexDenoise == nil)
        return;
    
    [localSpeexDenoise  reset];
    localSpeexDenoise = nil;
}


@end
