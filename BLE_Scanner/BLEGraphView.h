//
//  BLEGraphView.h
//  BLE_Scanner
//
//  Created by Chip Keyes on 2/10/13.
//  Copyright (c) 2013 Chip Keyes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLEGraphView : UIView

// data source for graph
@property (nonatomic, strong) NSArray *accelerationData;


@property (nonatomic)NSUInteger maxDataPoints;
@end
