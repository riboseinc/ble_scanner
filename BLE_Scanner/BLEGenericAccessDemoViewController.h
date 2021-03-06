//
//  BLEGenericAccessDemoViewController.h
//  BLE_Scanner
//
//  Created by Chip Keyes on 2/15/13.
//  Copyright (c) 2013 Chip Keyes. All rights reserved.
//

#import "BLEDemoViewController.h"
#import "BLEDemoViewController.h"


// Demo class which uses the Generic Access Service 0x1800
@interface BLEGenericAccessDemoViewController : BLEDemoViewController

// the GAP service which is the model for the controller
@property (nonatomic, strong) CBService *genericAccessProfileService;
@end
