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
#import "ZKScrollableTabBar.h"

static void *COVER_SCROLL_KVO_CTX = &COVER_SCROLL_KVO_CTX;
static void *PAGE_SCROLL_KVO_CTX = &PAGE_SCROLL_KVO_CTX;

static void *STICKY_SCROLL_KVO_CTX = &STICKY_SCROLL_KVO_CTX;

@interface ZKStickSubviewScrollView : ZKTouchThroughScrollView
@property (strong, nonatomic) NSArray<UIView*> *stickSubviews;
@property (strong, nonatomic) NSArray<NSValue*> *stickPositions;

- (void)adjustAllSubviews;
@end

@implementation ZKStickSubviewScrollView

- (void)dealloc {
  if (_stickSubviews.count) {
    [self removeObserver:self forKeyPath:@"contentOffset"];
  }
}

- (void)setStickSubviews:(NSArray<UIView *> *)stickSubviews {
  if (!_stickSubviews.count && stickSubviews.count) {
    [self addObserver:self
           forKeyPath:@"contentOffset"
              options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
              context:STICKY_SCROLL_KVO_CTX];
  } else if (_stickSubviews.count && !stickSubviews.count) {
    [self removeObserver:self forKeyPath:@"contentOffset"];
  }
  _stickSubviews = stickSubviews;
  NSMutableArray *positions = [NSMutableArray array];
  [stickSubviews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [positions addObject:[NSValue valueWithCGRect:obj.frame]];
  }];
  self.stickPositions = positions;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if ([keyPath isEqualToString:@"contentOffset"] && context == STICKY_SCROLL_KVO_CTX) {
    [self.stickSubviews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      [self adjustSubviewAtindex:idx];
    }];
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)adjustSubviewAtindex:(NSInteger)idx {
  UIView *subview = self.stickSubviews[idx];
  CGRect frame = subview.frame;
  CGPoint upRim = [self.superview convertPoint:self.frame.origin toView:nil];
  CGRect absFrame = [self convertRect:frame toView:nil];
  CGFloat reachOut = upRim.y - absFrame.origin.y;
  if (reachOut > 0) {
    frame.origin.y += upRim.y - absFrame.origin.y;
    subview.frame = frame;
  } else {
    CGRect originalPos = [self.stickPositions[idx] CGRectValue];
    frame.origin.y -= MIN(-reachOut, MAX(0, frame.origin.y - originalPos.origin.y));
    subview.frame = frame;
  }
}

- (void)adjustAllSubviews {
  [self.stickSubviews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    [self adjustSubviewAtindex:idx];
  }];
}

@end


@interface ZKMultiScrollViewController () <UIScrollViewDelegate>
@property (strong, nonatomic) NSMutableArray<UIViewController<ZKScrollableProtocol>*> *scrollables;
@property (weak, nonatomic) UIScrollView *hScroll;

@property (strong, nonatomic) NSMutableArray<NSNumber*> * visibleIndexs;
@property (assign, nonatomic) NSInteger currentIndex;

@property (weak, nonatomic) ZKStickSubviewScrollView *coverScrollView;

@property (readonly, nonatomic) UIView *headerView;
@property (readonly, nonatomic) CGFloat verticalScrollInset;
@property (strong, nonatomic) UIView<ZKScrollableTabBarProtocol> *tabBar;

@property (assign, nonatomic) BOOL rightPageTrigger;
@property (assign, nonatomic) BOOL leftPageTrigger;
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

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  
  CGRect bounds = [self selfBounds];
  self.hScroll.frame = bounds;
  self.coverScrollView.frame = bounds;
  CGSize contentSize = self.coverScrollView.contentSize;
  contentSize.width = CGRectGetWidth(bounds);
  self.coverScrollView.contentSize = contentSize;
  
  CGRect headerViewFrame = self.headerView.frame;
  headerViewFrame.size.width = bounds.size.width;
  headerViewFrame.origin = CGPointZero;
  self.headerView.frame = headerViewFrame;

  [self.coverScrollView adjustAllSubviews];
  CGSize contentSize1 = self.hScroll.contentSize;
  contentSize1 = self.hScroll.contentSize;
  contentSize1.height = CGRectGetHeight(bounds);
  contentSize1.width = [self.delegate numberOfScrollablesForController:self] * CGRectGetWidth(bounds);
  self.hScroll.contentSize = contentSize1;
  
  [self.scrollables enumerateObjectsUsingBlock:^(UIViewController<ZKScrollableProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    UIView *page = [obj scrollView];
    page.frame = CGRectMake(idx * CGRectGetWidth(bounds), 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds));
    CGSize csize = [obj scrollView].contentSize;
    csize.width = CGRectGetWidth(bounds);
    [obj scrollView].contentSize = csize;
  }];
  
  CGRect frame = self.tabBar.frame;
  frame.size.width = CGRectGetWidth(bounds);
  self.tabBar.frame = frame;
}

