//
//  AliyunOSSManager.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/20.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "AliyunOSSManager.h"

static NSString *const AccessKey    = @"LTAIsMmF6IAZv7MR";
static NSString *const SecretKey    = @"seqe7gasoD0pDSHJ2UdzBPyAC16bgu";
static NSString *const endPoint     = @"https://oss-cn-shanghai.aliyuncs.com";
static NSString *const bucketName   = @"test-video-save-bucketname";
static NSString *const multipartUploadKey = @"multipartUploadObject";

@interface AliyunOSSManager ()

@property (nonatomic, strong) OSSClient *client;

@end

@implementation AliyunOSSManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AliyunOSSManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        id <OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:AccessKey secretKey:SecretKey];
        OSSClientConfiguration *configutation = [[OSSClientConfiguration alloc] init];
        _client = [[OSSClient alloc] initWithEndpoint:endPoint credentialProvider:credential clientConfiguration:configutation];
    }
    return self;
}

- (OSSTask *)resumableUploadVideoWithFilePath:(NSString *)filePath
                                    objectKey:(NSString *)objectKey
                          uploadProgressBlock:(AliyunUploadProgressBlock)uploadProgressBlock
                                   completion:(AliyunCompletion)completion
                                   errorBlock:(AliyunError)errorBlock
{
    
    __block NSString *recordKey;

    return [[[[[[OSSTask taskWithResult:nil] continueWithBlock:^id(OSSTask *task) {
        // 为该文件构造一个唯一的记录键
        NSURL * fileURL = [NSURL fileURLWithPath:filePath];
        NSDate * lastModified;
        NSError * error;
        [fileURL getResourceValue:&lastModified forKey:NSURLContentModificationDateKey error:&error];
        if (error) {
            return [OSSTask taskWithError:error];
        }
        recordKey = [NSString stringWithFormat:@"%@-%@-%@-%@", bucketName, objectKey, [OSSUtil getRelativePath:filePath], lastModified];
        // 通过记录键查看本地是否保存有未完成的UploadId
        NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
        return [OSSTask taskWithResult:[userDefault objectForKey:recordKey]];
    }] continueWithSuccessBlock:^id(OSSTask *task) {
        if (!task.result) {
            // 如果本地尚无记录，调用初始化UploadId接口获取
            OSSInitMultipartUploadRequest * initMultipart = [OSSInitMultipartUploadRequest new];
            initMultipart.bucketName = bucketName;
            initMultipart.objectKey = objectKey;
//            initMultipart.contentType = @"application/octet-stream";
            initMultipart.contentType = @"video/mp4";
            return [self.client multipartUploadInit:initMultipart];
        }
        OSSLogVerbose(@"An resumable task for uploadid: %@", task.result);
        return task;
    }] continueWithSuccessBlock:^id(OSSTask *task) {
        NSString * uploadId = nil;
        
        if (task.error) {
            if (errorBlock) {
                errorBlock(task.error);
            }
            return task;
        }
        
        if ([task.result isKindOfClass:[OSSInitMultipartUploadResult class]]) {
            uploadId = ((OSSInitMultipartUploadResult *)task.result).uploadId;
        } else {
            uploadId = task.result;
        }
        
        if (!uploadId) {
            return [OSSTask taskWithError:[NSError errorWithDomain:OSSClientErrorDomain
                                                              code:OSSClientErrorCodeNilUploadid
                                                          userInfo:@{OSSErrorMessageTOKEN: @"Can't get an upload id"}]];
        }
        // 将“记录键：UploadId”持久化到本地存储
        NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:uploadId forKey:recordKey];
        [userDefault synchronize];
        return [OSSTask taskWithResult:uploadId];
    }] continueWithSuccessBlock:^id(OSSTask *task) {
        // 持有UploadId上传文件
        OSSResumableUploadRequest * resumableUpload = [OSSResumableUploadRequest new];
        resumableUpload.bucketName = bucketName;
        resumableUpload.objectKey = objectKey;
        resumableUpload.uploadId = task.result;
        resumableUpload.partSize = 1024 * 1024;
        resumableUpload.uploadingFileURL = [NSURL fileURLWithPath:filePath];
        resumableUpload.uploadProgress = uploadProgressBlock;
        return [self.client resumableUpload:resumableUpload];
    }] continueWithBlock:^id(OSSTask *task) {
        if (task.error) {
            if (errorBlock) {
                errorBlock(task.error);
            }
            if ([task.error.domain isEqualToString:OSSClientErrorDomain] && task.error.code == OSSClientErrorCodeCannotResumeUpload) {
                // 如果续传失败且无法恢复，需要删除本地记录的UploadId，然后重启任务
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:recordKey];
            }
        } else {
            if (completion) {
                completion();
            }
            NSLog(@"upload completed!");
            // 上传成功，删除本地保存的UploadId
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:recordKey];
        }
        return task;
    }];
}

- (void)uploadVideo:(NSString *)filePath objectKey:(NSString *)objectKey {
    __block NSString *uploadId = nil;
    OSSInitMultipartUploadRequest *init = [[OSSInitMultipartUploadRequest alloc] init];
    init.bucketName = bucketName;
    init.objectKey = objectKey;
    init.contentType = @"video/mp4";
    OSSTask *task = [_client multipartUploadInit:init];
    [[task continueWithBlock:^id _Nullable(OSSTask * _Nonnull task) {
        if (!task.error) {
            OSSInitMultipartUploadResult *result = task.result;
            uploadId = result.uploadId;
        } else {
            NSLog(@"init uploadid failed, error: %@", task.error);
        }
        return nil;
    }] waitUntilFinished];
    
    OSSResumableUploadRequest *resumableUpload= [OSSResumableUploadRequest new];
    resumableUpload.bucketName = bucketName;
    resumableUpload.objectKey = objectKey;
    resumableUpload.uploadId = uploadId;
    resumableUpload.partSize = 1024 * 1024;
    resumableUpload.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
    };
    resumableUpload.uploadingFileURL = [NSURL fileURLWithPath:filePath];
    
    OSSTask *resumeTask = [_client resumableUpload:resumableUpload];
    [resumeTask continueWithBlock:^id _Nullable(OSSTask * _Nonnull task) {
        if (task.error) {
            NSLog(@"error: %@", task.error);
            if ([task.error.domain isEqualToString:OSSClientErrorDomain] && task.error.code ==
                OSSClientErrorCodeCannotResumeUpload) {
                // 该任务无法续传，需要获取新的uploadId重新上传
            }
        } else {
            NSLog(@"Upload file success");
        }
        return nil;
    }];
    [resumeTask waitUntilFinished];
    
//    [resumableUpload cancel];
}































@end
