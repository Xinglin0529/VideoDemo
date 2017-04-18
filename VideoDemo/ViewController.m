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

@interface ViewController () <ZARecordViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"摄像" style:UIBarButtonItemStylePlain target:self action:@selector(callCamera)];
    
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [recordButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(callVideoRecord) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recordButton];
    [recordButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(200, 40));
    }];
}

- (void)callVideoRecord {
    ZARecordViewController *record = [ZARecordViewController new];
    record.delegate = self;
    record.videoMaximumDuration = 30 * 60;
    [self presentViewController:record animated:YES completion:nil];
}

- (void)recordViewController:(ZARecordViewController *)record videoPath:(NSString *)videoPath {
    
    NSURL *videoFileUrl = [NSURL fileURLWithPath:videoPath];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:videoFileUrl completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"保存视频失败:%@",error);
        } else {
            NSLog(@"保存视频到相册成功");
        }
    }];

    NSData *data = [[NSData alloc] initWithContentsOfFile:videoPath];
    NSString *message = [NSString stringWithFormat:@"视频大小:%.2fM", data.length / 1024.0 / 1024.0];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
    [alert show];
}

- (void)callCamera {
    [self.navigationController pushViewController:[ImagePickerViewController new] animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
