//
//  SimpleAudioUnit.m
//  SpeexDemo
//
//  Created by user on 14-11-13.
//  Copyright (c) 2014年 jwl. All rights reserved.
//

#import "SimpleAudioUnit.h"

static BOOL _audioChainIsBeingReconstructed = NO;

static AudioComponentInstance audioUnit = NULL;

SimpleAudioUnit *g_SimpleAudioUnit = nil;

@implementation SimpleAudioUnit


-(id) init
{
    if(self = [super init])
    {
        g_SimpleAudioUnit = self;
    }
    
    return self;
}


- (void) handleInterruption:(NSNotification *)notification
{
    try {
        
        UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
        
        NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
            [self stopIOUnit];
        }
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
            // make sure to activate the session
            NSError *error = nil;
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            if (nil != error)
                NSLog(@"AVAudioSession set active failed with error: %@", error);
            
            [self startIOUnit];
        }
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
}


- (void) handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void) handleMediaServerReset:(NSNotification *)notification
{
    NSLog(@"Media server has reset");
    _audioChainIsBeingReconstructed = YES;
    
    usleep(25000); //wait here for some time to ensure that we don't delete these objects while they are being accessed elsewhere
    
    // rebuild the audio chain
    
    [self setupAudioSession];
    [self setupIOUnit];
    [self startIOUnit];
    
    _audioChainIsBeingReconstructed = NO;
}


//recording
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    
    if(_audioChainIsBeingReconstructed) return noErr;
    
    
    /*if(inTimeStamp->mFlags&kAudioTimeStampSampleTimeValid)
    {
        double timeInSeconds = inTimeStamp->mSampleTime / kSampleRate;
        
        NSLog(@"record::mSampleTime=%f", inTimeStamp->mSampleTime);
    }
    
    if(inTimeStamp->mFlags&kAudioTimeStampHostTimeValid)
    {
        mach_timebase_info_data_t info;
        double elapsedInSecond = 0.0;       //秒
        double elapsedInMillisecond = 0.0; //毫秒
        double elapsedInMicrosecond = 0.0; //微秒
        if(mach_timebase_info(&info) == KERN_SUCCESS)
        {
            uint64_t now = mach_absolute_time();
            uint64_t elapsed = now - inTimeStamp->mHostTime;
            uint64_t nanos = elapsed * info.numer/info.denom;
            elapsedInSecond = (double)nanos/NSEC_PER_SEC;       //秒
            elapsedInMillisecond = (double)nanos/NSEC_PER_MSEC; //毫秒
            elapsedInMicrosecond = (double)nanos/NSEC_PER_USEC; //微秒
        }
        
        NSLog(@"--record::mHostTime=%llu, elapsedInMillisecond=%f", inTimeStamp->mHostTime, elapsedInMillisecond);
    }
    if(inTimeStamp->mFlags&kAudioTimeStampWordClockTimeValid)
        NSLog(@"----record::mWordClockTime=%llu", inTimeStamp->mWordClockTime);
    if(inTimeStamp->mFlags&kAudioTimeStampRateScalarValid)
        NSLog(@"------record::mRateScalar=%f", inTimeStamp->mRateScalar);*/
    
    
    AudioBufferList bufferList;
    UInt16 numSamples = inNumberFrames*kChannels;
    UInt16 samples[numSamples];
    memset(samples, 0, sizeof(samples));
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = samples;
    bufferList.mBuffers[0].mNumberChannels = kChannels;
    bufferList.mBuffers[0].mDataByteSize = numSamples*sizeof(UInt16);
    
    XThrowIfError(AudioUnitRender(audioUnit,ioActionFlags, inTimeStamp, kInputBus, inNumberFrames, &bufferList), "couldn't do AudioUnitRender");
    
    if(g_SimpleAudioUnit->inputDataFunc != NULL)
    {
        g_SimpleAudioUnit->inputDataFunc(samples, numSamples, inTimeStamp->mSampleTime);
    }
    
    return noErr;
    
}


