//
//  BLEServicesViewController.h
//  BLE_Scanner
//
//  Created by Chip Keyes on 2/4/13.
//  Copyright (c) 2013 Chip Keyes. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEDiscoveryRecord.h"


@interface BLEPeripheralServicesTVC : UITableViewController

// Model for the view controller
@property (nonatomic, strong)BLEDiscoveryRecord *deviceRecord ;
@end
