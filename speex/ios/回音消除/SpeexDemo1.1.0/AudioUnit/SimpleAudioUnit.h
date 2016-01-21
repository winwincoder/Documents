//
//  SimpleAudioUnit.h
//  SpeexDemo
//
//  Created by user on 14-11-13.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioUnit.h>
#import <mach/mach_time.h>

#import "CAXException.h"

#define kOutputBus  0
#define kInputBus   1
#define kChannels   1
#define kBits       16
#define kSampleRate 8000


typedef void (*InputAndOutputDataCallBack)(unsigned short *samples, int numSamples, double mSampleTime);


@interface SimpleAudioUnit : NSObject {
    
    InputAndOutputDataCallBack inputDataFunc;   //录音回调
    InputAndOutputDataCallBack outputDataFunc;  //回放回调
    
}

- (void) setupAudio:(InputAndOutputDataCallBack)recordCbFunc And:(InputAndOutputDataCallBack)playbackCbFunc;
- (void) resetAudio;
- (void) start;
- (void) stop;


@end
