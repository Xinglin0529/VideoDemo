//
//  VODUploadManager.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/20.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "VODUploader.h"

static NSString *const AccessKey    = @"LTAIsMmF6IAZv7MR";
static NSString *const SecretKey    = @"seqe7gasoD0pDSHJ2UdzBPyAC16bgu";
static NSString *const endPoint     = @"https://oss-cn-shanghai.aliyuncs.com";
static NSString *const bucketName   = @"test-video-save-bucketname";
static NSString *const multipartUploadKey = @"multipartUploadObject";

@interface VODUploader ()

@property (nonatomic, strong) VODUploadClient *client;

@end

@implementation VODUploader

- (instancetype)initWithListener:(VODUploadListener *)listener {
    self = [super init];
    if (self) {
        _client = [[VODUploadClient alloc] init];
        [_client init:AccessKey accessKeySecret:SecretKey listener:listener];
    }
    return self;
}

- (BOOL)addFile:(NSString *)filePath object:(NSString *)object vodInfo:(VodInfo *)vodInfo {
    return [_client addFile:filePath endpoint:endPoint bucket:bucketName object:object vodInfo:vodInfo];
}

/**
 添加视频上传
 */
- (BOOL)addFile:(NSString *)filePath object:(NSString *)object
{
    return [_client addFile:filePath endpoint:endPoint bucket:bucketName object:object];
}


/**
 删除文件
 */
- (BOOL)deleteFile:(int) index {
    return [_client deleteFile:index];
}

/**
 清除上传列表
 */
- (BOOL)clearFiles {
    return [_client clearFiles];
}


/**
 获取上传文件列表
 */
- (NSMutableArray<UploadFileInfo *> *)listFiles {
    return [_client listFiles];
}

/**
 开始上传
 */
- (BOOL)start {
    return [_client start];
}

/**
 停止上传
 */
- (BOOL)stop {
    return [_client stop];
}

/**
 暂停上传
 */
- (BOOL)pause {
    return [_client pause];
}

/**
 恢复上传
 */
- (BOOL)resume {
    return [_client resume];
}

@end
