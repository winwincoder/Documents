//
//  SimpleSpeech.m
//  SpeexDemo
//
//  Created by user on 14-10-23.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import "SimpleSpeech.h"

#import "SimpleUdp.h"
#import "SimpleSpeex.h"
#import "SimpleAudioUnit.h"
#import "recvBuffer.h"
#import "echoCancelBuffer.h"

SimpleSpeech * g_SimpleSpeech = nil;

//语音处理相关对象
SimplePreprocessor *preProcessor = NULL;
SimpleEcho *echoProcessor = NULL;
SimpleCodec *codecProcessor = NULL;
//SimpleJitterBuffer *jitter = NULL;
//udp通信对象
SimpleUdp *udp = NULL;

//音频录制和播放
SimpleAudioUnit *ioUnit = nil;

recvBuffer *recBufMgr = nil;
echoCancelBuffer *echoBufMgr = nil;


@implementation SimpleSpeech

@synthesize farIpStr;
@synthesize isStarted;

-(id)init {
    
    if(self = [super init]) {
        
        g_SimpleSpeech = self;
        isInitialized = NO;
        isStarted = NO;
    }
    
    return self;
}


//接收网络数据回调
void NetRecDataCallBack(char *buf, int size, int userData, char *ip, int port) {
    
    NSLog(@"NetRecDataCallBack bufSize = %d.", size);
    
    //解码接收到的数据
    int frame_size = codecProcessor->get_enc_framesize();
    short recvPcm[frame_size];
    codecProcessor->decode(buf, size, recvPcm);
    
    //将解码的PCM数据放入缓冲区
    [recBufMgr put:recvPcm Size:frame_size];
    
    return;
    
}



//录音数据回调
void RecordDataCallBack(unsigned short *samples, int numSamples, double mSampleTime) {
    
    NSLog(@"put_record_data sampleSize = %d.", numSamples);
    
    //将录制的数据放到定制的缓冲队列中
    [echoBufMgr put_record_data:(short*)samples Size:numSamples];
}

#define DISCARDED_AUDIO_FRAME_NUM 5 //放弃掉的音频帧数
static int g_AudioFrameDiscardedCount;

//回放数据回调
void PlaybackDataCallBack(unsigned short *samples, int numSamples, double mSampleTime) {
    
    NSLog(@"put_playback_data sampleSize = %d.", numSamples);
    
    if(g_AudioFrameDiscardedCount >= DISCARDED_AUDIO_FRAME_NUM)
    {
        [recBufMgr pop:(short*)samples Size:numSamples];
    }
    else
    {
        g_AudioFrameDiscardedCount++;
        memset(samples, 0, numSamples*sizeof(short));
    }
    
    [echoBufMgr put_playback_data:(short*)samples Size:numSamples];
    
}


