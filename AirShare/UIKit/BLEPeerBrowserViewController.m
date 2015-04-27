//
//  BLEPeerBrowserViewController.m
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import "BLEPeerBrowserViewController.h"
#import "BLEPeerTableViewCell.h"
#import "PureLayout.h"
#import "BLEDataMessage.h"

@interface BLEPeerBrowserViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSMutableOrderedSet *peers;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) BOOL hasUpdatedConstraints;
@property (nonatomic, strong) BLEDataMessage *outgoingTransfer;
@end

@implementation BLEPeerBrowserViewController

- (instancetype) initWithSessionManager:(BLESessionManager*)sessionManager {
    if (self = [self init]) {
        _sessionManager = sessionManager;
        self.sessionManager.delegate = self;
        self.sessionManager.delegateQueue = dispatch_get_main_queue();
    }
    return self;
}

- (instancetype) init {
    if (self = [super init]) {
        self.title = NSLocalizedString(@"Peer Browser", @"title for peer browser");
        self.mode = BLEPeerBrowserModeReceive;
        self.delegateQueue = dispatch_get_main_queue();
    }
    return self;
}

- (void) updateViewConstraints {
    [super updateViewConstraints];
    if (self.hasUpdatedConstraints) {
        return;
    }
    [self.tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero];
    self.hasUpdatedConstraints = YES;
}

- (void) addOutgoingData:(NSData*)data headers:(NSDictionary*)headers {
    self.outgoingTransfer = [[BLEDataMessage alloc] initWithData:data extraHeaders:headers];
}

- (void) setupTableView {
    self.tableView = [[UITableView alloc] init];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[BLEPeerTableViewCell class] forCellReuseIdentifier:[BLEPeerTableViewCell cellIdentifier]];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.peers = [NSMutableOrderedSet orderedSet];
    [self setupTableView];
    [self setupDoneButton];
    //[self setupBroadcastButton];
    [self updateViewConstraints];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSArray *peers = [self.sessionManager discoveredPeers];
    [self.peers addObjectsFromArray:peers];
    
    if (self.mode == BLEPeerBrowserModeSend) {
        [self.sessionManager scanForPeers];
    } else if (self.mode == BLEPeerBrowserModeReceive) {
        [self.sessionManager advertiseLocalPeer];
    }
}

- (void) setupDoneButton {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
}

- (void) setupBroadcastButton {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Broadcast" style:UIBarButtonItemStyleBordered target:self action:@selector(broadcastButtonPressed:)];
}

- (void) broadcastButtonPressed:(id)sender {
    [self.sessionManager advertiseLocalPeer];
}

- (void) doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (NSData*) generateTestDataOfLength:(NSUInteger)length {
    NSMutableData *data = [NSMutableData dataWithCapacity:length];
    uint8_t x = 0;
    for (NSUInteger i = 0; i < length; i++) {
        x++;
        [data appendBytes:&x length:1];
    }
    return data;
}

#pragma mark BLESessionManagerDelegate


- (void) sessionManager:(BLESessionManager *)sessionManager
                   peer:(BLERemotePeer *)peer
          statusUpdated:(BLEConnectionStatus)status {
    NSUInteger index = [self.peers indexOfObjectPassingTest:^BOOL(BLERemotePeer *testPeer, NSUInteger idx, BOOL *stop) {
        if ([peer.publicKey isEqual:testPeer.publicKey]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    
    if (status == BLEConnectionStatusConnected) {
        if (index == NSNotFound) {
            [self.peers addObject:peer];
        } else {
            [self.peers replaceObjectAtIndex:index withObject:peer];
        }
    } else if (status == BLEConnectionStatusDisconnected) {
        [self.peers removeObject:peer];
    }
    
    [self.peers sortUsingComparator:^NSComparisonResult(BLERemotePeer *peer1, BLERemotePeer *peer2) {
        NSComparisonResult result = NSOrderedSame;
        if (peer1.RSSI && peer2.RSSI) {
            result = [peer1.RSSI compare:peer2.RSSI];
        }
        return result;
    }];
    [self.tableView reloadData];
}

- (void) sessionManager:(BLESessionManager *)sessionManager receivedMessage:(BLESessionMessage *)message fromPeer:(BLERemotePeer *)peer {
    NSLog(@"received message from peer: %@ %@", message, peer);
    if ([message isKindOfClass:[BLEDataMessage class]]) {
        dispatch_async(self.delegateQueue, ^{
            BLEDataMessage *dataMessage = (BLEDataMessage*)message;
            [self.delegate peerBrowser:self dataReceived:dataMessage.data headers:dataMessage.extraHeaders];
        });
    }
}

#pragma mark UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.peers.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BLEPeerTableViewCell *peerCell = [tableView dequeueReusableCellWithIdentifier:[BLEPeerTableViewCell cellIdentifier] forIndexPath:indexPath];
    BLEPeer *peer = [self.peers objectAtIndex:indexPath.row];
    [peerCell setPeer:peer];
    return peerCell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

#pragma mark UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == BLEPeerBrowserModeSend && self.outgoingTransfer) {
        BLERemotePeer *peer = [self.peers objectAtIndex:indexPath.row];
        [self.sessionManager sendSessionMessage:self.outgoingTransfer toPeer:peer];
    }
}

@end
