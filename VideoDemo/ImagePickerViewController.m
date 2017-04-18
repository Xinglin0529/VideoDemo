//
//  ImagePickerViewController.m
//  VedioRecord
//
//  Created by xudongdong on 2017/4/6.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "ImagePickerViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ImagePickerViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *sizeLabel;

@end

@implementation ImagePickerViewController

static void showAlert(NSString *message) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"拍摄" style:UIBarButtonItemStylePlain target:self action:@selector(openCamera)];
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.sizeLabel];
}

- (void)openCamera {
    if (![self openCameraForVideo]) {
        NSLog(@"打开摄像头失败");
    }
}

- (BOOL)openCameraForVideo
{
    // 一般情况下用这个判断
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // 该设备不支持拍照
        return NO;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.mediaTypes =  [[NSArray alloc] initWithObjects:(NSString*)kUTTypeMovie,nil];
    picker.videoMaximumDuration = 30 * 60.f; // 视频的最大录制时长
    picker.videoQuality = UIImagePickerControllerQualityType640x480;
    picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo; //相机的模式 拍照/摄像
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
    
    return YES;
}

#pragma mark - delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        // 图片处理
        UIImage *image = nil;
        if ([picker allowsEditing]) {
            image = info[UIImagePickerControllerEditedImage];//获取编辑后的照片
        }else {
            image = info[UIImagePickerControllerOriginalImage];//获取原始照片
        }
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(photoPath:didFinishSaveWithError:contextINfo:), nil);//保存到相簿
        }
        
        self.imageView.image = image;
        
    }else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        // 视频处理
        NSURL *videoUrl = info[UIImagePickerControllerMediaURL];//视频路径
        self.sizeLabel.text = [NSString stringWithFormat:@"压缩之前大小%fMB", [self fileSize:videoUrl]];
        UIImage *image = [self get_videoThumbImage:videoUrl];
        self.imageView.image = image;
        
        [self convertVideo:videoUrl];
    }
    // 选择图片后手动销毁界面
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)convertVideo:(NSURL *)videoPath {
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *fullPath = [document stringByAppendingPathComponent:@"record.mp4"];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtPath:fullPath error:nil];
    
    //转码配置
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoPath options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        //AVAssetExportPresetLowQuality  3g  环境
        //AVAssetExportPresetMediumQuality  wifi 环境
        //AVAssetExportPresetHighestQuality  原来的质量
        AVAssetExportSession *exportSession= [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputURL = [NSURL fileURLWithPath:fullPath];
        exportSession.outputFileType = AVFileTypeMPEG4;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            int exportStatus = exportSession.status;
            switch (exportStatus)
            {
                case AVAssetExportSessionStatusFailed:
                {
                    // log error to text view
                    NSError *exportError = exportSession.error;
                    NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
                    self.sizeLabel.text = [NSString stringWithFormat:@"-Fail-"];
                    break;
                }
                case AVAssetExportSessionStatusCompleted:
                {
                    [self saveVideo:[NSURL fileURLWithPath:fullPath]];
                    NSString *message = [NSString stringWithFormat:@"压缩之后大小%fMB", [self fileSize:[NSURL fileURLWithPath:fullPath]]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        showAlert(message);
                    });
                }
            }
        }];
    }
}

/**
 获取视频时长
 */
- (CGFloat)get_videoTotalWith:(NSURL *)videoURL
{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:videoURL options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    return second;
}
/**
 获取视频缩略图
 */

- (UIImage *)get_videoThumbImage:(NSURL *)videoURL
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

- (CGFloat)fileSize:(NSURL *)path
{
    return [[NSData dataWithContentsOfURL:path] length]/1024.00 /1024.00;
}

- (void)saveVideo:(NSURL *)outputFileURL
{
    //ALAssetsLibrary提供了我们对iOS设备中的相片、视频的访问。
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"保存视频失败:%@",error);
        } else {
            NSLog(@"保存视频到相册成功");
        }
    }];
}

//图片保存到相册之后的回调
- (void)photoPath:(NSString *)path didFinishSaveWithError:(NSError *)error contextINfo:(void *)contextInfo
{
    if (error) {
        // 保存失败
    }else {
        // 处理图片
    }
}

//视频保存到相册之后的回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        // 保存失败
    }else {
        // 处理视频
        
    }
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = CGRectMake(100, 100, 175, 200);
    }
    return _imageView;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc] init];
        _sizeLabel.font = [UIFont systemFontOfSize:20];
        _sizeLabel.textAlignment = NSTextAlignmentCenter;
        _sizeLabel.frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame) + 20, [UIScreen mainScreen].bounds.size.width, 60);
    }
    return _sizeLabel;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
