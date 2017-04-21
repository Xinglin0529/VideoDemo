//
//  ZAUploadOperation.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/21.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "ZAUploadOperation.h"

static NSString *const ZAOperationLockName = @"ZAOperationLockName";

@interface ZAUploadOperation ()

@property (nonatomic, strong) OSSClient *client;
@property (nonatomic, strong) ZAUploadFileInfo *fileInfo;
@property (nonatomic, copy) OnUploadSucceedListener success;
@property (nonatomic, copy) OnUploadFailedListener failure;
@property (nonatomic, copy) OnUploadProgressListener progress;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) NSArray *runLoopModes;

@end

@implementation ZAUploadOperation

@synthesize executing = _executing;
@synthesize cancelled = _cancelled;
@synthesize finished = _finished;

+ (instancetype)operationWithUploadClient:(OSSClient *)client
                                 fileInfo:(ZAUploadFileInfo *)fileInfo
                                  success:(OnUploadSucceedListener)success
                                     fail:(OnUploadFailedListener)failure
                                 progress:(OnUploadProgressListener)progress {
    return [[self alloc] initOperationWithUploadClient:client
                                              fileInfo:fileInfo
                                               success:success
                                                  failure:failure
                                              progress:progress];
}

- (instancetype)initOperationWithUploadClient:(OSSClient *)client
                                     fileInfo:(ZAUploadFileInfo *)fileInfo
                                      success:(OnUploadSucceedListener)success
                                      failure:(OnUploadFailedListener)failure
                                     progress:(OnUploadProgressListener)progress
{
    self = [super init];
    if (self) {
        self.client = client;
        self.fileInfo = fileInfo;
        self.success = success;
        self.failure = failure;
        self.progress = progress;
        self.lock = [[NSRecursiveLock alloc] init];
        self.runLoopModes = @[NSRunLoopCommonModes];
    }
    return self;
}

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"AsyncOperation"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)operationThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

#pragma mark - operation

- (void)cancel {
    [self.lock lock];
    if (!self.isCancelled && !self.isFinished) {
        [super cancel];
        [self KVONotificationWithNotiKey:@"isCancelled" state:&_cancelled stateValue:YES];
        if (self.isExecuting) {
            [self runSelector:@selector(cancelUpload)];
        }
    }
    [self.lock unlock];
}

- (void)cancelUpload {
    self.success = nil;
    self.failure = nil;
    self.progress = nil;
}

- (void)start {
    [self.lock lock];
    if (self.isCancelled) {
        [self finish];
        [self.lock unlock];
        return;
    }
    if (self.isFinished || self.isExecuting) {
        [self.lock unlock];
        return;
    }
    [self runSelector:@selector(startUpload)];
    [self.lock unlock];
}

- (void)startUpload {
    if (self.isCancelled || self.isFinished || self.isExecuting) {
        return;
    }
    [self KVONotificationWithNotiKey:@"isExecuting" state:&_executing stateValue:YES];
    [self uploadFile];
}

- (void)uploadFile {
    __weak typeof(self) weakSelf = self;
    [self.client resumableUploadFile:_fileInfo.filePath
                     withContentType:nil
                      withObjectMeta:nil
                        toBucketName:_fileInfo.bucket
                         toObjectKey:_fileInfo.objectKey
                         onCompleted:^(BOOL success, NSError * error) {
                             if (success) {
                                 if (weakSelf.success) {
                                     weakSelf.success(weakSelf.fileInfo);
                                 }
                             } else {
                                 if (weakSelf.failure) {
                                     weakSelf.failure(weakSelf.fileInfo, error.code, error.localizedDescription);
                                 }
                             }
                             [weakSelf finish];
                         }
                          onProgress:^(float progress) {
                              if (weakSelf.progress) {
                                  weakSelf.progress(weakSelf.fileInfo, progress);
                              }
                          }
     ];
}

- (void)finish {
    [self.lock lock];
    if (self.isExecuting) {
        [self KVONotificationWithNotiKey:@"isExecuting" state:&_executing stateValue:NO];
    }
    [self KVONotificationWithNotiKey:@"isFinished" state:&_finished stateValue:YES];
    [self.lock unlock];
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)KVONotificationWithNotiKey:(NSString *)key state:(BOOL *)state stateValue:(BOOL)stateValue {
    [self.lock lock];
    [self willChangeValueForKey:key];
    *state = stateValue;
    [self didChangeValueForKey:key];
    [self.lock unlock];
}

- (void)runSelector:(SEL)selecotr {
    [self performSelector:selecotr onThread:[[self class] operationThread] withObject:nil waitUntilDone:NO modes:self.runLoopModes];
}

@end
