//
//  BLEViewController.m
//  BLE_Scanner
//
//  Created by Chip Keyes on 1/28/13.
//  Copyright (c) 2013 Chip Keyes. All rights reserved.
//

#import "BLECentralManagerViewController.h"
#import "BLEPeripheralServicesTVC.h"


@interface BLECentralManagerViewController ()

// initiate scanning
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanBarButton;

// animate when central manager scanning, connecting, etc.
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *centralManagerActivityIndicator;

// displays CBCentralManager status (role of iphone/ipad)
@property (weak, nonatomic) IBOutlet UILabel *hostBluetoothStatus;

// label which displays central manager activity
@property (weak, nonatomic) IBOutlet UILabel *centralManagerStatus;

// CBCentral Manager 
@property (strong, nonatomic) CBCentralManager *centralManager;

// reference to discovered device list table view controller - a child controller
@property (nonatomic, strong) BLEDiscoveredDevicesTVC *discoveredDeviceListTVC;

// flag indicating whether scanning is currently active
@property (nonatomic) BOOL scanState;

// list of discovered peripherals
@property (nonatomic, strong)NSMutableArray *discoveredPeripherals;


// the BLEPeripheralRecord corresponding to a peripheral which is connecting
@property (nonatomic, strong) BLEPeripheralRecord *connectingPeripheral;

// the BLEPeripheralRecord corresponding to the peripheral which is disconnecting
@property (nonatomic, strong) BLEPeripheralRecord *disconnectingPeripheral;

@end

@implementation BLECentralManagerViewController

#pragma mark- Actions

// User cancels connect request
- (IBAction)stopConnect:(id)sender
{
    [self.centralManager cancelPeripheralConnection:self.connectingPeripheral.peripheral];
    
    NSArray *toolbarItems = self.toolbarItems;
    [[toolbarItems objectAtIndex:[toolbarItems count]-1]setEnabled:NO];
    
    [self.centralManagerActivityIndicator stopAnimating];
    self.centralManagerStatus.textColor = [UIColor blackColor];
    self.centralManagerStatus.text = @"Idle";
    
}


// toggle button, initiate scanning if not scanning or stops scanning if scanning
- (IBAction)scanButton
{
    if (! self.scanState)
    {
        if (self.centralManager.state == CBCentralManagerStatePoweredOn)
        {
            self.scanState = YES;  // scanning
            self.scanBarButton.title = @"Stop";
            
            DLog(@"Starting scan...");
            
            self.centralManagerStatus.textColor = [UIColor greenColor];
            self.centralManagerStatus.text = @"Scanning for all services.";
                
            [self.centralManager scanForPeripheralsWithServices:nil options:nil];
            
            [self.centralManagerActivityIndicator startAnimating];
        }
        else
        {
            DLog(@"Scan request not executed, central manager not in powered on state");
            DLog(@"Central Manager state: %@",[ [self class] getCBCentralStateName: self.centralManager.state]);
        }
    }
    else  // stop scanning
    {
        DLog(@"Scan stopped");
        [self.centralManagerActivityIndicator stopAnimating];
        self.centralManagerStatus.textColor = [UIColor blackColor];
        self.centralManagerStatus.text = @"Idle";
        if (self.centralManager.state == CBCentralManagerStatePoweredOn)
        {
            [self.centralManager stopScan];
        }
        
        self.scanBarButton.title = @"Scan";
        self.scanState = NO;
    }
}


#pragma mark - Properties


// Lazy instantiation of discovered peripheral list.
-(NSMutableArray *)discoveredPeripherals
{
    if (_discoveredPeripherals == nil)
    {
        // provide an empty array so that the table view code will not have to deal with nil source data
        _discoveredPeripherals = [NSMutableArray array];
    }
    
    return _discoveredPeripherals;
}


#pragma mark - Private Functions

/*
 *
 * Method Name:  logDiscoveredDeviceInformation
 *
 * Description:  log discovered device information for debug support
 *
 * Parameter(s): peripheral - discovered device
 *               advertisementData - advertisement data broadcasted by device
 *               RSSI - received signal strength indicator
 *
 */