//playback
static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    
    if(_audioChainIsBeingReconstructed) return noErr;
    
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    
    
    /*if(inTimeStamp->mFlags&kAudioTimeStampSampleTimeValid)
    {
        double timeInSeconds = inTimeStamp->mSampleTime / kSampleRate;
        
        NSLog(@"record::mSampleTime=%f", inTimeStamp->mSampleTime);
    }
    
    if(inTimeStamp->mFlags&kAudioTimeStampHostTimeValid)
    {
        mach_timebase_info_data_t info;
        double elapsedInSecond = 0.0;       //秒
        double elapsedInMillisecond = 0.0; //毫秒
        double elapsedInMicrosecond = 0.0; //微秒
        if(mach_timebase_info(&info) == KERN_SUCCESS)
        {
            uint64_t now = mach_absolute_time ();
            
            //if(now >= inTimeStamp->mHostTime)
            {
                uint64_t elapsed = inTimeStamp->mHostTime - now;
                uint64_t nanos = elapsed * info.numer/info.denom;
                elapsedInSecond = (double)nanos/NSEC_PER_SEC;       //秒
                elapsedInMillisecond = (double)nanos/NSEC_PER_MSEC; //毫秒
                elapsedInMicrosecond = (double)nanos/NSEC_PER_USEC; //微秒
            }
            //else
            //{
            //    NSLog(@"--playback::mHostTime=%llu, now=%llu", inTimeStamp->mHostTime, now);
            //}
        }
        
        NSLog(@"--playback::mHostTime=%llu, elapsedInMillisecond=%f", inTimeStamp->mHostTime, elapsedInMillisecond);
    }
    if(inTimeStamp->mFlags&kAudioTimeStampWordClockTimeValid)
        NSLog(@"----playback::mWordClockTime=%llu", inTimeStamp->mWordClockTime);
    if(inTimeStamp->mFlags&kAudioTimeStampRateScalarValid)
        NSLog(@"------playback::mRateScalar=%f", inTimeStamp->mRateScalar);*/
    
    
    if(g_SimpleAudioUnit->outputDataFunc != NULL)
    {
        g_SimpleAudioUnit->outputDataFunc((unsigned short *)ioData->mBuffers[0].mData, inNumberFrames, inTimeStamp->mSampleTime);
    }
    
    /*UInt32 *frameBuffer = (UInt32 *)ioData->mBuffers[0].mData;
    UInt32 count = inNumberFrames;
    for (int j = 0; j < count; j++){
        frameBuffer[j] = [this->inMemoryAudioFile getNextFrame];//Stereo channels
    }*/
    
    return noErr;
}


//设置为可同时录制和播放的声音使用模式，并使用外放
- (void) setupAudioSession
{
    try {
        // Configure the audio session
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
        // we are going to play and record so we pick that category
        NSError *error = nil;
        [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's audio category");
        
        // set the buffer duration to 20 ms
        NSTimeInterval bufferDuration = .02;
        [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session's I/O buffer duration");
        
        // set the session's sample rate
        //[sessionInstance setPreferredSampleRate:kSampleRate error:&error];
        //XThrowIfError((OSStatus)error.code, "couldn't set session's preferred sample rate");
        
        // add interruption handler
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:sessionInstance];
        
        // we don't do anything special in the route change notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRouteChange:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:sessionInstance];
        
        // if media services are reset, we need to rebuild our audio chain
        [[NSNotificationCenter defaultCenter]	addObserver:	self
                                                 selector:	@selector(handleMediaServerReset:)
                                                     name:	AVAudioSessionMediaServicesWereResetNotification
                                                   object:	sessionInstance];
        
        // activate the audio session
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        XThrowIfError((OSStatus)error.code, "couldn't set session active");
        
        
        //设置为扬声器模式
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        OSStatus result = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker , sizeof (audioRouteOverride), &audioRouteOverride);
        if (result)
            NSLog(@"couldn't set audioRouteOverride!");

    }
    catch (CAXException &e) {
        NSLog(@"Error returned from setupAudioSession: %d: %s", (int)e.mError, e.mOperation);
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupAudioSession");
    }
    
    return;
}

