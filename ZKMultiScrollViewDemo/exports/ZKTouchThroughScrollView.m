//
//  ZKTouchThroughScrollView.m
//  ZKMultiScrollViewDemo
//
//  Created by wansong on 25/05/2017.
//  Copyright © 2017 zhike. All rights reserved.
//

#import "ZKTouchThroughScrollView.h"

@implementation ZKTouchThroughScrollView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *ret = [super hitTest:point withEvent:event];
  if (ret == self) {
    return nil;
  }
  return ret;
}

@end
