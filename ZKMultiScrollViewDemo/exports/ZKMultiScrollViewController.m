//
//  ZKMultiScrollViewController.m
//  ZKMultiScrollViewDemo
//
//  Created by wansong on 24/05/2017.
//  Copyright © 2017 zhike. All rights reserved.
//

#import "ZKMultiScrollViewController.h"

@interface ZKMultiScrollViewController () <UIScrollViewDelegate>
@property (strong, nonatomic) NSMutableArray<UIViewController<ZKScrollableProtocol>*> *scrollables;
@property (weak, nonatomic) UIScrollView *hScroll;
@property (strong, nonatomic) NSMutableArray<NSNumber*> * visibleIndexs;
@end

@implementation ZKMultiScrollViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.scrollables = [NSMutableArray array];
  self.visibleIndexs = [NSMutableArray arrayWithObjects:@0, @(-1), nil];
  self.automaticallyAdjustsScrollViewInsets = NO;
  
  if (self.delegate) {
    [self setupSubviews];
  }
}

- (void)setupSubviews {
  [self loadNextScrollable];
  
  NSInteger nScrollable = [self.delegate numberOfScrollablesForController:self];
  CGRect bounds = [self selfBounds];
  UIScrollView *hScroll = [[UIScrollView alloc] initWithFrame:bounds];
  self.hScroll = hScroll;
  self.hScroll.delegate = self;
  self.hScroll.pagingEnabled = YES;
  self.hScroll.showsHorizontalScrollIndicator = NO;
  self.hScroll.contentSize = CGSizeMake(nScrollable * bounds.size.width, bounds.size.height);
  self.hScroll.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:self.hScroll];
  
  [self.scrollables enumerateObjectsUsingBlock:^(UIViewController<ZKScrollableProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [self installScrollable:obj atIndex:idx];
  }];
  
  //UIView *headerView = [self.delegate headerViewForController:self];
}

- (BOOL)scrollableLoadedAtIndex:(NSInteger)index {
  return self.scrollables.count > index;
}

- (void)loadNextScrollable {
  NSInteger index = self.scrollables.count;
  UIViewController<ZKScrollableProtocol> *scrollable = [self.delegate scrollableAtIndex:index
                                                                          forController:self];
  [self.scrollables addObject:scrollable];
}

- (CGRect)selfBounds {
  return self.view.bounds;
}

- (void)installScrollable:(UIViewController<ZKScrollableProtocol> *)scrollable atIndex:(NSInteger)index {
  CGSize boundSize = self.hScroll.bounds.size;
  [self addChildViewController:scrollable];
  UIView *scrollableRoot = scrollable.view;
  scrollableRoot.frame = CGRectMake(index * boundSize.width, 0, boundSize.width, boundSize.height);
  [self.hScroll addSubview:scrollableRoot];
  // todo: add contentOffset kvo
  [scrollable didMoveToParentViewController:self];
}

#pragma mark -- UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [self checkPageVisibility:scrollView];
}

#pragma mark -- manage page visibility
- (void)checkPageVisibility:(UIScrollView*)hScroll {
  NSArray<NSNumber*> *indexs = [self visiblePageIndexsForHScroll:hScroll];
  NSInteger left = [indexs[0] integerValue];
  NSInteger right = [indexs[1] integerValue]; // right is left + 1 or -1
  
  NSInteger left0 = [self.visibleIndexs[0] integerValue];
  NSInteger right0 = [self.visibleIndexs[1] integerValue];
  
  if (left == left0 && right == right0) {
    return;
  }
  
  if (left == left0) {
    if (right == -1) {
      [self notifyPageVisible:NO atIndex:right0];
    } else {
      [self notifyPageVisible:YES atIndex:right];
    }
  } else {
    if (left < left0) {
      [self notifyPageVisible:YES atIndex:left];
    } else {
      [self notifyPageVisible:NO atIndex:left0];
      if (right != -1) {
        [self notifyPageVisible:YES atIndex:right];
      }
    }
  }
  [self.visibleIndexs replaceObjectAtIndex:0 withObject:@(left)];
  [self.visibleIndexs replaceObjectAtIndex:1 withObject:@(right)];
}

- (NSArray<NSNumber*> *)visiblePageIndexsForHScroll:(UIScrollView*)hScroll {
  NSInteger pixelsPerPoint = [UIScreen mainScreen].scale;
  CGPoint hOffset = hScroll.contentOffset;
  CGFloat hOffsetX = hOffset.x;
  NSInteger hOffsetInPixel = MAX(0, pixelsPerPoint * hOffsetX);
  NSInteger pageWidthInPixel = hScroll.bounds.size.width * pixelsPerPoint;
  
  NSInteger left = hOffsetInPixel / pageWidthInPixel;
  NSInteger right = hOffsetInPixel % pageWidthInPixel ? left + 1 : -1;
  return @[@(left), @(right >= [self.delegate numberOfScrollablesForController:self] ? -1 : right)];
}

- (void)notifyPageVisible:(BOOL)visible atIndex:(NSInteger)index {
  if (visible) {
    if (![self scrollableLoadedAtIndex:index] && index < [self.delegate numberOfScrollablesForController:self]) {
      [self loadNextScrollable];
      [self installScrollable:self.scrollables[index] atIndex:index];
    }
  }
}

@end