//发送数据线程
- (void) SendDataThreadFunc {
    
    
    g_AudioFrameDiscardedCount = 0;
    
    //配置语音编解码器
    codecProcessor = new SimpleCodec(6, 4, SAMPLING_RATE_8000);
    int frame_size = codecProcessor->get_enc_framesize();
    //配置回声消除处理器
    echoProcessor = new SimpleEcho(SAMPLING_RATE_8000, 10*frame_size, frame_size);
    //配置预处理
    preProcessor = new SimplePreprocessor(SAMPLING_RATE_8000, frame_size);
    preProcessor->setEchoState(echoProcessor->get_echo_state());
    preProcessor->setDenoise(1, 60);
    preProcessor->setAgc(1, 8000);
    //preProcessor->setVad(1, 80, 65);
    
    
    //配置jitterBuffer
    //jitter = new SimpleJitterBuffer(1);
    //jitter->reset();
    
    //建立udp通信对象
    udp = new SimpleUdp();
    if(-1 == udp->init(UDP_PORT, NetRecDataCallBack, 0))
        NSLog(@"myUdp->init fail...");
    
    //建立音频录制和播放对象
    ioUnit = [[SimpleAudioUnit alloc] init];
    [ioUnit setupAudio:RecordDataCallBack And:PlaybackDataCallBack];
    
    //创建缓冲管理对象
    recBufMgr = [[recvBuffer alloc] init];
    echoBufMgr = [[echoCancelBuffer alloc] init];
    
    
    BOOL isNotStopped = YES;
    
    while(isInitialized)
    {
        
        if(isStarted)
        {
            isNotStopped = YES;
            
            //从回放的数据缓冲队列中找到时间戳相同的数据做回音消除
            short samples[frame_size];
            short echo_cancelled_pcm[frame_size];
            short no_echo_pcm[frame_size];
            if([echoBufMgr pop:samples EchoData:echo_cancelled_pcm Size:frame_size])
            {
                NSLog(@"SendDataThreadFunc echoBufMgr pop...........");
                
                //回音消除
                echoProcessor->cancel_echo(samples, echo_cancelled_pcm, no_echo_pcm);
                
                //预处理
                preProcessor->run(no_echo_pcm);
                
                //编码
                int out_frame_size = frame_size*2;
                char out_frame[out_frame_size];
                codecProcessor->encode(no_echo_pcm, out_frame, &out_frame_size);
                
                //发送到网络
                char ipstr[16] = {0};
                sprintf(ipstr, "%s", [farIpStr UTF8String]);
                int n = udp->sendTo(ipstr, UDP_PORT, out_frame, out_frame_size);
                if(n != out_frame_size)
                {
                    NSLog(@"talkbackFunc udp->sendTo 异常...........");
                }
                else
                {
                    NSLog(@"talkbackFunc udp->sendTo %d bytes.", out_frame_size);
                }
                
            }
            else
            {
                usleep(1000*10);
            }
        }
        else
        {
            if(isNotStopped) //开始到停止状态切换
            {
                //[recBufMgr reset];
                //[echoBufMgr reset];
                
                isNotStopped = NO;
            }
            
            usleep(1000*20);
        }
    }
    
    
    //对象释放
    //网络反初始化
    udp->unInit();
    
    //释放音频对象
    [ioUnit stop];
    [ioUnit resetAudio];
    ioUnit = nil;
    
    //语音处理相关对象
    delete udp;
    delete codecProcessor;
    delete preProcessor;
    delete echoProcessor;
    //delete jitter;
    
    
    //释放缓冲管理对象
    [recBufMgr reset];
    [echoBufMgr reset];
    recBufMgr = nil;
    echoBufMgr = nil;
}


-(void) initSpeech:(NSString*)ipStr {
    
    if(isInitialized) {
        
        return;
    }
    
    farIpStr = ipStr;
    
    //开启主线程，负责数据的发送和各种对象的初始化及释放
    isStarted = NO;
    isInitialized = YES;
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(SendDataThreadFunc) object:nil];
    [thread start];

    return;
}

-(void) uninitSpeech {
    
    if(!isInitialized) {
        
        return;
    }
    
    //关闭主线程
    isStarted = NO;
    isInitialized = NO;
}

-(BOOL) start {
    
    if(isStarted)
        return NO;
    
    //必须先清除，才能保证清空数据数据的同步对齐
    [recBufMgr reset];
    [echoBufMgr reset];
    
    isStarted = YES;
    
    
    [ioUnit start];
    
    return YES;
}



-(void) stop {
    
    if(!isStarted)
    return;
    
    [ioUnit stop];
    
    isStarted = NO;
}


+(NSString*) getLocalIp
{
    char ip[16] = {0};
    int success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    
    success = getifaddrs(&addrs) == 0;
    
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            // the second test keeps from picking up the loopback address
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                if(strcmp(cursor->ifa_name, "en0") == 0)// Wi-Fi adapter
                {
                    sprintf(ip, "%s", inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr));
                    break;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    
    
    NSString *str = [NSString stringWithFormat:@"%s", ip];
    
    return str;
    
}



@end
