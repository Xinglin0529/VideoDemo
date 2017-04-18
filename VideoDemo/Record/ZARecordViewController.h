//
//  ZARecordViewController.h
//  VideoDemo
//
//  Created by xudongdong on 2017/4/11.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZARecordViewController;

@protocol ZARecordViewControllerDelegate <NSObject>

- (void)recordViewController:(ZARecordViewController *)record videoPath:(NSString *)videoPath;

@end

@interface ZARecordViewController : UIViewController

@property (nonatomic, assign) NSTimeInterval videoMaximumDuration;
@property (nonatomic, weak) id <ZARecordViewControllerDelegate> delegate;

@end
