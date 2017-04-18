//
//  ZARecordViewController.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/11.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "ZARecordViewController.h"
#import <Masonry/Masonry.h>
#import "ZARecordEngine.h"
#import "ZARecordTimerView.h"

@interface ZARecordViewController ()

@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *takeCameraBtn;
@property (nonatomic, strong) UIButton *doneBtn;
@property (nonatomic, strong) UIButton *switchBtn;
@property (nonatomic, strong) UIImageView *takeImageView;
@property (nonatomic, assign) BOOL isCapturing;
@property (nonatomic, strong) ZARecordEngine *recordEngine;
@property (nonatomic, strong) ZARecordTimerView *timerview;

@end

@implementation ZARecordViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    [self za_setupSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.recordEngine) {
        self.recordEngine.previewLayer.frame = self.view.bounds;
        [self.view.layer insertSublayer:self.recordEngine.previewLayer atIndex:0];
    }
    [self.recordEngine startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.recordEngine stopRunning];
}

#pragma mark - event

- (void)dismiss {
    [self.recordEngine cancelSaveVideo];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)takeCamera {
    if (!self.recordEngine.isCapturing) {
        __weak typeof(self) weakself = self;
        [self.recordEngine startCapture:^{
            [weakself.timerview startWithTimeInterval:self.videoMaximumDuration completion:^{
                
            }];
        }];
    } else {
        [self.recordEngine stopCapture:^(UIImage *thumbImage, NSString *path) {
            
        }];
        [self.timerview stop];
    }
    [self za_switchBtnsStatus:self.recordEngine.isCapturing];
}

- (void)done {
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordViewController:videoPath:)]) {
        [self.delegate recordViewController:self videoPath:self.recordEngine.videoPath];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchCamera {
    [self.recordEngine switchCameraInputDevice];
}

#pragma mark - private

- (void)za_switchBtnsStatus:(BOOL)hidden {
    self.cancelBtn.hidden = hidden;
    self.doneBtn.hidden = hidden;
    self.switchBtn.hidden = hidden;
    self.takeImageView.hidden = !hidden;
}

- (void)za_setupSubviews {
    
    [self.view addSubview:self.timerview];
    [self.timerview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view);
        make.centerX.equalTo(self.view.mas_trailing).offset(-30);
        make.size.mas_equalTo(CGSizeMake(60, 20));
    }];
    
    self.takeCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.takeCameraBtn setImage:[UIImage imageNamed:@"sc_btn_take"] forState:UIControlStateNormal];
    [self.takeCameraBtn addTarget:self action:@selector(takeCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.takeCameraBtn];
    [self.takeCameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(70, 70));
        make.bottom.equalTo(self.view).offset(-20);
    }];

    self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelBtn setImage:[UIImage imageNamed:@"btn_cancel_a"] forState:UIControlStateNormal];
    [self.cancelBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.cancelBtn];
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.takeCameraBtn.mas_centerY);
        make.trailing.equalTo(self.view).offset(-20);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];

    self.doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneBtn.hidden = YES;
    [self.doneBtn setImage:[UIImage imageNamed:@"btn_camera_done_a"] forState:UIControlStateNormal];
    [self.doneBtn addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneBtn];
    [self.doneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(20);
        make.leading.equalTo(self.view).offset(20);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];

    self.switchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.switchBtn setImage:[UIImage imageNamed:@"btn_video_flip_camera"] forState:UIControlStateNormal];
    [self.switchBtn addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.switchBtn];
    [self.switchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.takeCameraBtn.mas_centerY);
        make.leading.equalTo(self.view).offset(20);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    self.takeImageView = [[UIImageView alloc] init];
    self.takeImageView.image = [UIImage imageNamed:@"icon_facial_btn_take"];
    self.takeImageView.hidden = YES;
    [self.takeCameraBtn addSubview:self.takeImageView];
    [self.takeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.takeImageView.superview);
    }];
}

#pragma mark - setter & getter

- (ZARecordEngine *)recordEngine {
    if (!_recordEngine) {
        _recordEngine = [[ZARecordEngine alloc] init];
    }
    return _recordEngine;
}

- (ZARecordTimerView *)timerview {
    if (!_timerview) {
        _timerview = [ZARecordTimerView new];
        _timerview.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    return _timerview;
}

@end
