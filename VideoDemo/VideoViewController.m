//
//  VideoViewController.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/10.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "VideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>
#import "VideoTableViewCell.h"
#import "VODUploader.h"
#import "AliyunOSS.h"

static NSString *const VideoTableViewCellIdentifier = @"VideoTableViewCell";

typedef NS_ENUM(NSInteger, UploadStatus) {
    UploadStatusStart,//开始
    UploadStatusPause,//暂停
    UploadStatusContinue //继续上传
};

@interface VideoViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataList;
@property (nonatomic, strong) VODUploader *uploader;
@property (nonatomic, strong) UIButton *uploadBtn;
@property (nonatomic, assign) UploadStatus uploadStatus;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configVideoData];
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.uploadBtn];
    self.uploadStatus = UploadStatusStart;
    
    __weak typeof(self) weakself = self;
    VODUploadListener *listener = [[VODUploadListener alloc] init];
    listener.success = ^(UploadFileInfo *fileInfo) {
        NSLog(@"-----------------完成!!!!!");
        [weakself deleteTableViewCell:fileInfo];
    };
    listener.failure = ^(UploadFileInfo *fileInfo, NSString *code, NSString *message) {
        
    };
    listener.progress = ^(UploadFileInfo *fileInfo, long uploadedSize, long totalSize) {
        NSInteger i = [weakself indexOfModelWithFileInfo:fileInfo];
        VideoModel *model = weakself.dataList[i];
        model.progress = (CGFloat)uploadedSize / (CGFloat)totalSize;
        NSLog(@"-----------------%f", model.progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.tableView reloadRowsAtIndexPaths:@[[weakself indexPath:i]] withRowAnimation:UITableViewRowAnimationNone];
        });
    };
    listener.retryResume = ^{
        
    };
    self.uploader = [[VODUploader alloc] initWithListener:listener];
}

- (NSInteger)indexOfModelWithFileInfo:(UploadFileInfo *)info {
    NSInteger findIndex = 0;
    for (NSInteger i = 0; i < self.dataList.count; i++) {
        VideoModel *model = self.dataList[i];
        if ([model.title isEqualToString:info.object]) {
            findIndex = i;
            break;
        }
    }
    return findIndex;
}

- (void)deleteTableViewCell:(UploadFileInfo *)info {
    NSInteger i = [self indexOfModelWithFileInfo:info];
    [self za_removeItemAtIndex:i];
    [self.dataList removeObjectAtIndex:i];
    [self.uploader deleteFile:(int)i];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[[self indexPath: i]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    });
    if (self.dataList.count == 0) {
        self.uploadStatus = UploadStatusStart;
        self.uploadBtn.enabled = NO;
    }
}

- (void)za_removeItemAtIndex:(NSInteger)i {
    VideoModel *model = self.dataList[i];
    NSString *path = model.path;
    NSError *error;
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) {
            NSLog(@"ZARecordEncoder: %@", error.localizedDescription);
        }
    }
}

- (void)startUpload {
    for (NSInteger i = 0; i < self.dataList.count; i++) {
        VideoModel *model = self.dataList[i];
        VodInfo *info = [VodInfo new];
        info.priority = @(i);
        [self.uploader addFile:model.path object:model.title vodInfo:info];
    }
    
    [self.uploader start];
}

- (void)uploadBtnAction {
    if (self.dataList.count == 0) {
        return;
    }
    if (_uploadStatus == UploadStatusStart) {
        self.uploadStatus = UploadStatusPause;
        [self startUpload];
    } else if (_uploadStatus == UploadStatusPause) {
        self.uploadStatus = UploadStatusContinue;
        [self.uploader pause];
    } else {
        self.uploadStatus = UploadStatusPause;
        [self.uploader resume];
    }
}

- (void)setUploadStatus:(UploadStatus)uploadStatus {
    _uploadStatus = uploadStatus;
    switch (uploadStatus) {
        case UploadStatusStart:
        {
            [self.uploadBtn setTitle:@"开始" forState:UIControlStateNormal];
        }
            break;
        case UploadStatusPause:
        {
            [self.uploadBtn setTitle:@"暂停" forState:UIControlStateNormal];
        }
            break;
        case UploadStatusContinue:
        {
            [self.uploadBtn setTitle:@"继续上传" forState:UIControlStateNormal];
        }
            break;
    }
}

#pragma mark - delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:VideoTableViewCellIdentifier forIndexPath:indexPath];
    [cell updateCellWithModel:self.dataList[indexPath.row]];
    return cell;
}

#pragma mark - private

- (NSIndexPath *)indexPath:(NSInteger)i {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
    return indexPath;
}

- (VideoTableViewCell *)getCell:(NSInteger)i {
    NSIndexPath *indexPath = [self indexPath:i];
    VideoTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

- (void)configVideoData {
    self.dataList = @[].mutableCopy;
    NSArray <NSString *> *videos = [self videoNames];
    NSString *directory = [self cacheDirectory];
    for (NSString *name in videos) {
        VideoModel *model = [VideoModel new];
        model.path = [directory stringByAppendingPathComponent:name];
        model.title = name;
        model.progress = 0;
        [self.dataList addObject:model];
    }
    self.navigationItem.rightBarButtonItem.enabled = self.dataList.count > 0;
}

- (NSArray <NSString *> *)videoNames {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    NSString *path = [self cacheDirectory];
    [manager fileExistsAtPath:path isDirectory:&isDir];
    if (isDir) {
        NSError *error;
        NSArray *subpaths = [manager contentsOfDirectoryAtPath:path error:&error];
        return subpaths;
    }
    return nil;
}

- (NSString *)cacheDirectory {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"origin_videos"];
    return path;
}

#pragma mark - getter 

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        [_tableView registerClass:[VideoTableViewCell class] forCellReuseIdentifier:VideoTableViewCellIdentifier];
    }
    return _tableView;
}

- (UIView *)uploadBtn {
    if (!_uploadBtn) {
        _uploadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _uploadBtn.frame = CGRectMake(0, 0, 80, 20);
        _uploadBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _uploadBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_uploadBtn setTitle:@"上传" forState:UIControlStateNormal];
        [_uploadBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [_uploadBtn addTarget:self action:@selector(uploadBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _uploadBtn;
}

@end
