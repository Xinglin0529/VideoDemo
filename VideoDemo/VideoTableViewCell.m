//
//  VideoTableViewCell.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/20.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "VideoTableViewCell.h"
#import <Masonry/Masonry.h>
#import "ZAMeProgressView.h"
#import <AVFoundation/AVFoundation.h>

#define ScreenWidth [UIScreen mainScreen].bounds.size.width

@interface VideoTableViewCell ()

@property (nonatomic, strong) UIImageView *thumbImage;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) ZAMeProgressView *progressView;

@end

@implementation VideoTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _thumbImage = [[UIImageView alloc] init];
        [self.contentView addSubview:_thumbImage];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.textColor = [UIColor blackColor];
        [self.contentView addSubview:_titleLabel];
        
        _progressView = [[ZAMeProgressView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth - 20, 10)];
        _progressView.indicatorColor = [UIColor redColor];
        [self.contentView addSubview:_progressView];
        
        [_thumbImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView);
            make.leading.equalTo(self.contentView).offset(10);
            make.size.mas_equalTo(CGSizeMake(30, 30));
        }];
        
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_thumbImage.mas_trailing).offset(5);
            make.centerY.equalTo(self.contentView);
            make.trailing.equalTo(self.contentView).offset(-10);
        }];
        
        [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView).offset(10);
            make.trailing.equalTo(self.contentView).offset(-10);
            make.top.equalTo(_thumbImage.mas_bottom).offset(5);
            make.height.mas_equalTo(@(10));
        }];
     }
    return self;
}


#pragma mark - public

- (void)updateCellWithModel:(VideoModel *)model {
    _titleLabel.text = model.title;
    [_progressView updateProgress:model.progress animated:NO];
    if (!_thumbImage.image) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [self get_videoThumbImage:[NSURL fileURLWithPath:model.path]];
            dispatch_async(dispatch_get_main_queue(), ^{
                _thumbImage.image = image;
            });
        });
    }
}

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

@end

@implementation VideoModel

@end
