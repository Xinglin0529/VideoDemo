//
//  AliyunOSS.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/21.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "AliyunOSS.h"
#import "ZAUploadOperation.h"

static NSString *const AccessKey    = @"LTAIsMmF6IAZv7MR";
static NSString *const SecretKey    = @"seqe7gasoD0pDSHJ2UdzBPyAC16bgu";
static NSString *const endPoint     = @"https://oss-cn-shanghai.aliyuncs.com";
static NSString *const bucketName   = @"test-video-save-bucketname";
static NSString *const multipartUploadKey = @"multipartUploadObject";

@interface AliyunOSS ()

@property (nonatomic, strong) OSSClient *client;
@property (nonatomic, strong) ZAUploadListener *listener;
@property (nonatomic, strong) NSMutableArray <ZAUploadFileInfo *> *uploadFiles;
@property (nonatomic, strong) NSMutableArray <OSSTaskHandler *> *handlers;
@property (nonatomic, strong) NSOperationQueue *queue;
@end

@implementation AliyunOSS

- (instancetype)initWithListener:(ZAUploadListener *)listener {
    self = [super init];
    if (self) {
        id <OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:AccessKey secretKey:SecretKey];
        OSSClientConfiguration *configutation = [[OSSClientConfiguration alloc] init];
        _client = [[OSSClient alloc] initWithEndpoint:endPoint credentialProvider:credential clientConfiguration:configutation];
        _listener = listener;
    }
    return self;
}

/**
 添加视频上传
 */
- (BOOL)addFile:(NSString *)filePath object:(NSString *)object {
    ZAUploadFileInfo *uploadInfo = [ZAUploadFileInfo new];
    uploadInfo.filePath = filePath;
    uploadInfo.objectKey = object;
    uploadInfo.endpoint = endPoint;
    uploadInfo.bucket = bucketName;
    [self.uploadFiles addObject:uploadInfo];
    return YES;
}

/**
 删除文件
 */
- (BOOL)deleteFile:(NSInteger)index {
    [self.uploadFiles removeObjectAtIndex:index];
    return YES;
}

/**
 获取上传文件列表
 */
- (NSMutableArray<ZAUploadFileInfo *> *)listFiles {
    return self.uploadFiles;
}

/**
 开始上传
 */
- (BOOL)start {
    [self startRequest];
    return YES;
}

/**
 暂停上传
 */
- (BOOL)pause {
    [self.queue setSuspended:YES];
    return YES;
}

/**
 恢复上传
 */
- (BOOL)resume {
    [self.queue setSuspended:NO];
    return YES;
}

- (void)startRequest {
    for (NSInteger i = 0; i < self.uploadFiles.count; i++) {
        ZAUploadFileInfo *info = self.uploadFiles[i];
        ZAUploadOperation *operation = [self createOperation:_client
                                                    fileInfo:info
                                                     success:_listener.success
                                                     failure:_listener.failure
                                                    progress:_listener.progress];
        [self.queue addOperation:operation];
    }
}

- (ZAUploadOperation *)createOperation:(OSSClient *)client
                              fileInfo:(ZAUploadFileInfo *)fileInfo
                               success:(OnUploadSucceedListener)success
                               failure:(OnUploadFailedListener)failure
                              progress:(OnUploadProgressListener)progress {
    return [ZAUploadOperation operationWithUploadClient:client
                                               fileInfo:fileInfo
                                                success:success
                                                   fail:failure
                                               progress:progress];
}

#pragma mark - getter & setter

- (NSMutableArray<ZAUploadFileInfo *> *)uploadFiles {
    if (!_uploadFiles) {
        _uploadFiles = @[].mutableCopy;
    }
    return _uploadFiles;
}

- (NSMutableArray<OSSTaskHandler *> *)handlers {
    if (!_handlers) {
        _handlers = @[].mutableCopy;
    }
    return _handlers;
}

- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
    }
    return _queue;
}

@end

@implementation ZAUploadFileInfo

@end

@implementation ZAUploadListener

@end