-(void)logDiscoveredDeviceInformation:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    DLog(@"A peripheral was discovered during scan.");
    
    // log the peripheral name
    DLog(@"Peripheral Name:  %@",peripheral.name);
    
    // log the peripheral UUID
    NSUUID *uuid = peripheral.identifier;
    if (uuid)
    {
        NSString *uuid_string = [uuid UUIDString];
        DLog(@"Peripheral UUID: %@",uuid_string);
    }
    else
    {
        DLog(@"Discovered peripheral provided no UUID on initial discovery");
    }
    
    // log the advertisement keys
    DLog(@"Logging advertisement keys descriptions");
    NSArray *keys = [advertisementData allKeys];
    for (id key in keys)
    {
        if ([key isKindOfClass:[NSString class]])
        {
            id value = [advertisementData objectForKey:key];
            
            DLog(@"advertisement key:  %@  value:  %@",key, [value description]);
        }
    }
    if (RSSI)
    {
        // log the rssi value
        DLog(@"RSSI value: %i", [RSSI shortValue]);
    }
    else
    {
        DLog(@"Discovered peripheral data did not include RSSI");
    }
}


// Converts CBCentralManagerState to a string... implement as a category on CBCentralManagerState?
+(NSString *)getCBCentralStateName:(CBCentralManagerState) state
{
    NSString *stateName;
    
    switch (state) {
        case CBCentralManagerStatePoweredOn:
            stateName = @"Bluetooth Powered On - Ready";
            break;
        case CBCentralManagerStateResetting:
            stateName = @"Resetting";
            break;
            
        case CBCentralManagerStateUnsupported:
            stateName = @"Unsupported";
            break;
            
        case CBCentralManagerStateUnauthorized:
            stateName = @"Unauthorized";
            break;
            
        case CBCentralManagerStatePoweredOff:
            stateName = @"Bluetooth Powered Off";
            break;
            
        default:
            stateName = @"Unknown";
            break;
    }
    return stateName;
}


