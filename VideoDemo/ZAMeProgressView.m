//
//  ZAMeProgressView.m
//  ZADigital
//
//  Created by xudongdong on 2017/4/14.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "ZAMeProgressView.h"
#import <Masonry/Masonry.h>

@interface ZAMeProgressView ()

@property (nonatomic, strong) UIView *progressView;

@end

@implementation ZAMeProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        self.layer.borderColor = [UIColor grayColor].CGColor;
        self.layer.cornerRadius = frame.size.height / 2;
        self.clipsToBounds = YES;
        _progressView = [[UIView alloc] init];
        _progressView.frame = CGRectMake(0, 0, 0, frame.size.height);
        [self addSubview:_progressView];
    }
    return self;
}

#pragma mark - public

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    _indicatorColor = indicatorColor;
    _progressView.backgroundColor = indicatorColor;
}

- (void)updateProgress:(CGFloat)progress animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:1.0f animations:^{
            CGFloat width = progress * self.bounds.size.width;
            _progressView.frame = CGRectMake(0, 0, width, self.bounds.size.height);
        }];
    } else {
        CGFloat width = progress * self.bounds.size.width;
        _progressView.frame = CGRectMake(0, 0, width, self.bounds.size.height);
    }
}

@end
