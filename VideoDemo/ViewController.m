//
//  ViewController.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/10.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "ViewController.h"
#import "ImagePickerViewController.h"
#import "ZARecordViewController.h"
#import <Masonry/Masonry.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <Qiniu/QiniuSDK.h>
#import <AFNetworking/AFNetworking.h>
#import <AliyunOSSiOS/AliyunOSSiOS.h>
#import "AliyunOSSManager.h"
#import "ZAMeProgressView.h"
#import "VODUploader.h"
#import "VideoViewController.h"

@interface ViewController () <ZARecordViewControllerDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionUploadTask *uploadTask;
@property (nonatomic, strong) ZAMeProgressView *progressView;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *videoName;
@property (nonatomic, strong) UIButton *pauseBtn;
@property (nonatomic, assign) BOOL pause;
@property (nonatomic, strong) OSSTask *task;
@property (nonatomic, strong) VODUploader *uploader;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"拍摄视频" style:UIBarButtonItemStylePlain target:self action:@selector(callCamera)];
    
    self.progressView = [[ZAMeProgressView alloc] initWithFrame:CGRectMake(0, 0, 300, 10)];
    self.progressView.indicatorColor = [UIColor redColor];
    [self.view addSubview:self.progressView];
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(84);
        make.size.mas_equalTo(CGSizeMake(300, 10));
    }];
    
    __weak typeof(self) weakself = self;
    VODUploadListener *listener = [[VODUploadListener alloc] init];
    listener.success = ^(UploadFileInfo *fileInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"上传成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
            [weakself.progressView updateProgress:0 animated:NO];
        });
    };
    listener.failure = ^(UploadFileInfo *fileInfo, NSString *code, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
        });
    };
    listener.progress = ^(UploadFileInfo *fileInfo, long uploadedSize, long totalSize) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.progressView updateProgress:(CGFloat)uploadedSize / (CGFloat)totalSize animated:NO];
        });
    };
    listener.retryResume = ^{
        
    };
    
    self.uploader = [[VODUploader alloc] initWithListener:listener];
    
    
    [self getVideoFiles];
}

- (void)recordViewController:(ZARecordViewController *)record videoPath:(NSString *)videoPath videoName:(NSString *)videoName {
    
    NSURL *videoFileUrl = [NSURL fileURLWithPath:videoPath];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:videoFileUrl completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"保存视频失败:%@",error);
        } else {
            NSLog(@"保存视频到相册成功");
        }
    }];

    self.filePath = videoPath;
    self.videoName = videoName;
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:videoPath];
    NSString *message = [NSString stringWithFormat:@"视频大小:%.2fM", data.length / 1024.0 / 1024.0];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
}
- (IBAction)uploadAction:(id)sender {
    //    self.filePath = @"/var/mobile/Containers/Data/Application/9061C2D3-FFF6-4F27-9BAE-4EDE20AA364D/Documents/origin_videos/ZAVIDEO1492671320.mp4";
    //    self.videoName = @"ZAVIDEO1492671320";
    
    if (!self.filePath || !self.videoName) {
        return;
    }
    
    [self uploadVideo:self.filePath objectKey:self.videoName];
//    [self.uploader addFile:self.filePath object:self.videoName];
//    [self.uploader start];
}

- (IBAction)resumeAction:(id)sender {
    [self.uploader resume];
}

- (IBAction)pauseAction:(id)sender {
    [self.uploader pause];
}

- (IBAction)pushNext:(id)sender {
    VideoViewController *video = [[VideoViewController alloc] init];
    [self.navigationController pushViewController:video animated:YES];
}

- (void)callCamera {
    
    ZARecordViewController *record = [ZARecordViewController new];
    record.delegate = self;
    record.videoMaximumDuration = 30 * 60;
    [self presentViewController:record animated:YES completion:nil];
    
}

- (void)uploadVideo:(NSString *)filepath objectKey:(NSString *)objectKey {
    self.task = [[AliyunOSSManager sharedInstance] resumableUploadVideoWithFilePath:filepath objectKey:objectKey uploadProgressBlock:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView updateProgress:(CGFloat)totalBytesSent / (CGFloat)totalBytesExpectedToSend animated:NO];
        });
    } completion:^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"上传成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    } errorBlock:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:error.localizedDescription delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }];
}

- (void)getVideoFiles {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"origin_videos"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    [manager fileExistsAtPath:path isDirectory:&isDir];
    if (isDir) {
        NSError *error;
        NSArray *subpaths = [manager contentsOfDirectoryAtPath:path error:&error];
        NSLog(@"----------%@", subpaths);
    }
}

- (NSString *)getVideoTimeInterval:(NSURL *)url {
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:0];
    // 初始化视频媒体文件
    NSInteger second = 0;
    second = (NSInteger)urlAsset.duration.value / (NSInteger)urlAsset.duration.timescale;
    
    // 获取视频总时长,单位秒
    NSLog(@"movie duration : %ld", (long)second);
    NSInteger temp = second % 60;
    if (temp == 0) {
        temp = second / 60;
        if (temp >= 10) {
            return [NSString stringWithFormat:@"%ld:00", second / 60];
        } else {
            return [NSString stringWithFormat:@"0%ld:00", second / 60];
        }
    } else {
        if (second % 60 >= 10) {
            return [NSString stringWithFormat:@"%ld:%ld", second / 60, second % 60];
        } else {
            return [NSString stringWithFormat:@"%ld:0%ld", second / 60, second % 60];
        }
    }
}

#pragma mark - QiqiuSDK

- (void)qn_upload {
    QNUploadOption *option = [[QNUploadOption alloc] initWithMime:@"Mime" progressHandler:^(NSString *key, float percent) {
        
    } params:@{@"param": @"param"} checkCrc:YES cancellationSignal:^BOOL{
        return NO;
    }];
    NSString *token = @"";
    QNUploadManager *upManager = [[QNUploadManager alloc] init];
    NSData *data = [@"hello world" dataUsingEncoding:NSUTF8StringEncoding];
    [upManager putData:data key:@"" token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        
    } option:option];
}


#pragma mark - 
- (void)afn_breakpointUpload:(NSString *)URLString filePath:(NSString *)filePath {
    // 1 指定下载文件地址 URLString
    // 2 获取保存的文件路径 filePath
    // 3 创建 NSURLRequest
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    unsigned long long downloadedBytes = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        // 3.1 若之前下载过 , 则在 HTTP 请求头部加入 Range
        // 获取已下载文件的 size
//        downloadedBytes = [self fileSizeForPath:filePath];
        
        // 验证是否下载过文件
        if (downloadedBytes > 0) {
            // 若下载过 , 断点续传的时候修改 HTTP 头部部分的 Range
            NSMutableURLRequest *mutableURLRequest = [request mutableCopy];
            NSString *requestRange =
            [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
            [mutableURLRequest setValue:requestRange forHTTPHeaderField:@"Range"];
            request = mutableURLRequest;
        }
    }
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:request fromData:[[NSData alloc] init] progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
    }];

    [uploadTask resume];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
