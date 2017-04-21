//
//  AliyunOSSManager.h
//  VideoDemo
//
//  Created by xudongdong on 2017/4/20.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AliyunOSSiOS/AliyunOSSiOS.h>

typedef void (^AliyunUploadProgressBlock)(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend);
typedef void (^AliyunCompletion)();
typedef void (^AliyunError)(NSError *error);

@interface AliyunOSSManager : NSObject

+ (instancetype)sharedInstance;

- (OSSTask *)resumableUploadVideoWithFilePath:(NSString *)filePath
                                    objectKey:(NSString *)objectKey
                          uploadProgressBlock:(AliyunUploadProgressBlock)uploadProgressBlock
                                   completion:(AliyunCompletion)completion
                                   errorBlock:(AliyunError)errorBlock;

@end
