//
//  BLEScanControlTVC.h
//  BLE_Scanner
//
//  Created by Chip Keyes on 1/28/13.
//  Copyright (c) 2013 Chip Keyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEDeviceListTVC.h"


@protocol BLEScanControlDelegate


-(void) scanForServices: (NSArray *)services sender:(id)sender;

@end


@interface BLEScanControlTVC : UITableViewController <BLEServiceListDelegate>


@property (nonatomic, weak)id< BLEScanControlDelegate>delegate;
@end
