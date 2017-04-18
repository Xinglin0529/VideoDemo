//
//  ZARecordEngine.h
//  VideoDemo
//
//  Created by xudongdong on 2017/4/11.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVCaptureVideoPreviewLayer.h>
#import <UIKit/UIKit.h>

@interface ZARecordEngine : NSObject

@property (nonatomic, assign, readonly) BOOL isCapturing;
@property (nonatomic, strong, readonly) AVCaptureConnection        *videoConnection;
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, copy, readonly) NSString *videoPath;

/**
 启动录制功能
 */
- (void)startRunning;

/**
 关闭录制功能
 */
- (void)stopRunning;

/**
 开始录制
 */
- (void)startCapture:(void (^)())handler;

/**
 停止录制
 
 @param handler 视频缩略图
 */
- (void)stopCapture:(void (^)(UIImage *thumbImage, NSString *path))handler;

/**
 开启闪光灯
 */
- (void)openFlashLight;

/**
 关闭闪光灯
 */
- (void)closeFlashLight;

/**
 切换前后摄像头
 
 */
- (void)switchCameraInputDevice;

/**
 取消视频
 */
- (void)cancelSaveVideo;

/**
 保存视频
 */
- (void)saveVideo;

@end
