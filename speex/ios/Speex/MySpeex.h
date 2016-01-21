//
//  Speex.h
//  Speex
//
//  Created by user on 14-6-16.
//  Copyright (c) 2014年 WuHan JiuChongTian. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MySpeex : NSObject

/* quality
 * 1 : 4kbps (very noticeable artifacts, usually intelligible)
 * 2 : 6kbps (very noticeable artifacts, good intelligibility)
 * 4 : 8kbps (noticeable artifacts sometimes)
 * 6 : 11kpbs (artifacts usually only noticeable with headphones)
 * 8 : 15kbps (artifacts not usually noticeable)
 */

#define DEFAULT_COMPRESSION  4

+(int) open:(int)quality;
+(int) encode:(short*)pInBuf Offset:(int)offset Encoded:(Byte*)pOutBuf Size:(int)sz;
+(int) decode:(Byte*)pInBuf Length:(int)len Decoded:(short*)pOutBuf Size:(int)sz;
+(int) decodeEx:(Byte*)pInBuf Length:(int)len Decoded:(short*)pOutBuf Size:(int)sz;
+(int) getFrameSize;
+(void) close;

//回声消除接口, 添加日期：2014-07-18， 郑雪峰
+(void) initACE:(int)frame_size FilterLength:(int)filter_length SamplingRate:(int)sampling_rate;
+(void) doACE:(short*)mic Echo:(short*)ref Out:(short*)dest FrameSize:(int)sz;
+(void) unInitACE;

//远端音频数据噪声抑制和增益控制
+(void) initFarMicDenoise;
+(void) farMicDoDenoise:(short*)far_Mic FrameSize:(int)sz;
+(void) unInitFarMicDenoise;

//本地端采集音频数据噪声抑制和增益控制
+(void) initLocalMicDenoise;
+(void) localMicDoDenoise:(short*)far_Mic FrameSize:(int)sz;
+(void) unInitLocalMicDenoise;

@end
