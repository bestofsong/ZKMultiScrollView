//
//  ViewController.m
//  ZKMultiScrollViewDemo
//
//  Created by wansong on 24/05/2017.
//  Copyright © 2017 zhike. All rights reserved.
//

#import "ViewController.h"
#import "ZKMultiScrollViewController.h"
#import "TestTableViewController.h"
@interface ViewController () <ZKMultiScrollViewProtocol>
@property (strong, nonatomic) UIView *header;
@property (strong, nonatomic) UIView *header1;
@property (weak, nonatomic) UIViewController *vc;
@property (weak, nonatomic) UIViewController *vc1;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor grayColor];
  UIButton *but = [[UIButton alloc] initWithFrame:CGRectMake(60, 60, 40, 40)];
  [self.view addSubview:but];
  [but addTarget:self action:@selector(pushTestViewController:) forControlEvents:UIControlEventTouchUpInside];
  [but setTitle:@"push" forState:UIControlStateNormal];
  [but setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [self.navigationController setNavigationBarHidden:YES];
  
  CGRect headFrame = self.view.bounds;
  headFrame.size.height = 240;
  self.header = [[UIView alloc] initWithFrame:headFrame];
  self.header.backgroundColor = [UIColor greenColor];
  UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHeader:)];
  [self.header addGestureRecognizer:gesture];
  
  self.header1 = [[UIView alloc] initWithFrame:headFrame];
  self.header1.backgroundColor = [UIColor redColor];
  
  ZKMultiScrollViewController *vc = [[ZKMultiScrollViewController alloc] init];
  vc.viewClass = [UIView class];
  vc.delegate = self;
  self.vc1 = vc;
  [self addChildViewController:vc];
  CGRect testFrame = CGRectMake(100, 100, 250, 500);
  vc.view.frame = testFrame;
  vc.view.backgroundColor = [UIColor redColor];
  [self.view addSubview:vc.view];
  [vc didMoveToParentViewController:self];
}

- (void)tapHeader:(id)sender {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)pushTestViewController:(id)sender {
  ZKMultiScrollViewController *vc = [[ZKMultiScrollViewController alloc] init];
  vc.delegate = self;
  self.vc = vc;
  [self.navigationController pushViewController:vc animated:YES];
}


- (NSInteger)numberOfScrollablesForController:(UIViewController *)delegater {
  return 10;
}

- (NSString*)tabNameForScrollableAtIndex:(NSInteger)index forController:(UIViewController *)delegater {
  return [NSString stringWithFormat:@"tab:%ld", index];
}

- (UIViewController<ZKScrollableProtocol> *)scrollableAtIndex:(NSInteger)index forController:(UIViewController *)delegater {
  TestTableViewController *vc = [[TestTableViewController alloc] init];
  vc.nCells = 50 + index * 20;
  return vc;
}

- (UIView*)headerViewForController:(UIViewController *)delegater {
  if (delegater == self.vc) {
    return self.header;
  } else {
    return self.header1;
  }
}

@end
