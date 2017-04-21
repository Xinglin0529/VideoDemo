//
//  ZAMeProgressView.h
//  ZADigital
//
//  Created by xudongdong on 2017/4/14.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZAMeProgressView : UIView

@property (nonatomic, strong) UIColor *indicatorColor;

- (void)updateProgress:(CGFloat)progress animated:(BOOL)animated;

@end
