//
//  VideoTableViewCell.h
//  VideoDemo
//
//  Created by xudongdong on 2017/4/20.
//  Copyright © 2017年 xudongdong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoModel : NSObject
@property (nonatomic, strong) UIImage *thumbImage;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *title;

@end

@interface VideoTableViewCell : UITableViewCell

- (void)updateCellWithModel:(VideoModel *)model;

@end
