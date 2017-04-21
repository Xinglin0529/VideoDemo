//
//  ZARecordEngine.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/11.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "ZARecordEngine.h"
#import "ZARecordEncoder.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define ZAVIDEO_PREFIX                  @"ZAVIDEO"
#define ZAVIDEO_ORIGINAL_VIDEO          @"origin_videos"
#define ZAVIDEO_COMPRESSION_VIDEO       @"compression_videos"

@interface ZARecordEngine() <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, CAAnimationDelegate>
{
    NSInteger _width;
    NSInteger _height;
    int _channels;
    Float64 _sampleRare;
}
@property (nonatomic, strong) ZARecordEncoder            *recordEncoder;
@property (nonatomic, strong) AVCaptureSession           *recordSession;//捕获视频的会话
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;//捕获到的视频呈现的layer
@property (nonatomic, strong) AVCaptureDeviceInput       *captureDeviceInput;//摄像头输入
@property (nonatomic, strong) AVCaptureDeviceInput       *audioMicInput;//麦克风输入
@property (nonatomic, copy)   dispatch_queue_t           captureQueue;//录制的队列
@property (nonatomic, strong) AVCaptureConnection        *audioConnection;//音频录制连接
@property (nonatomic, strong) AVCaptureConnection        *videoConnection;//视频录制连接
@property (nonatomic, strong) AVCaptureVideoDataOutput   *videoOutput;//视频输出
@property (nonatomic, strong) AVCaptureAudioDataOutput   *audioOutput;//音频输出
@property (nonatomic, assign) BOOL isCapturing;//正在录制
@property (nonatomic, copy)   NSString *videoPath;
@property (nonatomic, copy)   NSString *videoName;

@end

@implementation ZARecordEngine

#pragma mark - public

- (void)startRunning {
    self.isCapturing = NO;
    [self.recordSession startRunning];
}

- (void)stopRunning {
    if (self.recordSession) {
        [self.recordSession stopRunning];
    }
}

- (void)startCapture:(void (^)())handler {
    @synchronized (self) {
        if (!self.isCapturing) {
            self.isCapturing = YES;
        }
        if (handler) {
            handler();
        }
    }
}

- (void)stopCapture:(void (^)(UIImage *, NSString *))handler {
    @synchronized (self) {
        if (self.isCapturing) {
            self.isCapturing = NO;
        }
        NSString *path = self.recordEncoder.path;
        __weak typeof(self) weakself = self;
        dispatch_async(_captureQueue, ^{
            [self.recordEncoder finishWithCompletionHandler:^{
                if (!path) {
                    handler(nil, nil);
                    weakself.recordEncoder = nil;
                    return ;
                }
                NSURL *url = [NSURL fileURLWithPath:path];
                UIImage *thumb = [weakself za_getVideoThumbImage:url];
                handler(thumb, path);
                weakself.recordEncoder = nil;
            }];
        });
    }
}

- (void)openFlashLight {
    AVCaptureDevice *backCamera = [self za_cameraWithPosition:AVCaptureDevicePositionBack];
    if (backCamera.torchMode == AVCaptureTorchModeOff) {
        [backCamera lockForConfiguration:nil];
        backCamera.torchMode = AVCaptureTorchModeOn;
        backCamera.flashMode = AVCaptureFlashModeOn;
        [backCamera unlockForConfiguration];
    }
}

- (void)closeFlashLight {
    AVCaptureDevice *backCamera = [self za_cameraWithPosition:AVCaptureDevicePositionBack];
    if (backCamera.torchMode == AVCaptureTorchModeOn) {
        [backCamera lockForConfiguration:nil];
        backCamera.torchMode = AVCaptureTorchModeOff;
        backCamera.flashMode = AVCaptureTorchModeOff;
        [backCamera unlockForConfiguration];
    }
}

- (void)switchCameraInputDevice {
    [self za_switchCamera];
}

- (void)saveVideo
{
    NSURL *videoFileUrl = [NSURL fileURLWithPath:self.videoPath];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:videoFileUrl completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"保存视频失败:%@",error);
        } else {
            NSLog(@"保存视频到相册成功");
        }
    }];
}

- (void)cancelSaveVideo {
    [self za_removeVideoItem];
}

#pragma mark - event

- (void)areaChange:(NSNotification *)noti {
    
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    BOOL isVideo = YES;
    @synchronized (self) {
        if (!self.isCapturing) {
            return;
        }
        if (captureOutput != self.videoOutput) {
            isVideo = NO;
        }
        if (!self.recordEncoder && !isVideo) {
            [self za_setupAudio:sampleBuffer];
            NSString *videoName = [self za_videoName];
            self.videoPath = [[self za_videoCacheDirectoryPath:ZAVIDEO_ORIGINAL_VIDEO] stringByAppendingPathComponent:videoName];
            self.videoName = videoName;
            self.recordEncoder = [ZARecordEncoder encoderWithPath:self.videoPath width:_width height:_height channels:_channels sampleRate:_sampleRare];
        }
        [self.recordEncoder encode:sampleBuffer isVideo:isVideo];
    }
}

#pragma mark - private

- (void)za_removeVideoItem {
    NSError *error;
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.videoPath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.videoPath error:&error];
        if (error) {
            NSLog(@"ZARecordEngine: %@", error.localizedDescription);
        }
    }
}

