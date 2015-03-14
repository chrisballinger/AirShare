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
#import "BLEFileTransferMessage.h"

@interface BLEPeerBrowserViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSMutableOrderedSet *peers;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) BOOL hasUpdatedConstraints;
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
    //[self setupDoneButton];
    //[self setupBroadcastButton];
    [self updateViewConstraints];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSArray *peers = [self.sessionManager discoveredPeers];
    [self.peers addObjectsFromArray:peers];
    [self.sessionManager scanForPeers];
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
    if (index == NSNotFound) {
        [self.peers addObject:peer];
    } else {
        [self.peers replaceObjectAtIndex:index withObject:peer];
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
    if ([message isKindOfClass:[BLEFileTransferMessage class]]) {
        BLEFileTransferMessage *fileTransfer = (BLEFileTransferMessage*)message;
        if (fileTransfer.transferType == BLEFileTransferMessageTypeOffer) {
            fileTransfer.transferType = BLEFileTransferMessageTypeAccept;
        }
        [self.sessionManager sendSessionMessage:fileTransfer toPeer:peer];
        NSLog(@"received message from peer: %@ %@", message, peer);
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
    BLERemotePeer *peer = [self.peers objectAtIndex:indexPath.row];
    NSData *testData = [self generateTestDataOfLength:16000];
    NSString *tempDirectory = NSTemporaryDirectory();
    NSString *testPath = [tempDirectory stringByAppendingPathComponent:@"test.file"];
    BOOL success = [testData writeToFile:testPath atomically:YES];
    NSParameterAssert(success);
    BLEFileTransferMessage *fileTransfer = [[BLEFileTransferMessage alloc] initWithFileURL:[NSURL fileURLWithPath:testPath] transferType:BLEFileTransferMessageTypeOffer];
    [self.sessionManager sendSessionMessage:fileTransfer toPeer:peer];
}

@end
