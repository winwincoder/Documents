//
//  recvBuffer.h
//  SpeexDemo
//
//  Created by user on 14-11-14.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import "SimpleAudioUnit.h"

/*
 功能：接收到不固定长度的音频数据包填充，根据播放接口需要的数据长度取出音频数据进行播放，若缓冲队列中数据不足，则取数据时直接填充0，保证音频播放不中断

 */



#import <Foundation/Foundation.h>
#import "bufferList.h"


@interface recvBuffer : NSObject {
    
    bufferList *bufMgr;
}


/*
 功能：添加音频数据到队列中
 参数：data 从网络接收到并解码后的PCM数据
      sz 数据长度
 返回值：-
 */
-(void) put:(short*)data Size:(int)sz;


/*
 功能：取出指定长度的音频数据
 参数：data 用来存放获取到得音频数据的缓存
      sz 给入缓存的大小
 返回值：-
 */
-(void) pop:(short*)data Size:(int)sz;

/*
 功能：重置链表
 参数：-
 返回值：-
 */

-(void) reset;



@end
