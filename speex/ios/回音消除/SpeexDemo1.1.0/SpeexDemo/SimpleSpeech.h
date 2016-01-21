//
//  SimpleSpeech.h
//  SpeexDemo
//
//  Created by user on 14-10-23.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import <Foundation/Foundation.h>


//获取本地WIFI IP地址用头文件
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <dlfcn.h>

#define UDP_PORT 21000

#define IGNORED_FRAME_NUM 4


//双向对讲，使用单线程控制同步
@interface SimpleSpeech : NSObject {
    
    BOOL isInitialized;
}

@property (nonatomic, retain)  NSString* farIpStr;
@property (nonatomic)  BOOL isStarted;

-(void) initSpeech:(NSString*)ipStr;
-(void) uninitSpeech;

-(BOOL) start;
-(void) stop;

+(NSString*) getLocalIp;

@end
