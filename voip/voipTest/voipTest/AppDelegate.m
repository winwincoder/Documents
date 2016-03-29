//
//  AppDelegate.m
//  voipTest
//
//  Created by user on 14-12-2.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import "AppDelegate.h"



@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize streamConnCount;
@synthesize inputStream;
@synthesize outputStream;
@synthesize voipServerIP;
@synthesize voipServerPort;


- (void)sendLocalNotification:(NSString*)message WithUserInfo:(NSDictionary*)userInfo {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    
    UIApplication *application = [UIApplication sharedApplication];
    
    UILocalNotification *notification = [UILocalNotification new];
    notification.repeatInterval = 0;
    [notification setAlertBody:[NSString stringWithFormat:@"%@: %@", dateString, message]];
    [notification setUserInfo:userInfo];
    [notification setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    [notification setTimeZone:[NSTimeZone defaultTimeZone]];
    [notification setSoundName:UILocalNotificationDefaultSoundName];
    
    NSInteger badgeNum = [[UIApplication sharedApplication] applicationIconBadgeNumber];
    badgeNum += 1;
    [notification setApplicationIconBadgeNumber:badgeNum];
    
    [application scheduleLocalNotification:notification];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    
    NSLog(@"didFinishLaunchingWithOptions");
    
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert categories:nil]];
    
    //判断是正常启动应用还是系统自动启动, 然后决定该创建window还是创建voip的socket
    if([application applicationState] == UIApplicationStateBackground) //系统自动启动
    {
        [self sendLocalNotification:@"系统自动启动" WithUserInfo:nil];
        NSLog(@"系统自动启动");
    }
    else //正常启动
    {
        [self sendLocalNotification:@"正常启动" WithUserInfo:nil];
        NSLog(@"系统正常启动");
    }
    
    
    //指定voip的服务器tcp连接地址信息
    //////////////////////////////////////////////////////////
    self.voipServerIP = VOIP_SERVER_IP;
    self.voipServerPort = VOIP_SERVER_PORT;
    
    [self setupStream:voipServerIP withPort:voipServerPort];
    
    
    return YES;
}

//建立voip用tcp连接，只调用一次
-(void)setupStream:(NSString*)svrIp withPort:(int)port
{
    self.streamConnCount = 0;
    self.outputStream = nil;
    self.inputStream = nil;
    
    [self resetStream:svrIp withPort:port];
    
    
    //5.调用setKeepAliveTimeout：handler：，app在后台时将会定期调用handler。运行在其中做任何事情，但是它应当用于发送‘ping’到服务器，来保持链接可用。上述代码设置为每隔10 min进行ping操作（文档所示的最小值）
    [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
        /*if (self.outputStream != nil)
        {
            char pingString[16] = {0};
            sprintf(pingString, "ping");
            
            [self.outputStream write:(const uint8_t *)pingString maxLength:strlen((char*)pingString)];
            [self sendLocalNotification:@"Ping sent" WithUserInfo:nil];
        }*/
        
        
        //检查网络连接状态
        if([self isNeedReset]) //已断开
        {
            NSLog(@"setKeepAliveTimeout, try to reconnect tcp server...");
            [self resetStream:svrIp withPort:port];
        }
        else
        {
            //是否需要主动发送心跳数据，还需要测试，保险起见，加上此操作
            char pingString[16] = {0};
            sprintf(pingString, "idle");
            
            [self.outputStream write:(const uint8_t *)pingString maxLength:strlen((char*)pingString)];
            
            NSLog(@"setKeepAliveTimeout is being connected..");
        }
    }];
}

-(BOOL) isNeedReset
{
    if(self.outputStream == nil && self.inputStream == nil)
        return YES;
    
    return NO;
}


//和服务器建立连接，若已存在连接则关闭再重新建立，可多次调用
-(void)resetStream:(NSString*)svrIp withPort:(NSInteger)port
{
    if(self.inputStream != nil)
    {
        [self cleanUpStream:self.inputStream];
    }
    
    if(self.outputStream != nil)
    {
        [self cleanUpStream:self.outputStream];
    }
    
    // 1.应用CFStreamCreatePairWithSocketToHost方法是最简便的方式，意味着此后更多的桥接（bridging）可以应用NSInputStream和NSOutputStream类
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)svrIp, (UInt32)port, &readStream, &writeStream);
    
    // 2.以CFStreamCreatePairWithSocketToHost创建2个stream对后，将它们转换成oc类，setProperty：forKey方法调用非常重要，由此告知OS，app在后台时，链接仍需保持。该设置只需在input stream完成即可
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [self.inputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    
    // 3.设置s2个tream的委托对象为self，并将runloop设置为main runloop。OS需要确定委托方法需要在哪个runloop下被调用，本例中最适合的runloop便是和app主线程相关的。为了在接收到信息后更新UI，故需要设置在main runloop中
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    // 4.设置好后，开启2个stream
    [self.inputStream open];
    [self.outputStream open];
    
}


