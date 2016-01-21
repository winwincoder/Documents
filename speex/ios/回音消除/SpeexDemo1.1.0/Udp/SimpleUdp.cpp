//
//  udp.cpp
//  SpeexDemo
//
//  Created by user on 14-10-17.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#include "SimpleUdp.h"


///////////////////////////////////////////////////////


SimpleUdp::SimpleUdp() {
    
    sock_fd = -1;
    recvCallBack = NULL;
}


SimpleUdp::~SimpleUdp() {
    
}


void *clientRecv(void *arg) {
   
    SimpleUdp *clnt = (SimpleUdp *)arg;
    
    struct sockaddr_in rin;
    int address_size;
    char buf[MAX_REC_BUF_SIZE];
    ssize_t n;
    
    while(clnt->get_t_flag() == 1) {
        
        address_size = sizeof(rin);
        
        n = recvfrom(clnt->get_sock_fd(), buf, MAX_REC_BUF_SIZE, 0, (struct sockaddr *)&rin, (socklen_t *)&address_size);
        if (n < 0) {  //发生错误
            /*
             EAGAIN：套接字已标记为非阻塞，而接收操作被阻塞或者接收超时
             EBADF：sock不是有效的描述词
             ECONNREFUSE：远程主机阻绝网络连接
             EFAULT：内存空间访问出错
             EINTR：操作被信号中断
             EINVAL：参数无效
             ENOMEM：内存不足
             ENOTCONN：与面向连接关联的套接字尚未被连接上
             ENOTSOCK：sock索引的不是套接字
             */
            if(errno == EAGAIN) {
                
                continue;
                
            }
            else {
                
                printf("clientRecv recvfrom error:%s\n",strerror(errno));
                
                break;   //退出
            }
            
        }
        else if(n == 0) {  //另一端已关闭
            
            continue;
        }
        else {  //接收到数据
            
            //抛出数据
            UdpRecDataCallBack func = clnt->get_rec_callback();
            if(func != NULL) {
                
                // 取得ip和端口号
                char ip[32] = {0};
                sprintf(ip, "%s", inet_ntoa(rin.sin_addr));
                int port = ntohs(rin.sin_port);
                
                func(buf, (int)n, clnt->get_user_data(), ip, port);
            }
            
        }
        
    }
    
    
    
    
    return ((void *)0);
}


int SimpleUdp::init(int port, UdpRecDataCallBack func, int userData) {
    
    if(sock_fd != -1)  //已初始化
        return -1;
    
    
    struct sockaddr_in sin;
    
    bzero(&sin, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = INADDR_ANY;
    sin.sin_port = htons(port);
    
    sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (-1 == sock_fd) {
        return -1;
    }
    
    //将socket设置为非阻塞方式
    int flags = fcntl(sock_fd, F_GETFL, 0);
    fcntl(sock_fd, F_SETFL, flags | O_NONBLOCK);
    
    int n = bind(sock_fd, (struct sockaddr *)&sin, sizeof(sin));
    if (-1 == n) {
        close(sock_fd);
        sock_fd = -1;
        return -1;
    }
    
    
    recvCallBack = func;
    user_data = userData;
    
    //接收数据线程
    t_flag = 1;
    int err = pthread_create(&udp_tid, NULL, clientRecv, (void *)this);
    if(err != 0) {
        
        printf("pthread_create error:%s\n",strerror(err));
        
        close(sock_fd);
        sock_fd = -1;
        return -1;
    }
    
    
    initType = 1;
    
    return sock_fd;
}

int SimpleUdp::init(int port)
{
    if(sock_fd != -1)  //已初始化
        return -1;
    
    struct sockaddr_in sin;
    
    bzero(&sin, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_addr.s_addr = INADDR_ANY;
    sin.sin_port = htons(port);
    
    sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (-1 == sock_fd) {
        return -1;
    }
    
    //将socket设置为非阻塞方式
    int flags = fcntl(sock_fd, F_GETFL, 0);
    fcntl(sock_fd, F_SETFL, flags | O_NONBLOCK);
    
    int n = bind(sock_fd, (struct sockaddr *)&sin, sizeof(sin));
    if (-1 == n) {
        close(sock_fd);
        sock_fd = -1;
        return -1;
    }
    
    initType = 0;
    
    return sock_fd;
}

void SimpleUdp::unInit() {
    
    if(sock_fd != -1) {
        
        if(initType == 1)
        {
            t_flag = 0; //关闭线程
            
            void *tret;
            int err = pthread_join(udp_tid, &tret);
            if(err != 0) {
                printf("can not join with thread1:%s\n",strerror(err));
            }
        }
        
        close(sock_fd);
        sock_fd = -1;
    }
    
}

int SimpleUdp::sendTo(char *ip, int port, char *buf, int size) {
    
    if(sock_fd == -1)  //未初始化
        return -1;
    
    struct sockaddr_in pin;
    
    bzero(&pin, sizeof(pin));
    pin.sin_family = AF_INET;
    inet_pton(AF_INET, ip, &pin.sin_addr);
    pin.sin_port = htons(port);
    
    ssize_t n =	sendto(sock_fd, buf, size, SO_NOSIGPIPE, (struct sockaddr *)&pin, sizeof(pin));

    if(n == -1) {
        /*
         EBADF 参数s非法的socket处理代码。
         EFAULT 参数中有一指针指向无法存取的内存空间。
         WNOTSOCK canshu s为一文件描述词，非socket。
         EINTR 被信号所中断。
         EAGAIN 此动作会令进程阻断，但参数s的soket为补课阻断的。
         ENOBUFS 系统的缓冲内存不足。
         EINVAL 传给系统调用的参数不正确。
         */

        printf("udp sendto fail, errono=%d", errno);
    }
    
    
    return (int)n;
    
}

int SimpleUdp::recv(char *buf, int size)
{
    if(sock_fd == -1)  //未初始化
        return -1;
    
    struct sockaddr_in rin;
    int address_size = sizeof(rin);
    ssize_t n = recvfrom(sock_fd, buf, size, 0, (struct sockaddr *)&rin, (socklen_t *)&address_size);
    
    return (int)n;
}


int SimpleUdp::get_sock_fd() {
    
    return sock_fd;
}

int SimpleUdp::get_user_data() {
    
    return user_data;
}

int SimpleUdp::get_t_flag()
{
    return t_flag;
}
                
UdpRecDataCallBack SimpleUdp::get_rec_callback() {
    
    return recvCallBack;
}















//////////////////////////////////////////////////////////////////














