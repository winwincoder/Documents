//
//  bufferList.m
//  SpeexDemo
//
//  Created by user on 14-11-19.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import "bufferList.h"

@implementation bufferList


- (instancetype) init {
    
    if(self = [super init])
    {
        operLock = [[NSLock alloc] init];
        
        p_first = NULL;
        p_last = NULL;
        
        m_frame_sample_time = 0;
    }
    
    return self;
}

//写入
-(void) put_back:(short*)data size:(int)sz
{
    [operLock lock];
    
    p_dataBuffer p = (p_dataBuffer)malloc(sizeof(dataBuffer));
    p->data = (short*)malloc(sz*sizeof(short));
    memcpy(p->data, data, sz*sizeof(short));
    p->data_len = sz;
    
    p->rd.pos = 0;
    p->rd.rd_sz = p->data_len;
    
    m_frame_sample_time += p->data_len;
    p->wr.sampleTime = m_frame_sample_time;
    p->next = NULL;
    
    
    if(p_last == NULL) //空链表
    {
        p_first = p_last = p;
    }
    else
    {
        p_last->next = p;
        p_last = p;
    }
    
    [operLock unlock];
    return;
}

-(BOOL) is_data_enough:(int)wantedSize
{
    [operLock lock];
    
    //检查当前链表中可读出数据量是否足够
    int totalSize = 0;
    p_dataBuffer p = p_first;
    while (p != NULL)
    {
        totalSize += p->rd.rd_sz;
        p = p->next;
    }
    
    if(totalSize < wantedSize)  //当数据量不充足时
    {
        [operLock unlock];
        return NO;
    }

    [operLock unlock];
    return YES;
}

//读取
-(BOOL) pop_front:(short*)data size:(int)sz sampleTime:(UInt64*)st
{
    [operLock lock];
    
    //检查当前链表中可读出数据量是否足够
    int totalSize = 0;
    p_dataBuffer p = p_first;
    while (p != NULL)
    {
        totalSize += p->rd.rd_sz;
        p = p->next;
    }
    
    if(totalSize < sz)  //当数据量不充足时
    {
        [operLock unlock];
        return NO;
    }
    

    int wantedSize = sz;
    short *wantedData = data;
    
LOOP:
    
    if(wantedSize <= p_first->rd.rd_sz)
    {
        memcpy(wantedData, p_first->data + p_first->rd.pos, wantedSize*sizeof(short));
        p_first->rd.pos += wantedSize;
        p_first->rd.rd_sz -= wantedSize;
        *st = p_first->wr.sampleTime - p_first->rd.rd_sz;
        
        if(p_first->rd.rd_sz == 0) //数据已全部读出
        {
            //删除该节点
            if(p_first == p_last) //只存在一个节点
            {
                free(p_first->data);
                free(p_first);
                p_first = p_last = NULL;
            }
            else
            {
                p_dataBuffer p = p_first;
                p_first = p->next;
                free(p->data);
                free(p);
            }
        }
        
        [operLock unlock];
        return YES;
    }
    else
    {
        memcpy(wantedData, p_first->data + p_first->rd.pos, p_first->rd.rd_sz*sizeof(short));
        
        wantedSize -= p_first->rd.rd_sz;
        wantedData += p_first->rd.rd_sz;
        
        p_first->rd.pos += p_first->rd.rd_sz;
        p_first->rd.rd_sz = 0;

        //删除本节点
        p_dataBuffer p = p_first;
        p_first = p->next;
        free(p->data);
        free(p);
        
        goto LOOP;

    }
    
}

-(void) reset
{
    [operLock lock];
    
    while(p_first != NULL) //链表非空
    {
        p_dataBuffer p = p_first;
        p_first = p_first->next;
        free(p);
    }
    
    p_last = NULL;
    
    m_frame_sample_time = 0;
    
    
    [operLock unlock];
}

@end
