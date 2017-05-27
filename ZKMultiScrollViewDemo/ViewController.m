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
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  UIButton *but = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
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
}

- (void)tapHeader:(id)sender {
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)pushTestViewController:(id)sender {
  ZKMultiScrollViewController *vc = [[ZKMultiScrollViewController alloc] init];
  vc.delegate = self;
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
  vc.nCells = 5 + index * 20;
  return vc;
}

- (UIView*)headerViewForController:(UIViewController *)delegater {
  return self.header;
}

@end
