//
//  ScanView.h
//  ScanCode
//
//  Created by Oma-002 on 16/7/7.
//  Copyright © 2016年 com.tjl.org. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScanView : UIView

/**
 *  扫描条
 */
@property (nonatomic, strong) UIImageView *sweepLineView;

- (void)sweepAnimation;

@end
