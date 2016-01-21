//
//  udp.h
//  SpeexDemo
//
//  Created by user on 14-10-17.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#ifndef __udp__
#define __udp__

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>
#include <stdlib.h>
#include <fcntl.h>
#include <pthread.h>  


#define MAX_REC_BUF_SIZE 2014  //线程中udp接收数据缓冲区最大大小

typedef void (*UdpRecDataCallBack)(char *buf, int size, int userData, char *ip, int port);


class SimpleUdp{
    
private:
    int sock_fd;
    int user_data; //用户自定义信息
    
    UdpRecDataCallBack recvCallBack;
    
    //关联的接收线程相关信息
    pthread_t udp_tid; //线程id
    int t_flag; //线程循环控制
    
    int initType; //记录初始化的方式
    
public:
    SimpleUdp();
    ~SimpleUdp();
    
public:
    //使用接收线程，接收的数据从回调中获得
    int init(int port, UdpRecDataCallBack func, int userData);
    //不使用接收线程，需要主动调用recv成员函数获得数据
    int init(int port);
    void unInit();
    int sendTo(char *ip, int port, char *buf, int size);
    int recv(char *buf, int size);

    
//以下成员函数只在本类的线程中使用
public:
    int get_sock_fd();
    int get_user_data();
    int get_t_flag();
    UdpRecDataCallBack get_rec_callback();
    
        
};


#endif /* defined(__udp__) */
