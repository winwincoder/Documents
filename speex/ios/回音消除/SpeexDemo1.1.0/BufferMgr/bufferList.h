//
//  bufferList.h
//  SpeexDemo
//
//  Created by user on 14-11-19.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 功能：填充不定长度的数据，可根据需要取出指定长度的数据，读写均含时间戳信息用于数据对齐(时间戳使用2字节对齐数据帧数表示)，遵守先入先出原则，可保障线程调用安全；
 注意：适用于2字节采样的音频数据，及做数据对齐,对齐要求设备录放音具有很好的实时性
 */


typedef struct dataBuffer {
    
    short *data;
    int    data_len;
    
    //读相关信息记录
    struct rd_info{
        int pos;    //记录当前仍有未取出数据起始位置
        int rd_sz;  //可读出数据大小
    };

    struct rd_info rd;
    
    //写相关信息记录
    struct wr_info{
        UInt64 sampleTime;  //记录采样帧时间戳
    };
    
    struct wr_info wr;
    
    
    struct dataBuffer* next;
    
} dataBuffer, *p_dataBuffer;



@interface bufferList : NSObject {
    
    NSLock *operLock;
    
    p_dataBuffer p_first;  //链表头
    p_dataBuffer p_last;   //链表尾
    
    UInt64 m_frame_sample_time; //整个链表的全局时间戳
}

/*
 功能：入栈
 */
-(void) put_back:(short*)data size:(int)sz;

/*
 功能：出栈
 */
-(BOOL) pop_front:(short*)data size:(int)sz sampleTime:(UInt64*)st;

/*
 功能：检查链表中数据是否有足够的数据
 */
-(BOOL) is_data_enough:(int)wantedSize;


/*
 功能：重置，清空时间戳信息及清空链表
 */
-(void) reset;






@end