// Cpnnect to specified peripheral if not already connected
-(void) connectToPeripheralDevice : (CBPeripheral *)peripheral
{
   
    // Implement checks before connecting, i.e. already connected
    if (!peripheral.state)
    {
        NSArray *toolbarItems = self.toolbarItems;
        [[toolbarItems objectAtIndex:[toolbarItems count]-1]setEnabled:YES];
        DLog(@"CBCentralManager connecting to peripheral");
        self.centralManagerStatus.textColor = [UIColor greenColor];
        self.centralManagerStatus.text = @"Connecting to peripheral.";
        [self.centralManagerActivityIndicator startAnimating];
        
        // Core Bluetooth Connect Request
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
    else if (peripheral)
    {
        DLog(@"Request for CentralManager to connect to a connected peripheral ignored.");
    }
    else
    {
        DLog(@"Request to connect CentralManager to nil peripheral pointer ignored.");
    }
        
}


// Disconnect a peripheral from Central after ensuring peripheral is in connected state
-(void) disconnectPeripheralDevice:(CBPeripheral *)peripheral
{
    // Ensure peripheral is connected
    if (!peripheral.state)
    {
        DLog(@"CBCentralManager disconnecting peripheral");
        
         // Core Bluetooth Cancel Connection Request
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    else if (peripheral)
    {
        DLog(@"Request for CentralManager to disconnect an unconnected peripheral ignored.");
    }
    else
    {
        DLog(@"Request to disconnect CentralManager to nil peripheral pointer ignored.");
    }
}


/*
 *
 * Method Name:  removeDuplicatePeripherals
 *
 * Description:  A discovered device may not have an assigned UUID. A device UUID is assigned after a connection is made to the device. This method removes duplicate peripheral entries in the discoveredPeripherals list after a connection is made to a peripheral. The newly connected peripheral is passed in as a parameter and its UUID is compared to the other peripherals in the list. Duplicates are indentified by the index set returned from the comparison test. All duplcates are removed from the list leaving only a single entry for the peripheral.
 *
 * Parameter(s): peripheral - the newly connected device which is used to compare agianst the entries in the connectedPeripherals list
 *
 */
-(void)removeDuplicatePeripherals : (CBPeripheral *) peripheral
{
    BOOL (^test)(id obj, NSUInteger idx, BOOL *stop);
    test = ^(id obj, NSUInteger idx, BOOL *stop)
    {
        BLEPeripheralRecord *record = (BLEPeripheralRecord *)obj;
        if ( record.peripheral.identifier == peripheral.identifier )
        {
            return YES;
        }
        return NO;
    };

    NSIndexSet * indexSet;
    indexSet = [self.discoveredPeripherals indexesOfObjectsPassingTest:test];
            
    if ([indexSet count]> 1)
    {
        // more than one entry has the same UUID
        NSMutableIndexSet *duplicates = [[NSMutableIndexSet alloc] initWithIndexSet:indexSet];
        // don't remove one instance
        [duplicates removeIndex:0];
        // remove all duplicates from the list
        [self.discoveredPeripherals removeObjectsAtIndexes:duplicates];
    }
}


/*
 *
 * Method Name:  updateDiscoveredPeripheralList
 *
 * Description:  Examines a newly discovered device to determine if it has previously been discovered. If not, then the new device is added to the device list and the table view is updated.
 *  
 *  If the device is being rediscovered, then the entry in the list is replaced with the new record since it may contain additional advertising data in some active discovery modes.
 *
 * Parameter(s): newRecord - device record corresponding to newly discovered device
 *
 */
-(void)updateDiscoveredPeripheralList:(BLEPeripheralRecord *)newRecord
{
    // determine if the list contain a corresponding entry based upon UUID
    BOOL matchFound = NO;
    
    // stringify the UUID of the newly discovered device
    NSUUID *newUUID = newRecord.peripheral.identifier;
   
    // If we have a UUID string to compare with then look at the list
    if (newUUID)
    {
        NSUInteger index = 0;
        // look for match in previously discovered devices
        for (BLEPeripheralRecord *record in self.discoveredPeripherals)
        {
            NSUUID *uuid = record.peripheral.identifier;
            if (uuid)
            {
                if (newUUID == uuid)
                {
                    matchFound = YES;
                    [self.discoveredPeripherals replaceObjectAtIndex:index withObject:newRecord];
                    self.discoveredDeviceListTVC.discoveredPeripherals = self.discoveredPeripherals;
                    break;
                }
            }
            
            index+=1;
        }
        
        if (! matchFound)
        {
            // add the new record
            [self.discoveredPeripherals addObject:newRecord];
            self.discoveredDeviceListTVC.discoveredPeripherals = self.discoveredPeripherals;
        }
    }
    else
    {
        // a peripheral was discovered with no UUID 
        // this is valid, we won't know the device UUID until after connecting
        [self.discoveredPeripherals addObject:newRecord];
        self.discoveredDeviceListTVC.discoveredPeripherals = self.discoveredPeripherals;
    }
}


#pragma mark- Controller Lifecycle

-(void)awakeFromNib
{
    [super awakeFromNib];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    
    // Initialize central manager providing self as its delegate
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    // initial scan state 
    _scanState = NO;  
    
    //iPad specific initializations
    if (self.splitViewController)
    {
        // Get a handle to the detail view controller
        UINavigationController* detailRoot = [[self.splitViewController viewControllers] lastObject];
        self.discoveredDeviceListTVC = (BLEDiscoveredDevicesTVC *)detailRoot.topViewController;
        
        self.discoveredDeviceListTVC.delegate = self;
    }
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog(@"Entering viewWillAppear Central Manager View Controller");
}



// Segue to the embedded discovered services table view controller
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DLog(@"Preparing to segue from CentralManager");

    if ([segue.identifier isEqualToString:@"DiscoveredDevices"])
    {
        DLog(@"Segueing to Discovered Devices");
        if ([segue.destinationViewController isKindOfClass:[BLEDiscoveredDevicesTVC class]])
        {
            self.discoveredDeviceListTVC = segue.destinationViewController;
            self.discoveredDeviceListTVC.delegate = self;
        }
    }
}


#pragma mark - BLECentralManagerDelegate

// Request to connect Central Manager to peripheral from list of discovered device peripherals
-(void)connectPeripheral: (BLEPeripheralRecord *)peripheralRecord sender:(id)sender;
{
    self.connectingPeripheral = peripheralRecord;
    self.centralManagerStatus.text = @"Connecting to peripheral";
    
    // Core Bluetooth Connect Request
    [self connectToPeripheralDevice:peripheralRecord.peripheral];
}


// Request to disconnect Central Manager from peripheral
-(void)disconnectPeripheral: (BLEPeripheralRecord *)peripheralRecord sender:(id)sender
{
    self.disconnectingPeripheral = peripheralRecord;
    self.centralManagerStatus.text = @"Disconnecting peripheral";
    [self disconnectPeripheralDevice:peripheralRecord.peripheral];

}


#pragma mark - CBCentralManagerDelegate
// CBCentralManager state changed
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    DLog(@"Central Manager Delegate DidUpdate State Invoked");
    
    if (self.centralManager.state ==CBCentralManagerStatePoweredOn)
    {
        self.hostBluetoothStatus.textColor = [UIColor greenColor];
    }
    else if ( (self.centralManager.state == CBCentralManagerStateUnknown) ||
              (self.centralManager.state == CBCentralManagerStateResetting) )
    {
        self.hostBluetoothStatus.textColor = [UIColor blackColor];
    }
    else
    {
        self.hostBluetoothStatus.textColor = [UIColor redColor];
    }
    
    self.hostBluetoothStatus.text = [[self class ] getCBCentralStateName: self.centralManager.state];
}


