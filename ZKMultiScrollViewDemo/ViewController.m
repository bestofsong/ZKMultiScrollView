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
}

- (void)pushTestViewController:(id)sender {
  ZKMultiScrollViewController *vc = [[ZKMultiScrollViewController alloc] init];
  vc.delegate = self;
  [self.navigationController pushViewController:vc animated:YES];
}


- (NSInteger)numberOfScrollablesForController:(UIViewController *)delegater {
  return 3;
}

- (NSString*)tabNameForScrollableAtIndex:(NSInteger)index forController:(UIViewController *)delegater {
  return [NSString stringWithFormat:@"tab:%ld", index];
}

- (UIViewController<ZKScrollableProtocol> *)scrollableAtIndex:(NSInteger)index forController:(UIViewController *)delegater {
  TestTableViewController *vc = [[TestTableViewController alloc] init];
  vc.nCells = (1 + index) * 10;
  return vc;
}

@end
