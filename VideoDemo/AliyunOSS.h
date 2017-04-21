//
//  AliyunOSS.h
//  VideoDemo
//
//  Created by xudongdong on 2017/4/21.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AliyunOSSiOS/AliyunOSSiOS.h>

@interface ZAUploadFileInfo : NSObject

@property (nonatomic, strong) UIImage *thumbImage;
@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, copy) NSString *filePath; //文件路径
@property (nonatomic, copy) NSString *objectKey; //文件名
@property (nonatomic, strong) NSString* endpoint;
@property (nonatomic, strong) NSString* bucket;

@end

typedef void (^OnUploadSucceedListener) (ZAUploadFileInfo* fileInfo);
typedef void (^OnUploadFailedListener) (ZAUploadFileInfo* fileInfo, NSInteger code, NSString * message);
typedef void (^OnUploadProgressListener) (ZAUploadFileInfo* fileInfo, float progress);

@interface ZAUploadListener : NSObject

@property (nonatomic, copy) OnUploadSucceedListener success;
@property (nonatomic, copy) OnUploadFailedListener failure;
@property (nonatomic, copy) OnUploadProgressListener progress;

@end


@interface AliyunOSS : NSObject

- (instancetype)initWithListener:(ZAUploadListener *)listener;

/**
 添加视频上传
 */
- (BOOL)addFile:(NSString *)filePath object:(NSString *)object;

/**
 删除文件
 */
- (BOOL)deleteFile:(NSInteger)index;

/**
 获取上传文件列表
 */
- (NSMutableArray<ZAUploadFileInfo *> *)listFiles;

/**
 开始上传
 */
- (BOOL)start;

/**
 暂停上传
 */
- (BOOL)pause;

/**
 恢复上传
 */
- (BOOL)resume;

@end
