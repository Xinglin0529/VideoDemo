//
//  ZAUploadOperation.h
//  VideoDemo
//
//  Created by xudongdong on 2017/4/21.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AliyunOSSiOS/AliyunOSSiOS.h>
#import "AliyunOSS.h"

@interface ZAUploadOperation : NSOperation

@property (nonatomic, copy) NSString *identifier;

+ (instancetype)operationWithUploadClient:(OSSClient *)client
                                 fileInfo:(ZAUploadFileInfo *)fileInfo
                                  success:(OnUploadSucceedListener)success
                                     fail:(OnUploadFailedListener)fail
                                 progress:(OnUploadProgressListener)progress;

- (instancetype)initOperationWithUploadClient:(OSSClient *)client
                                     fileInfo:(ZAUploadFileInfo *)fileInfo
                                      success:(OnUploadSucceedListener)success
                                      failure:(OnUploadFailedListener)failure
                                     progress:(OnUploadProgressListener)progress;

@end
