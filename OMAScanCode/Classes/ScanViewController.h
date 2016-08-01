//
//  ScanViewController.h
//  ScanCode
//
//  Created by Oma-002 on 16/7/7.
//  Copyright © 2016年 com.tjl.org. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScanViewController : UIViewController

typedef void(^ScanQRCodeResult)(NSString *serialNumber);

- (instancetype)initWithComplete:(ScanQRCodeResult) complete;

@end
