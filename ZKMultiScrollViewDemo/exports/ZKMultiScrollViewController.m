//
//  ZKMultiScrollViewController.m
//  ZKMultiScrollViewDemo
//
//  Created by wansong on 24/05/2017.
//  Copyright © 2017 zhike. All rights reserved.
//

#import "ZKMultiScrollViewController.h"
#import "ZKTouchThroughScrollView.h"
#import "UIScrollView+Boundry.h"

static void *COVER_SCROLL_KVO_CTX = &COVER_SCROLL_KVO_CTX;
static void *PAGE_SCROLL_KVO_CTX = &PAGE_SCROLL_KVO_CTX;

@interface ZKMultiScrollViewController () <UIScrollViewDelegate>
@property (strong, nonatomic) NSMutableArray<UIViewController<ZKScrollableProtocol>*> *scrollables;
@property (weak, nonatomic) UIScrollView *hScroll;

@property (strong, nonatomic) NSMutableArray<NSNumber*> * visibleIndexs;
@property (assign, nonatomic) NSInteger currentIndex;

@property (weak, nonatomic) ZKTouchThroughScrollView *coverScrollView;

@property (readonly, nonatomic) UIView *headerView;
@end

@implementation ZKMultiScrollViewController {
  BOOL _syncingOffset;
  // 用于控制一次drag/scroll在一个方向上最多只有一次页码的变化，可以避免回弹问题
  BOOL _leftPageTrigger;
  BOOL _rightPageTrigger;
}

- (void)dealloc {
  [self uninstallCoverScrollView];
  [self.scrollables enumerateObjectsUsingBlock:^(UIViewController<ZKScrollableProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [self uninstallScrollable:obj];
  }];
}

