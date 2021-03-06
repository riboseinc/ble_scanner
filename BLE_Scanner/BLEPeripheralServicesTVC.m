//
//  BLEServicesViewController.m
//  BLE_Scanner
//
//  Created by Chip Keyes on 2/4/13.
//  Copyright (c) 2013 Chip Keyes. All rights reserved.
//

#import "BLEPeripheralServicesTVC.h"
#import "BLEPeripheralCharacteristicsTVC.h"
#import "CBUUID+StringExtraction.h"
#import "BLEDemoDispatcherTableViewController.h"
#include "ServiceAndCharacteristicMacros.h"

@interface BLEPeripheralServicesTVC ()

@end

@implementation BLEPeripheralServicesTVC


// class variable which is a set of known services for which a demo exists
static NSSet *_demoServices;

// static initializer
+(void)initialize
{
    _demoServices = [NSSet setWithObjects:
                     GENERIC_ACCESS_PROFILE,
                     IMMEDIATE_ALERT_SERVICE,
                     Tx_POWER_SERVICE,
                     DEVICE_INFORMATION_SERVICE,
                     HEART_RATE_MEASUREMENT_SERVICE,
                     BATTERY_SERVICE,
                     TI_KEYFOB_ACCELEROMETER_SERVICE,
                     TI_KEYFOB_KEYPRESSED_SERVICE,
                     nil ];
}


#pragma mark- Actions
- (IBAction)demosButton:(UIBarButtonItem *)sender
{
    DLog(@"Demos button tapped.");
    
    // segue to demo list view controller
    [self performSegueWithIdentifier:@"ShowDemoList" sender:self];
    
}

#pragma mark- Properties

// Setter for peripheral - the model for the controller
-(void)setPeripheral:(CBPeripheral *)peripheral
{
    // set the property
    _peripheral = peripheral;
    
    // the peripheral's services have been set at this point, determine if demos exist for any of the services
    for (CBService *service in _peripheral.services)
    {
        NSString *uuidString = [[service.UUID representativeString]uppercaseString];
        DLog(@"Peripheral Service: %@",uuidString);
        
        if ([_demoServices containsObject:uuidString])
        {
            //enable the demo button in the tool bar
            [self.toolbarItems[0] setEnabled:YES];
            break;
        }
    }
    
    [self.tableView reloadData];
}


#pragma mark- View Controller Lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog(@"Entering viewWillAppear in BLEPeripheralServicesTVC");
    self.title = @"Services";
    
    [self.tableView reloadData];
}


/*
 *
 * Method Name:  prepareForSegue
 *
 * Description:  Seques to next scene in response to user action
 *
 * Parameter(s): seque - segue to execute
 *
 */
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  
    if ([segue.identifier isEqualToString:@"ShowCharacteristics"])
    {
        DLog(@"Segueing to Show Characteristics");
        if ([segue.destinationViewController isKindOfClass:[BLEPeripheralCharacteristicsTVC class]])
        {
            if ([sender isKindOfClass:[CBService class]])
            {
                CBService *service =  (CBService *)sender;
                BLEPeripheralCharacteristicsTVC *destination = segue.destinationViewController;
                destination.characteristics = service.characteristics;
            
            }
            
        }
    }
    else if ([segue.identifier isEqualToString:@"ShowDemoList"])
    {
        DLog(@"Segueing to Demo Dispatcher");
        if ([segue.destinationViewController isKindOfClass:[BLEDemoDispatcherTableViewController  class]])
        {
            BLEDemoDispatcherTableViewController *destination = segue.destinationViewController;
            
            destination.peripheral = self.peripheral;
            destination.demoServices = _demoServices;
        }
    }
}


#pragma mark- Private Methods


// Discover characteristics for Service
-(void)discoverCharacteristicsForService: (CBService *) service
{
    if (service.peripheral && service.peripheral.state == CBPeripheralStateConnected)
    {
        if (service.peripheral.delegate == nil)
        {
            service.peripheral.delegate = self;
        }
        
     
        [service.peripheral discoverCharacteristics:nil forService:service];
    }
}




#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    DLog(@"numberOfSectionsInTableView invoked");
    NSUInteger count = [self.peripheral.services count];
    DLog(@"count = %u",count);
    // Return the number of sections.
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ServiceData";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = @"Service UUID";
    CBService *service = [self.peripheral.services objectAtIndex:indexPath.section];
    
    cell.detailTextLabel.text = [[service.UUID representativeString]uppercaseString];
    
    return cell;
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


// Accessory button is used to segue to characteristic data via CentralManager delegate
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"Accessory button tapped in PeripheralServicesTVC");
    // the service corresponds to the indexPath.section item in peripheral.services array
    CBService * service = [self.peripheral.services objectAtIndex:indexPath.section];
    
    service.peripheral.delegate = self;
    [service.peripheral discoverCharacteristics:nil forService:service];
    
    
}



#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    DLog(@"didDiscoverCharacteristicsForService invoked");
    
    if (error == nil)
    {
        // segue to BLEPeripheralCharacteristicsTVC
        [self performSegueWithIdentifier:@"ShowCharacteristics" sender:service];
    }
}



@end
