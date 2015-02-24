//
//  BLEPeerBrowserViewController.m
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import "BLEPeerBrowserViewController.h"
#import "BLESessionViewController.h"
#import "BLEPeerTableViewCell.h"
#import "PureLayout.h"

@interface BLEPeerBrowserViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSMutableArray *peers;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) BOOL hasUpdatedConstraints;
@end

@implementation BLEPeerBrowserViewController

- (instancetype) initWithSessionManager:(BLESessionManager*)sessionManager {
    if (self = [super init]) {
        _sessionManager = sessionManager;
        self.sessionManager.delegate = self;
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
    self.peers = [NSMutableArray array];
    [self setupTableView];
    [self setupDoneButton];
    [self setupBroadcastButton];
    [self updateViewConstraints];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

#pragma mark BLESessionManagerDelegate

- (void) sessionManager:(BLESessionManager*)sessionManager
errorEstablishingSession:(NSError*)error {
    
}

- (void) sessionManager:(BLESessionManager*)sessionManager
     sessionEstablished:(BLESession*)session {
    BLESessionViewController *sessionView = [[BLESessionViewController alloc] initWithSession:session sessionManager:self.sessionManager];
    [self.navigationController pushViewController:sessionView animated:YES];
}

- (void) sessionManager:(BLESessionManager *)sessionManager
                   peer:(BLEPeer *)peer
          statusUpdated:(BLEConnectionStatus)status {
    NSUInteger index = [self.peers indexOfObjectPassingTest:^BOOL(BLEPeer *testPeer, NSUInteger idx, BOOL *stop) {
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
    [self.peers sortUsingComparator:^NSComparisonResult(BLEPeer *peer1, BLEPeer *peer2) {
        NSComparisonResult result = NSOrderedSame;
        if (peer1.RSSI && peer2.RSSI) {
            result = [peer1.RSSI compare:peer2.RSSI];
        }
        return result;
    }];
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.peers.count;
}

#pragma mark UITableViewDelegate

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BLEPeerTableViewCell *peerCell = [tableView dequeueReusableCellWithIdentifier:[BLEPeerTableViewCell cellIdentifier] forIndexPath:indexPath];
    return peerCell;
}

@end
