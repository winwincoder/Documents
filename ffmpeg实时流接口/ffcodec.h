//
//  ffcodec.h
//  ffLibDemo
//
//  Created by user on 15-5-7.
//  Copyright (c) 2015年 jwl. All rights reserved.
//

#ifndef __ffLibDemo__ffcodec__
#define __ffLibDemo__ffcodec__

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif
    
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libavutil/avutil.h"
#include "libswscale/swscale.h"
    
#ifdef __cplusplus
}
#endif


#ifdef __cplusplus
extern "C" {
#endif

//解码h264码流数据抛出回调函数定义
typedef void (*pNaluDataCallbackFunc)(unsigned char *nalu, int len);

void ff_registerAll();


/*
 功能：打开解码器
 参数：
 返回值: < 0 失败，否则成功
 */
int ff_openH264Dec(pNaluDataCallbackFunc pFunc, enum AVCodecID dec_id);

/*
 功能：解析h264 Annex B码流，从设置的回调函数中返回nalu
 参数：inBuf h264码流数据块
       inLen   数据块大小
 返回值: < 0 失败，否则成功
 */
int ff_h264_AnnexB_parse(unsigned char *inBuf, int inLen);

/*
 功能：解码nalu为yuv420数据格式
 参数：
 返回值: < 0 失败，否则成功
 */
int ff_h264_decode(unsigned char* pInNaluBuf, int inLen, unsigned char *pOutRgbaBuf, int *pw, int *ph);


AVFrame * ff_h264_decode_2(unsigned char* pInNaluBuf, int inLen, int *pw, int *ph);

void ff_closeH264Dec();
    
    
#ifdef __cplusplus
}
#endif

#endif /* defined(__ffLibDemo__ffcodec__) */