- (UIView*)headerView {
  return [self.delegate headerViewForController:self];
}

- (CGFloat)verticalScrollInset {
  UIView *header = self.headerView;
  UIView *tabBar = self.tabBar;
  return CGRectGetHeight(header.bounds) + CGRectGetHeight(tabBar.bounds);
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
  self.hScroll.directionalLockEnabled = YES;
  self.hScroll.showsHorizontalScrollIndicator = NO;
  self.hScroll.contentSize = CGSizeMake(nScrollable * bounds.size.width, bounds.size.height);
  self.hScroll.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:self.hScroll];
  
  [self installCoverScrollView];
  [self loadNextScrollable];
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
  scrollableScroll.contentInset = UIEdgeInsetsMake(self.verticalScrollInset,
                                                   0,
                                                   0,
                                                   0);
  scrollableScroll.contentOffset = CGPointMake(0, -self.verticalScrollInset);
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
  
  ZKStickSubviewScrollView *coverScrollView = [[ZKStickSubviewScrollView alloc] initWithFrame:bounds];
  self.coverScrollView = coverScrollView;
  self.coverScrollView.showsVerticalScrollIndicator = NO;
  [self.view addSubview:self.coverScrollView];
  self.coverScrollView.delegate = self;
  if (headerView) {
    [self.coverScrollView addSubview:headerView];
  }
  [self.coverScrollView addObserver:self
                         forKeyPath:@"contentOffset"
                            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial
                            context:COVER_SCROLL_KVO_CTX];
  
  NSMutableArray *names = [NSMutableArray array];
  for (NSInteger i = 0; i < [self.delegate numberOfScrollablesForController:self]; i++) {
    [names addObject:[self.delegate tabNameForScrollableAtIndex:i forController:self] ?: @"no name"];
  }
  ZKScrollableTabBar *tabBar = names.count ? [[ZKScrollableTabBar alloc] initWithItemNames:names width:CGRectGetWidth(bounds)] : nil;
  self.tabBar = tabBar;
  CGRect frame = tabBar.frame;
  frame.origin.y = CGRectGetMaxY(headerView.frame);
  self.tabBar.frame = frame;
  if (tabBar) {
    [self.coverScrollView addSubview:self.tabBar];
  }
  typeof(self) weakSelf = self;
  tabBar.onChangeSelect = ^(NSInteger selected) {
    [weakSelf notifyPageVisible:YES atIndex:selected];
    CGPoint offset = weakSelf.hScroll.contentOffset;
    offset.x = selected * weakSelf.view.bounds.size.width;
    [weakSelf.hScroll setContentOffset:offset animated:YES];
  };
  
  CGSize contentSize = bounds.size;
  contentSize.height += self.verticalScrollInset + 2000;
  self.coverScrollView.contentSize = contentSize;
  
  coverScrollView.stickSubviews = @[self.tabBar];
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
    
    UIScrollView *currentScroll = [self currentScrollView];
    if (!currentScroll) return;
    _syncingOffset = YES;
    if (context == PAGE_SCROLL_KVO_CTX) {
      if (currentScroll == object) {
        [self syncScrollView:currentScroll toScrollView:self.coverScrollView off:self.verticalScrollInset];
      }
    } else if (context == COVER_SCROLL_KVO_CTX) {
      if (self.coverScrollView != object) {
        NSAssert(NO, @"不科学");
      }
      currentScroll.contentOffset = self.coverScrollView.contentOffset;
      [self syncScrollView:self.coverScrollView toScrollView:currentScroll off:-self.verticalScrollInset];
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
    self.tabBar.selected = self.currentIndex;
    for (NSInteger ii = self.scrollables.count; ii <= self.currentIndex; ii++) {
      [self notifyPageVisible:YES atIndex:ii];
    }
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
    CGFloat correctOffsetY = [currentPage maxOffsetY] + self.verticalScrollInset;
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
    for (NSInteger ii = self.scrollables.count; ii <= self.currentIndex || ii <= index; ii++) {
      [self loadNextScrollable];
    }
    [self pickVerticalScrollForScrollAtIndex:index];
  }
}

- (void)pickVerticalScrollForScrollAtIndex:(NSInteger)index {
  UIScrollView *nextScroll = [self.scrollables[index] scrollView];
  
  CGPoint targetOffset = self.coverScrollView.contentOffset;
  targetOffset.y -= self.verticalScrollInset;
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
    coverOffset.y += self.verticalScrollInset;
    [self.coverScrollView setContentOffset:coverOffset animated:YES];
  }
}

// only works when horizontal scroll just begins
- (UIScrollView *)currentScrollView {
  if ([self.delegate numberOfScrollablesForController:self]) {
    if (self.scrollables.count <= self.currentIndex) {
      return nil;
    }
    return [self.scrollables[self.currentIndex] scrollView];
  } else {
    return nil;
  }
}

@end