- (UIView*)headerView {
  return [self.delegate headerViewForController:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.scrollables = [NSMutableArray array];
  self.visibleIndexs = [NSMutableArray arrayWithObjects:@0, @(-1), nil];
  self.automaticallyAdjustsScrollViewInsets = NO;
  self.currentIndex = 0;
  
  if (self.delegate) {
    [self setupSubviews];
  }
}

- (void)setupSubviews {
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
  
  [self loadNextScrollable];
  [self installCoverScrollView];
}

- (BOOL)scrollableLoadedAtIndex:(NSInteger)index {
  return self.scrollables.count > index;
}

- (void)loadNextScrollable {
  NSInteger index = self.scrollables.count;
  UIViewController<ZKScrollableProtocol> *scrollable = [self.delegate scrollableAtIndex:index
                                                                          forController:self];
  [self.scrollables addObject:scrollable];
  [self installScrollable:scrollable atIndex:index];
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
  UIScrollView *scrollableScroll = [scrollable scrollView];
  scrollableScroll.contentInset = UIEdgeInsetsMake(self.headerView.bounds.size.height,
                                                   0,
                                                   0,
                                                   0);
  [scrollableScroll addObserver:self
                     forKeyPath:@"contentOffset"
                        options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                        context:PAGE_SCROLL_KVO_CTX];
  [scrollable didMoveToParentViewController:self];
}

- (void)uninstallScrollable:(UIViewController<ZKScrollableProtocol> *)scrollale {
  [[scrollale scrollView] removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)installCoverScrollView {
  CGRect bounds = [self selfBounds];
  UIView *headerView = self.headerView;
  if (headerView) {
    ZKTouchThroughScrollView *coverScrollView = [[ZKTouchThroughScrollView alloc] initWithFrame:bounds];
    self.coverScrollView = coverScrollView;
    self.coverScrollView.showsVerticalScrollIndicator = NO;
    CGSize contentSize = bounds.size;
    contentSize.height += headerView.bounds.size.height;
    self.coverScrollView.contentSize = contentSize;
    [self.view addSubview:self.coverScrollView];
    self.coverScrollView.delegate = self;
    [self.coverScrollView addSubview:headerView];
    [self.coverScrollView addObserver:self
                           forKeyPath:@"contentOffset"
                              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial
                              context:COVER_SCROLL_KVO_CTX];
  }
}

- (void)uninstallCoverScrollView {
  if (self.coverScrollView) {
    [self.coverScrollView removeObserver:self forKeyPath:@"contentOffset"];
  }
}

#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
  if ([keyPath isEqualToString:@"contentOffset"] &&
      (context == COVER_SCROLL_KVO_CTX || context == PAGE_SCROLL_KVO_CTX)) {
    if (_syncingOffset) return;
    
    _syncingOffset = YES;
    UIScrollView *currentScroll = [self currentScrollView];
    if (context == PAGE_SCROLL_KVO_CTX) {
      if (currentScroll == object) {
        [self syncScrollView:currentScroll toScrollView:self.coverScrollView off:self.headerView.bounds.size.height];
      }
    } else {
      if (self.coverScrollView != object) {
        NSAssert(NO, @"不科学");
      }
      currentScroll.contentOffset = self.coverScrollView.contentOffset;
      [self syncScrollView:self.coverScrollView toScrollView:currentScroll off:-self.headerView.bounds.size.height];
    }
    _syncingOffset = NO;
    
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)syncScrollView:(UIScrollView*)sourceScroll toScrollView:(UIScrollView*)destScroll off:(CGFloat)off {
  CGPoint offset = sourceScroll.contentOffset;
  offset.y += off;
  destScroll.contentOffset = offset;
}

#pragma mark -- UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollView == self.hScroll) {
    [self checkPageVisibility:scrollView];
  }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  if (self.hScroll == scrollView) {
    [self checkPageVisibility:scrollView];
    self.currentIndex = [self.visibleIndexs[0] integerValue];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  if (self.hScroll == scrollView) {
    [self checkPageVisibility:scrollView];
    self.currentIndex = [self.visibleIndexs[0] integerValue];
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  if (scrollView == self.hScroll) {
    _leftPageTrigger = YES;
    _rightPageTrigger = YES;
  }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
  if (scrollView == self.coverScrollView) {
    UIScrollView *currentPage = [self currentScrollView];
    CGFloat correctOffsetY = [currentPage maxOffsetY] + self.headerView.bounds.size.height;
    if (targetContentOffset ->y > correctOffsetY) {
      *targetContentOffset = scrollView.contentOffset;
      CGPoint offset = *targetContentOffset;
      offset.y = correctOffsetY;
      [scrollView setContentOffset:offset animated:YES];
    }
  }
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
      if (_rightPageTrigger) {
        [self notifyPageVisible:YES atIndex:right];
        _rightPageTrigger = NO;
      }
    }
  } else {
    if (left < left0) {
      if (_leftPageTrigger) {
        [self notifyPageVisible:YES atIndex:left];
        _leftPageTrigger = NO;
      }
    } else {
      [self notifyPageVisible:NO atIndex:left0];
      if (right != -1) {
        if (_rightPageTrigger) {
          [self notifyPageVisible:YES atIndex:right];
          _rightPageTrigger = NO;
        }
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
  NSInteger right = -1;
  if (hOffsetInPixel % pageWidthInPixel) {
    right = left + 1;
  } else {
    right = -1;
  }
  return @[@(left), @(right >= [self.delegate numberOfScrollablesForController:self] ? -1 : right)];
}

- (void)notifyPageVisible:(BOOL)visible atIndex:(NSInteger)index {
  if (visible) {
    if (![self scrollableLoadedAtIndex:index] && index < [self.delegate numberOfScrollablesForController:self]) {
      [self loadNextScrollable];
      [self installScrollable:self.scrollables[index] atIndex:index];
    }
    [self pickVerticalScrollForScrollAtIndex:index];
  }
}

- (void)pickVerticalScrollForScrollAtIndex:(NSInteger)index {
  UIScrollView *nextScroll = [self.scrollables[index] scrollView];
  NSInteger theOther = index == [self.visibleIndexs[0] integerValue] ? [self.visibleIndexs[1] integerValue] : [self.visibleIndexs[0] integerValue];
  
  UIScrollView *nowScroll = [self.scrollables[theOther] scrollView];
  CGPoint targetOffset = nowScroll.contentOffset;
  CGPoint nowOffset = nextScroll.contentOffset;
  
  CGFloat destOffsetY = MIN(targetOffset.y, 0);
  CGFloat nextScrollYMax = [nextScroll maxOffsetY];
  
  
  if (destOffsetY >= 0 && nowOffset.y >= destOffsetY) {
    return;
  }
  
  BOOL shouldForceSyncCoverScroll = NO;
  if (destOffsetY >= 0) {
    targetOffset.y = MIN(nextScrollYMax, 0);
    shouldForceSyncCoverScroll = nextScrollYMax < 0;
  } else {
    targetOffset.y = MIN(nextScrollYMax, destOffsetY);
    shouldForceSyncCoverScroll = nextScrollYMax < destOffsetY;
  }
  [nextScroll setContentOffset:targetOffset];
  if (shouldForceSyncCoverScroll) {
    CGPoint coverOffset = targetOffset;
    coverOffset.y += self.headerView.bounds.size.height;
    [self.coverScrollView setContentOffset:coverOffset animated:YES];
  }
  
}

// only works when horizontal scroll just begins
- (UIScrollView *)currentScrollView {
  if ([self.delegate numberOfScrollablesForController:self]) {
    return [self.scrollables[self.currentIndex] scrollView];
  } else {
    return nil;
  }
}

@end
