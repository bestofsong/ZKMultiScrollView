//
//  ZKMultiScrollViewController.h
//  ZKMultiScrollViewDemo
//
//  Created by wansong on 24/05/2017.
//  Copyright © 2017 zhike. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZKMultiScrollViewProtocol.h"

@interface ZKMultiScrollViewController : UIViewController

@property (assign, nonatomic) Class viewClass;

@property (weak, nonatomic) id<ZKMultiScrollViewProtocol> delegate;

@end
