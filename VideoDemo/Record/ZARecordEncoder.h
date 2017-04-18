//
//  ZARecordEncoder.h
//  VideoDemo
//
//  Created by xudongdong on 2017/4/11.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface ZARecordEncoder : NSObject

@property (nonatomic, copy, readonly) NSString *path;

+ (ZARecordEncoder *)encoderWithPath:(NSString *)path width:(NSInteger)width height:(NSInteger)height channels:(int)channels sampleRate:(Float64)sampleRate;

- (instancetype)initWithPath:(NSString *)path width:(NSInteger)width height:(NSInteger)height channels:(int)channels sampleRate:(Float64)sampleRate;

- (void)finishWithCompletionHandler:(void(^)())handler;

- (BOOL)encode:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;

@end
