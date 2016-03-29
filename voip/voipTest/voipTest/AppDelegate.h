//
//  AppDelegate.h
//  voipTest
//
//  Created by user on 14-12-2.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/NSError.h>

#define VOIP_SERVER_IP @"192.168.1.120"
#define VOIP_SERVER_PORT 9001

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSStreamDelegate>

@property (strong, nonatomic) UIWindow *window;

//voip 服务器连接地址和端口
@property (retain, nonatomic) NSString *voipServerIP;
@property (nonatomic) NSInteger voipServerPort;
//voip 连接流
@property (nonatomic) NSInteger streamConnCount;   //记录连接成功次数，也可用来判断是否建立连接成功
@property (retain, nonatomic) NSInputStream *inputStream;
@property (retain, nonatomic) NSOutputStream *outputStream;


@end

