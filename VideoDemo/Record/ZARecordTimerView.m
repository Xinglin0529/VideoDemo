//
//  ZARecordTimerView.m
//  VideoDemo
//
//  Created by xudongdong on 2017/4/11.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import "ZARecordTimerView.h"
#import <Masonry/Masonry.h>

@interface ZARecordTimerView()

@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger timeInterval;
@property (nonatomic, copy) void (^block)();

@end

@implementation ZARecordTimerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.timeLabel];
        [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

#pragma mark - public

- (void)startWithTimeInterval:(NSTimeInterval)timeInterval completion:(void (^)())completion {
    self.timeInterval = (NSInteger)timeInterval;
    self.block = completion;
    [self za_addTimer];
}

- (void)stop {
    [self za_clearTimer];
}

#pragma mark - action

- (void)updateLabelText {
    NSInteger temp = self.timeInterval % 60;
    if (temp == 0) {
        self.timeLabel.text = [NSString stringWithFormat:@"%ld:00", self.timeInterval / 60];
    } else {
        if (self.timeInterval % 60 >= 10) {
            self.timeLabel.text = [NSString stringWithFormat:@"%ld:%ld", self.timeInterval / 60, self.timeInterval % 60];
        } else {
            self.timeLabel.text = [NSString stringWithFormat:@"%ld:0%ld", self.timeInterval / 60, self.timeInterval % 60];
        }
    }
    if (self.timeInterval == 0) {
        if (self.block) {
            self.block();
        }
        [self za_clearTimer];
    }
    self.timeInterval--;
}

#pragma mark - private

- (void)za_addTimer {
    [self za_clearTimer];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateLabelText) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    [_timer setFireDate:[NSDate date]];
}

- (void)za_clearTimer {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark - getter & setter

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [UILabel new];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.font = [UIFont systemFontOfSize:15];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.text = @"";
    }
    return _timeLabel;
}

@end
