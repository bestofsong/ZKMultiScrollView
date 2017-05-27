//
//  ZKScrollableTabBar.h
//  ZKMultiScrollViewDemo
//
//  Created by wansong on 27/05/2017.
//  Copyright © 2017 zhike. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZKMultiScrollViewProtocol.h"

@interface ZKScrollableTabBar : UIView <ZKScrollableTabBarProtocol>

- (instancetype)initWithItemNames:(NSArray<NSString*> *)names width:(CGFloat)width;

@end