- (AVCaptureDevice *)za_cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void)za_switchCamera {
    AVCaptureDevice *currentDevice = [self.captureDeviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    [self za_removeNotificationFromCaptureDevice:currentDevice];

    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toChangePosition = AVCaptureDevicePositionBack;
    }
    toChangeDevice = [self za_cameraWithPosition:toChangePosition];
    [self za_addNotificationToCaptureDevice:toChangeDevice];
    AVCaptureDeviceInput *toChangeDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:toChangeDevice error:nil];
    
    [self.recordSession beginConfiguration];
    [self.recordSession removeInput:self.captureDeviceInput];
    if ([self.recordSession canAddInput:toChangeDeviceInput]) {
//        [self za_addAnimation];
//        [self za_rotationAnimation];
        [self.recordSession addInput:toChangeDeviceInput];
        self.captureDeviceInput = toChangeDeviceInput;
    }
    [self.recordSession commitConfiguration];
}

#pragma mark - Notification

-(void)za_addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice{
    [self za_changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
    }];
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

-(void)za_removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

-(void)za_changeDeviceProperty:(void(^)(AVCaptureDevice* captureDevice))propertyChange{
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

- (UIImage *)za_getVideoThumbImage:(NSURL *)videoURL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:videoURL options:opts];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    CMTime actualTime;
    NSError *error = nil;
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0, 600) actualTime:&actualTime error:&error];
    if (error) {
        return nil;
    }
    return [UIImage imageWithCGImage:img];
}

- (NSString *)za_videoCacheDirectoryPath:(NSString *)name {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:name];
    BOOL isDir;
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL exist = [manager fileExistsAtPath:path isDirectory:&isDir];
    if (!isDir || !exist) {
        NSError *error;
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"ZARecordEngine: %@", error.localizedDescription);
        }
    }
    return path;
}

- (NSString *)za_videoName {
    NSInteger interval = (NSInteger)[[NSDate date] timeIntervalSince1970];
    NSString *timeStamp = [NSString stringWithFormat:@"%ld", (long)interval];
    NSString *fileName = [NSString stringWithFormat:@"%@%@.mp4",ZAVIDEO_PREFIX, timeStamp];
    return fileName;
}

- (void)za_setupAudio:(CMSampleBufferRef)sampleBuffer {
    CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    _sampleRare = asbd -> mSampleRate;
    _channels = asbd -> mChannelsPerFrame;
}

- (void)za_addAnimation {
    CATransition *animation = [CATransition animation];
    animation.duration = 0.45;
    animation.type = @"oglFlip";
    animation.subtype = kCATransitionFromRight;
    [self.previewLayer addAnimation:animation forKey:@"animation"];
}

- (void)za_rotationAnimation {
    CATransform3D affine = CATransform3DIdentity;
    affine.m34 = - 1 / 600.0;
    
    CATransform3D rotation = CATransform3DIdentity;
    rotation = CATransform3DMakeRotation(M_PI * 2, 0, 1, 0);
    
    CATransform3D concat = CATransform3DConcat(affine, rotation);
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.45;
    animation.toValue = [NSValue valueWithCATransform3D:concat];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    [self.previewLayer addAnimation:animation forKey:@"rotation"];
}

#pragma mark - getter & setter

- (AVCaptureSession *)recordSession {
    if (!_recordSession) {
        _recordSession = [[AVCaptureSession alloc] init];
        _recordSession.sessionPreset = AVCaptureSessionPreset640x480;
        
        //优先获取前置摄像头输入,前置摄像头不可用，则使用后置摄像头
        AVCaptureDevice *captureDevice;
        captureDevice = [self za_cameraWithPosition:AVCaptureDevicePositionFront];
        if (!captureDevice) {
            captureDevice = [self za_cameraWithPosition:AVCaptureDevicePositionBack];
        }
        
        NSError *error=nil;
        //根据输入设备初始化设备输入对象，用于获得输入数据
        self.captureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
        if (error) {
            NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        }

        if ([_recordSession canAddInput:_captureDeviceInput]) {
            [_recordSession addInput:_captureDeviceInput];
        }
        
        //麦克风输入
        if ([_recordSession canAddInput:self.audioMicInput]) {
            [_recordSession addInput:self.audioMicInput];
        }
        
        //视频输出
        if ([_recordSession canAddOutput:self.videoOutput]) {
            [_recordSession addOutput:self.videoOutput];
            //视频分辨率
            _width = 640;
            _height = 480;
        }
        
        //音频输出
        if ([_recordSession canAddOutput:self.audioOutput]) {
            [_recordSession addOutput:self.audioOutput];
        }
        
        [self.videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
    return _recordSession;
}

- (AVCaptureDeviceInput *)audioMicInput {
    if (!_audioMicInput) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"获取麦克风失败~");
        }
    }
    return _audioMicInput;
}

- (AVCaptureVideoDataOutput *)videoOutput {
    if (_videoOutput == nil) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey, nil];
        _videoOutput.videoSettings = setcapSettings;
    }
    return _videoOutput;
}

- (AVCaptureAudioDataOutput *)audioOutput {
    if (_audioOutput == nil) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}

- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    return _videoConnection;
}

- (AVCaptureConnection *)audioConnection {
    if (_audioConnection == nil) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.recordSession];
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _previewLayer = preview;
    }
    return _previewLayer;
}

- (dispatch_queue_t)captureQueue {
    if (_captureQueue == nil) {
        _captureQueue = dispatch_queue_create("com.test.capture", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}

@end
