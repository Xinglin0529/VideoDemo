//
//  ZARecordEncoder.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/11.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "ZARecordEncoder.h"

@interface ZARecordEncoder()
@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, copy) NSString *path;
@end

@implementation ZARecordEncoder

#pragma mark - life cycle

+ (ZARecordEncoder *)encoderWithPath:(NSString *)path width:(NSInteger)width height:(NSInteger)height channels:(int)channels sampleRate:(Float64)sampleRate {
    return [[ZARecordEncoder alloc] initWithPath:path width:width height:height channels:channels sampleRate:sampleRate];
}

- (instancetype)initWithPath:(NSString *)path width:(NSInteger)width height:(NSInteger)height channels:(int)channels sampleRate:(Float64)sampleRate {
    self = [super init];
    if (self) {
        self.path = path;
        [self za_removeItemAtPath:path];
        NSURL *url = [NSURL fileURLWithPath:path];
        _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
        _writer.shouldOptimizeForNetworkUse = YES;
        [self za_setupVideoInputWithWidth:width height:height];
        if (sampleRate != 0 && channels != 0) {
            [self za_setupAudioInputWithChannels:channels sampleRate:sampleRate];
        }
    }
    return self;
}

#pragma mark - public

- (BOOL)encode:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo {
    //数据是否准备写入
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        //写入状态为未知,保证视频先写入
        if (_writer.status == AVAssetWriterStatusUnknown && isVideo) {
            //获取开始写入的CMTime
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        //写入失败
        if (_writer.status == AVAssetWriterStatusFailed) {
            NSLog(@"writer error %@", _writer.error.localizedDescription);
            return NO;
        }
        //判断是否是视频
        if (isVideo) {
            //视频输入是否准备接受更多的媒体数据
            if (_videoInput.readyForMoreMediaData == YES) {
                //拼接数据
                [_videoInput appendSampleBuffer:sampleBuffer];
                return YES;
            }
        } else {
            //音频输入是否准备接受更多的媒体数据
            if (_audioInput.readyForMoreMediaData) {
                //拼接数据
//                [_audioInput appendSampleBuffer:sampleBuffer]; //不录制声音
                return YES;
            }
        }
    }
    return NO;
}

- (void)finishWithCompletionHandler:(void (^)())handler {
    [_writer finishWritingWithCompletionHandler:handler];
}

#pragma mark - private

- (void)za_setupVideoInputWithWidth:(NSInteger)width height:(NSInteger)height {
    //录制视频的一些配置，分辨率，编码方式等等
    NSDictionary *compression = @{AVVideoAverageBitRateKey: @(256.0 * 1024.0 * 16),
                                  AVVideoMaxKeyFrameIntervalKey: @(100),
                                  AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel};
    NSDictionary *settings = @{AVVideoCodecKey: AVVideoCodecH264,
                               AVVideoWidthKey: @(width),
                               AVVideoHeightKey: @(height),
                               AVVideoCompressionPropertiesKey: compression};
    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _videoInput.expectsMediaDataInRealTime = YES;
    [_writer addInput:_videoInput];
}

- (void)za_setupAudioInputWithChannels:(int)channels sampleRate:(Float64)sampleRate {
    //音频的一些配置包括音频各种这里为AAC,音频通道、采样率和音频的比特率
    NSDictionary *settings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                               AVNumberOfChannelsKey: @(channels),
                               AVSampleRateKey: @(sampleRate),
                               AVEncoderBitRateKey: @(128000)};
    _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:settings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _audioInput.expectsMediaDataInRealTime = YES;
    [_writer addInput:_audioInput];
    
}

- (void)za_removeItemAtPath:(NSString *)path {
    NSError *error;
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"ZARecordEncoder: %@", error.localizedDescription);
        }
    }
}

#pragma mark - getter & setter

@end