- (void)cleanUpStream:(NSStream *)stream
{
    [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [stream close];
    
    stream = nil;
}

#pragma stream delegate
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if([aStream isEqual:self.inputStream])
    {
        NSLog(@"aStream isEqual:self.inputStream");
    }
    else if([aStream isEqual:self.outputStream])
    {
        NSLog(@"aStream isEqual:self.outputStream");
    }
    else
    {
        NSLog(@"aStream is unkonwn!");
        return;
    }
    
    switch (eventCode) {
        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
            break;
        case NSStreamEventOpenCompleted:
            self.streamConnCount++;
            NSLog(@"NSStreamEventOpenCompleted");
            
            if(aStream == self.outputStream)
            {
                //这里必须在主线程中操作
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    char header[16] = {0};
                    sprintf(header, "JWLIdle");
                    [self.outputStream write:(const uint8_t *)header maxLength:strlen(header)];
                });
                
            }
            
            break;
        case NSStreamEventHasBytesAvailable:
            if (aStream == self.inputStream)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    uint8_t buffer[1024];
                    NSInteger bytesRead = [self.inputStream read:buffer maxLength:1024];
                    NSString *stringRead = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
                    
                    //解析字符串
                    stringRead = [stringRead stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                    NSLog(@"%@", [NSString stringWithFormat:@"Received: %@", stringRead]);
                    
                    if ([stringRead isEqualToString:@""])
                    {
                         //[self sendNotification:@"New VOIP call"];
                         [self sendLocalNotification:stringRead WithUserInfo:nil];
                    }
                    else if ([stringRead isEqualToString:@"idle"]) //心跳请求
                    {
                        char pingString[16] = {0};
                        sprintf(pingString, "idle");
                        //心跳反馈
                        [self.outputStream write:(const uint8_t *)pingString maxLength:strlen((char*)pingString)];
                        
                        NSLog(@"idle back");
                    }
                });
            }
            
            NSLog(@"NSStreamEventHasBytesAvailable");
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStreamEventHasSpaceAvailable");
            break;
        case NSStreamEventErrorOccurred:
            {
                NSError * error = [aStream streamError];
                NSString * errorInfo = [NSString stringWithFormat:@"Failed; error '%@' (code %ld)", error.localizedDescription, (long)error.code];
                NSLog(@"%@", errorInfo);
                
                [self cleanUpStream:aStream];
                
                if([aStream isEqual:self.inputStream])
                {
                    self.inputStream = nil;
                }
                else if([aStream isEqual:self.outputStream])
                {
                    self.outputStream = nil;
                }
                
                //在连接成功后，若出现异常则主动尝试做一次重连，而且只尝试一次
                if(self.streamConnCount > 0)
                {
                    self.streamConnCount--;
                    if(self.streamConnCount == 0)
                    {
                        [self resetStream:self.voipServerIP withPort:self.voipServerPort];
                        
                    }
                }

                NSLog(@"NSStreamEventErrorOccurred");
            }
            break;
        case NSStreamEventEndEncountered:
            
            [self cleanUpStream:aStream];
            
            if([aStream isEqual:self.inputStream])
            {
                self.inputStream = nil;
            }
            else if([aStream isEqual:self.outputStream])
            {
                self.outputStream = nil;
            }
            
            //在连接成功后，若出现异常则主动尝试做一次重连，而且只尝试一次
            if(self.streamConnCount > 0)
            {
                self.streamConnCount--;
                if(self.streamConnCount == 0)
                {
                    [self resetStream:self.voipServerIP withPort:self.voipServerPort];
                    
                }
            }
            
            NSLog(@"NSStreamEventEndEncountered");
            
            break;
        default:
            break;
    }

}



- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    if([[userInfo objectForKey:@"notifyType"] isEqualToString:@"incall"])
    {
        NSString *incallId = [userInfo objectForKey:@"incallId"];
        
        //[self getIncallOffLineEx:incallId];
    }
    
    
    NSLog(@"收到本地消息");
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    NSLog(@"applicationWillResignActive");
    
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
     NSLog(@"applicationDidEnterBackground");
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    NSLog(@"applicationWillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    application.applicationIconBadgeNumber = 0;
    
    //检查网络连接状态
    if([self isNeedReset]) //已断开
    {
        NSLog(@"setKeepAliveTimeout, try to reconnect tcp server...");
        [self resetStream:self.voipServerIP withPort:self.voipServerPort];
    }
    
    NSLog(@"applicationDidBecomeActive");
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    NSLog(@"applicationWillTerminate");
    
    //[[UIApplication sharedApplication] clearKeepAliveTimeout];
}

@end