- (void) setupIOUnit
{
    try {
        // Create a new instance of AURemoteIO
        
        AudioComponentDescription desc;
        desc.componentType = kAudioUnitType_Output;
        desc.componentSubType = kAudioUnitSubType_RemoteIO;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;
        
        AudioComponent comp = AudioComponentFindNext(NULL, &desc);
        XThrowIfError(AudioComponentInstanceNew(comp, &audioUnit), "couldn't create a new instance of AURemoteIO");
        
        //  Enable input and output on AURemoteIO
        //  Input is enabled on the input scope of the input element
        //  Output is enabled on the output scope of the output element
        
        UInt32 flag = 1;
        XThrowIfError(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &flag, sizeof(flag)), "could not enable input on AURemoteIO");
        XThrowIfError(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputBus, &flag, sizeof(flag)), "could not enable output on AURemoteIO");
        
        // Explicitly set the input and output client formats
        //Describe format
        AudioStreamBasicDescription audioFormat;
        audioFormat.mSampleRate = kSampleRate;
        audioFormat.mFormatID = kAudioFormatLinearPCM;
        audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        audioFormat.mFramesPerPacket = 1;
        audioFormat.mChannelsPerFrame = kChannels;
        audioFormat.mBitsPerChannel = kBits;
        audioFormat.mBytesPerFrame = audioFormat.mBitsPerChannel*audioFormat.mChannelsPerFrame/8;
        audioFormat.mBytesPerPacket = audioFormat.mBytesPerFrame*audioFormat.mFramesPerPacket;
        
        XThrowIfError(AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &audioFormat, sizeof(audioFormat)), "couldn't set the input client format on AURemoteIO");
        XThrowIfError(AudioUnitSetProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputBus, &audioFormat, sizeof(audioFormat)), "couldn't set the output client format on AURemoteIO");
        
        
        // Set the MaximumFramesPerSlice property. This property is used to describe to an audio unit the maximum number
        // of samples it will be asked to produce on any single given call to AudioUnitRender
        /*UInt32 maxFramesPerSlice = 4096;
        XThrowIfError(AudioUnitSetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, sizeof(UInt32)), "couldn't set max frames per slice on AURemoteIO");
        
        // Get the property value back from AURemoteIO. We are going to use this value to allocate buffers accordingly
        UInt32 propSize = sizeof(UInt32);
        XThrowIfError(AudioUnitGetProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFramesPerSlice, &propSize), "couldn't get max frames per slice on AURemoteIO");*/
        
        
        // We need references to certain data in the render callback
        // This simple struct is used to hold that information
        
        // Set the render callback on AURemoteIO
        AURenderCallbackStruct renderCallback;
        renderCallback.inputProc = recordingCallback;
        renderCallback.inputProcRefCon = NULL;
        XThrowIfError(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, kInputBus, &renderCallback, sizeof(renderCallback)), "couldn't set input callback on AURemoteIO");
        
        // Set output callback
        renderCallback.inputProc = playbackCallback;
        renderCallback.inputProcRefCon = NULL;
        XThrowIfError(AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, kOutputBus, &renderCallback, sizeof(renderCallback)), "couldn't set render callback on AURemoteIO");
        
        
        // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
        flag = 0;
        XThrowIfError(AudioUnitSetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, kInputBus, &flag, sizeof(flag)), "could not disable buffer allocation for the recorder");
        
        
        // Initialize the AURemoteIO instance
        XThrowIfError(AudioUnitInitialize(audioUnit), "couldn't initialize AURemoteIO instance");
    }
    
    catch (CAXException &e) {
        NSLog(@"Error returned from setupIOUnit: %d: %s", (int)e.mError, e.mOperation);
    }
    catch (...) {
        NSLog(@"Unknown error returned from setupIOUnit");
    }
    
    return;
}

- (OSStatus) startIOUnit
{
    
    OSStatus err = AudioOutputUnitStart(audioUnit);
    if (err)
        NSLog(@"couldn't start AURemoteIO: %d", (int)err);
    
    return err;
}

- (OSStatus) stopIOUnit
{
    OSStatus err = AudioOutputUnitStop(audioUnit);
    if (err)
        NSLog(@"couldn't stop AURemoteIO: %d", (int)err);
    
    return err;
}


- (void) destroyIOUnit
{
    AudioUnitUninitialize(audioUnit);
}


- (void) resetAudioSession
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //设置为听筒模式
    UInt32 audioRoute = kAudioSessionOverrideAudioRoute_Speaker;
    OSStatus result = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRoute), &audioRoute);
    if (result) {
        
        NSLog(@"OpenALProperty reset() AudioSessionSetProperty couldn't set audio category!");
    }
    
    //将音频策略切换到非以语音为主的应用方式
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
    [audioSession setActive:NO error:nil];
}

//=====================================================

- (void) setupAudio:(InputAndOutputDataCallBack)recordCbFunc And:(InputAndOutputDataCallBack)playbackCbFunc
{
    inputDataFunc = recordCbFunc;
    outputDataFunc = playbackCbFunc;
    
    [self setupAudioSession];
    [self setupIOUnit];
}

- (void) resetAudio
{
    [self destroyIOUnit];
    [self resetAudioSession];
    
}

- (void) start
{
    [self startIOUnit];
}

- (void) stop
{
    [self stopIOUnit];
}

@end
