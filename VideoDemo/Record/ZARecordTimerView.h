//
//  ZARecordTimerView.h
//  VideoDemo
//
//  Created by xudongdong on 2017/4/11.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZARecordTimerView : UIView

- (void)startWithTimeInterval:(NSTimeInterval)timeInterval completion:(void (^)())completion;
- (void)stop;

@end
