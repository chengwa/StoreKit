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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    RSStoreKit *kit = [RSStoreKit kit];
    RSStorage *storage = [kit storageNamed:@"1"];
    RSBucket *imageBucket = [storage bucketNamed:@"image"];
    RSDatabaseConnector *connector = [storage connectorNamed:@"accounts"];
    RSVersionDao *dao = [[RSVersionDao alloc] initWithConnector:connector];
    dao = nil;
    RSStorage *payment = [storage storageNamed:@"Payment"];
    [kit removeAllStorages];
//    [kit removeStorage:storage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
