//
//  VODUploadManager.h
//  VideoDemo
//
//  Created by xudongdong on 2017/4/20.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VODUpload/VODUploadClient.h>
#import <VODUpload/VODUploadModel.h>

@interface VODUploader : NSObject

- (instancetype)initWithListener:(VODUploadListener *)listener;

/**
 添加视频上传
 */
- (BOOL)addFile:(NSString *)filePath
         object:(NSString *)object
        vodInfo:(VodInfo *)vodInfo;

/**
 添加视频上传
 */
- (BOOL)addFile:(NSString *)filePath object:(NSString *)object;

/**
 删除文件
 */
- (BOOL)deleteFile:(int) index;

/**
 清除上传列表
 */
- (BOOL)clearFiles;


/**
 获取上传文件列表
 */
- (NSMutableArray<UploadFileInfo *> *)listFiles;

/**
 开始上传
 */
- (BOOL)start;

/**
 停止上传
 */
- (BOOL)stop;

/**
 暂停上传
 */
- (BOOL)pause;

/**
 恢复上传
 */
- (BOOL)resume;

@end