// A peripheral was discovered during scan.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [self logDiscoveredDeviceInformation:peripheral advertisementData:advertisementData RSSI:RSSI];
    
    BLEPeripheralRecord *discoveryRecord = [[BLEPeripheralRecord alloc] initWithCentral:central didDiscoverPeripheral:peripheral withAdvertisementData:advertisementData withRSSI:RSSI];
    
    // if this device is unknown add it to the list, otherwise replace entry with updated information
    [self updateDiscoveredPeripheralList:discoveryRecord];
    
}



//Invoked whenever a connection is succesfully created with the peripheral.
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    
    self.connectingPeripheral.peripheral = peripheral;
    self.connectingPeripheral = nil;
    
    // display idle status for Central
    [self.centralManagerActivityIndicator stopAnimating];
    self.centralManagerStatus.textColor = [UIColor blackColor];
    self.centralManagerStatus.text = @"Idle";
   
    DLog(@"Connected to peripheral");
    
    [self removeDuplicatePeripherals :peripheral];
    
    // toggle connect button label in corresponding discovered devices table view row in the BLEDiscoveredDevicesTVC
    [self.discoveredDeviceListTVC toggleConnectionState:peripheral];
    
    NSArray *toolbarItems = self.toolbarItems;
    [[toolbarItems objectAtIndex:[toolbarItems count]-1]setEnabled:NO];
    
}

//Invoked whenever an existing connection with the peripheral is torn down.
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (! error)
    {
        DLog(@"Peripheral succssfully disconnected.");
        self.disconnectingPeripheral.peripheral = peripheral;
        self.disconnectingPeripheral = nil;
        [self.centralManagerActivityIndicator stopAnimating];
        self.centralManagerStatus.textColor = [UIColor blackColor];
        self.centralManagerStatus.text = @"Idle";
        
        [self.discoveredDeviceListTVC synchronizeConnectionStates];
    }
    else 
    {
        DLog(@"Error disconnecting: %@",[error localizedDescription]);
        
        // This could occur for several reasons, a connection may have ben dropped by the system without the user initiating a disconnect, or a disconnect request could fail.
        
        // The course of action is to synch the state of the connected peripherals in the connected peripheral list and their corresponding connect/disconnect buttons in the discovered peripheral list.
        [self.discoveredDeviceListTVC synchronizeConnectionStates];
       
    }
}

//Invoked whenever the central manager fails to create a connection with the peripheral.
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    DLog(@"Failed to connect to peripheral");
}


#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    DLog(@"didDiscoverDescriptorsForCharacteristic invoked");
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
     DLog(@"didDiscoverIncludedServicesForService invoked");
}


// Invoked upon completion of a -[discoverServices:] request.
//
//If successful, "error" is nil and discovered services, if any, have been merged into the "services" property of the peripheral. If unsuccessful, "error" is set with the encountered failure.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    DLog(@"didDiscoverServices invoked");
    
    [self.centralManagerActivityIndicator stopAnimating];
    self.centralManagerStatus.textColor = [UIColor blackColor];
    self.centralManagerStatus.text = @"Idle";

    if (error == nil)
    {
        // segue to BLEPeripheralServicesTVC
        [self performSegueWithIdentifier:@"ShowServices" sender:self];
    }
}


@end
