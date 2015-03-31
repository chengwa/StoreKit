//
//  ViewController.m
//  StoreKit
//
//  Created by closure on 3/20/15.
//  Copyright (c) 2015 closure. All rights reserved.
//

#import "ViewController.h"
#import "RSStoreKit.h"
#import "RSStorage.h"
#import "RSDao.h"
#import "RSBucket.h"
#import "RSVersionDao.h"
#import "RSObjCClassDumpDao.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [RSObjCClassDumpDao dumpAction:^{
        NSLog(@"dump finished");
    }];
//    [kit removeStorage:storage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
