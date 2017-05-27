//
//  TestTableViewController.m
//  SexyScrollViews
//
//  Created by wansong on 16/5/12.
//  Copyright © 2016年 zhike. All rights reserved.
//

#import "TestTableViewController.h"

@interface TestTableViewController ()

@end

@implementation TestTableViewController

- (UIScrollView*)scrollView {
  return self.tableView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.nCells;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
  cell.textLabel.text = [NSString stringWithFormat:@"cell - %ld - %ld", self.nCells, (long)indexPath.row];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
