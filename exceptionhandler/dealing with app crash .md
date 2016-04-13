###IOS App 如何捕获异常并做出相应处理

通过崩溃捕获和收集，可以收集到已发布App的异常，以便开发人员发现和修改bug,对于提高软件质量有着极大的帮助。

要实现崩溃捕获和收集的困难主要有这么几个：

```
1、如何捕获崩溃（比如c++常见的野指针错误或是内存读写越界，当发生这些情况时程序不是异常退出了吗，我们如何捕获它呢）

2、如何获取堆栈信息（告诉我们崩溃是哪个函数，甚至是第几行发生的，这样我们才可能重现并修改问题）

3、将错误日志上传到指定服务器

```

会引发崩溃的代码本质上就两类，一个是c/c++语言层面的错误，比如野指针，除零，内存访问异常等等；另一类是未捕获异常（Uncaught Exception），iOS下面最常见的就是objective-c的NSException（通过@throw抛出，比如，NSArray访问元素越界）。这些异常如果没有在最上层try住，那么程序就崩溃了。iOS系统底层也是unix或者是类unix系统，对于第一类语言层面的错误，可以通过信号机制来捕获（signal），即任何系统错误都会抛出一个错误信号，我们可以通过设定一个回调函数，然后在回调函数里面打印并发送错误日志。


####直接贴代码：

---

UncaughtExceptionHandler.h

```
#import <Foundation/Foundation.h>

@interface UncaughtExceptionHandler:NSObject

@end

void InstallUncaughtExceptionHandler();

```

UncaughtExceptionHandler.m

```
#import "UncaughtExceptionHandler.h"
#import <libkern/OSAtomic.h>
#import <execinfo.h>


NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t    UncaughtExceptionMaximum = 10;

const NSInteger  UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger  UncaughtExceptionHandlerReportAddressCount = 5;



@implementation UncaughtExceptionHandler

+ (NSArray*)backtrace {
    
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for(i = UncaughtExceptionHandlerSkipAddressCount; i < UncaughtExceptionHandlerSkipAddressCount + UncaughtExceptionHandlerReportAddressCount; i++) {
        
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    
    free(strs);
    
    return backtrace;
}


NSString *applicationDocumentsDirectory() {
    
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

//异常捕捉后
- (void)validateAndSaveCriticalApplicationData:(NSException *)exception
{
    NSArray *arr = [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    
    NSString *path = [applicationDocumentsDirectory() stringByAppendingPathComponent:@"exception.txt"];
    
    NSString *content=[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if(content == nil) content = @"";
    
    NSString *url = [NSString stringWithFormat:@"%@\n\n=============error crash report=============\nname:\n%@\nreason:\n%@\ncallStackSymbols:\n%@", content, name, reason, arr];
    
    [url writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    //除了可以选择写到应用下的某个文件，通过后续处理将信息发送到服务器等
    //还可以选择调用发送邮件的程序，发送信息到指定的邮件地址
    //或者调用某个处理程序来处理这个信息
}


- (void)handleException:(NSException *)exception
{
    [self validateAndSaveCriticalApplicationData:exception];
    
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    
    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
    {
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    }
    else
    {
        [exception raise];
    }
    
}

@end



void HandleException(NSException *exception)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum)
    {
        return;
    }
    
    NSArray *callStack = [UncaughtExceptionHandler backtrace];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    
    [[[UncaughtExceptionHandler alloc] init] performSelectorOnMainThread:@selector(handleException:) withObject:[NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo] waitUntilDone:YES];
    
}

void SignalHandler(int signal)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum)
    {
        return;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey];
    
    NSArray *callStack = [UncaughtExceptionHandler backtrace];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    [[[UncaughtExceptionHandler alloc] init] performSelectorOnMainThread:@selector(handleException:) withObject:[NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName reason:[NSString stringWithFormat:@"Signal %d was raised.", signal] userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey]] waitUntilDone:YES];
}

void InstallUncaughtExceptionHandler(void)
{
    NSSetUncaughtExceptionHandler(&HandleException);
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
    
    /*
     SIGABRT--程序中止命令中止信号
     SIGALRM--程序超时信号
     SIGFPE--程序浮点异常信号
     SIGILL--程序非法指令信号
     SIGHUP--程序终端中止信号
     SIGINT-- 程序键盘中断信号
     SIGKILL--程序结束接收中止信号
     SIGTERM--程序kill中止信号 
     SIGSTOP--程序键盘中止信号
     SIGSEGV--程序无效内存中止信号
     SIGBUS--程序内存字节未对齐中止信号
     SIGPIPE--程序Socket发送失败中止信号
     */
}


```

####使用方法：

包含头文件后直接调用InstallUncaughtExceptionHandler();即可，若发生异常则将崩溃日志写到exception.txt中，可根据自身需要进行修改。

---

####另外，这里有个技巧可以在崩溃后程序保持运行状态而不退出

```
CFRunLoopRef runLoop = CFRunLoopGetCurrent(); 
CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop); 
     
while (!dismissed) 
{ 
    for (NSString *mode in (__bridge NSArray *)allModes) 
    { 
        CFRunLoopRunInMode((__bridge CFStringRef)mode, 0.001, false); 
    } 
} 
     
CFRelease(allModes); 

```

在崩溃处理函数做完处理后，调用上述代码，可以重新构建程序主循环。这样，程序即便崩溃了，依然可以正常运行（当然，这个时候是处于不稳定状态，但是由于手持应用大多是短期操作，不会有挂机这种说法，所以稳定与否就无关紧要了）。

这里要在说明一个概念，那就是“可重入（reentrant）”。简单来说，当我们的崩溃回调函数是可重入的时候，那么再次发生崩溃的时候，依然可以正常运行这个新的函数；但是如果是不可重入的，则无法运行（这个时候就彻底死了）。要实现上面描述的效果，并且还要保证回调函数是可重入的几乎不可能。所以，我测试的结果是，objective-c的异常触发多少次都可以正常运行。但是如果多次触发错误信号，那么程序就会卡死。所以要慎重决定是否要应用这个技巧。





