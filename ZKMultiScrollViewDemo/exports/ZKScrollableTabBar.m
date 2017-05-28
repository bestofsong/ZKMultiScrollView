//
//  ZKScrollableTabBar.m
//  ZKMultiScrollViewDemo
//
//  Created by wansong on 27/05/2017.
//  Copyright © 2017 zhike. All rights reserved.
//

#import "ZKScrollableTabBar.h"

@interface ZKScrollableTabBar ()

@property (strong, nonatomic) NSArray<UIButton*> *itemViews;

@property (weak, nonatomic) UIScrollView *scrollView;

@end

@implementation ZKScrollableTabBar
@synthesize selected = _selected;
@synthesize onChangeSelect = _onChangeSelect;

- (instancetype)initWithItemNames:(NSArray<NSString *> *)names width:(CGFloat)width  {
  CGRect __block bounds = CGRectMake(0, 0, width, 0);
  NSMutableArray *itemViews = [NSMutableArray array];
  [names enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    UIButton *aButton = [[UIButton alloc] init];
    [aButton setTitle:obj forState:UIControlStateNormal];
    [aButton setTitleColor:[UIColor greenColor] forState:UIControlStateSelected];
    [aButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [aButton sizeToFit];
    [itemViews addObject:aButton];
    bounds.size.height = MAX(bounds.size.height, aButton.bounds.size.height);
    aButton.tag = idx;
  }];
  
  self = [super initWithFrame:bounds];
  if (self) {
    self.itemViews = itemViews;
    _selected = -1;
    [self setup];
  }
  return self;
}

- (void)setup {
  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
  self.scrollView = scrollView;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.showsVerticalScrollIndicator = NO;
  
  [self.itemViews enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    CGRect btFrame = obj.bounds;
    if (idx > 0) {
      UIView *prev = self.itemViews[idx - 1];
      btFrame.origin.x = CGRectGetMaxX(prev.frame);
    }
    obj.frame = btFrame;
    [self.scrollView addSubview:obj];
    [obj addTarget:self action:@selector(onButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
  }];
  self.scrollView.contentSize =  CGSizeMake(
                                            CGRectGetMaxX(self.itemViews.lastObject.frame) - CGRectGetMinX(self.itemViews.firstObject.frame),
                                            CGRectGetHeight(self.bounds));
  [self addSubview:self.scrollView];
  self.selected = 0;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGRect scrollFrame = self.scrollView.frame;
  scrollFrame.size.width = CGRectGetWidth(self.bounds);
  self.scrollView.frame = scrollFrame;
}

- (void)setSelected:(NSInteger)selected {
  if (_selected == selected) {
    return;
  }
  
  NSInteger prev = _selected;
  _selected = selected;
  if (prev != -1) {
    self.itemViews[prev].selected = NO;
  }
  self.itemViews[selected].selected = YES;
  [self.scrollView scrollRectToVisible:self.itemViews[selected].frame animated:YES];
}

- (void)onButtonTapped:(UIButton*)sender {
  if (sender.tag == self.selected) {
    return;
  }
  self.selected = sender.tag;
  if (self.onChangeSelect) {
    self.onChangeSelect(sender.tag);
  }
}

@end
