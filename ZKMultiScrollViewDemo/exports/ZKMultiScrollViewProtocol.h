//
//  ZKMultiScrollViewProtocol.h
//  ZKMultiScrollViewDemo
//
//  Created by wansong on 24/05/2017.
//  Copyright © 2017 zhike. All rights reserved.
//

#ifndef ZKMultiScrollViewProtocol_h
#define ZKMultiScrollViewProtocol_h

#import <Foundation/Foundation.h>


@protocol ZKScrollableProtocol <NSObject>

- (UIScrollView*)scrollView;

@end

@protocol ZKScrollableTabBarProtocol <NSObject>

@property (assign, nonatomic) NSInteger selected;

@property (copy, nonatomic) void (^onChangeSelect)(NSInteger selected);

@end


@protocol ZKMultiScrollViewProtocol <NSObject>

// rendering
@required

- (NSInteger)numberOfScrollablesForController:(UIViewController*)delegater;

- (UIViewController<ZKScrollableProtocol>*)scrollableAtIndex:(NSInteger)index
                                               forController:(UIViewController*)delegater;

- (NSString*)tabNameForScrollableAtIndex:(NSInteger)index
                           forController:(UIViewController*)delegater;

@optional
// already rendered header view
- (UIView*)headerViewForController:(UIViewController*)delegater;

@end



#endif /* ZKMultiScrollViewProtocol_h */
