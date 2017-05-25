//
//  UIScrollView+Boundry.m
//  ZKMultiScrollViewDemo
//
//  Created by wansong on 25/05/2017.
//  Copyright © 2017 zhike. All rights reserved.
//

#import "UIScrollView+Boundry.h"

@implementation UIScrollView (Boundry)

- (CGFloat)maxOffsetY {
  CGSize content = self.contentSize;
  UIEdgeInsets insets = self.contentInset;
  CGRect bounds = self.bounds;
  
  CGFloat ret = content.height + insets.bottom - bounds.size.height;
  if (ret > 0) {
    return ret;
  } else {
    return MAX(ret, -insets.top);
  }
}

@end
