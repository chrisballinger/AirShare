//
//  BLETransferViewController.m
//  Pods
//
//  Created by Christopher Ballinger on 2/20/15.
//
//

#import "BLESessionViewController.h"

@interface BLESessionViewController ()
/** Set if outgoing transfer before showing view */
@property (nonatomic, strong, readonly) BLETransfer *transfer;
@property (nonatomic, strong) UIProgressView *progressView;
@end

@implementation BLESessionViewController

- (instancetype) init {
    if (self = [super init]) {
    }
    return self;
}

- (instancetype) initWithOutgoingTransfer:(BLETransfer *)transfer {
    if (self = [self init]) {
        _transfer = transfer;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated {
    if (self.session) {
        self.session.delegate = self;
    } else {
        // get a session
        [self.sessionManager advertiseLocalPeer];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark BLESessionManagerDelegate

- (void) sessionManager:(BLESessionManager*)sessionManager
     sessionEstablished:(BLESession*)session {
    _session = session;
    self.session.delegate = self;
    [self.session offerTransfer:self.transfer progress:^(float progress) {
        self.progressView.progress = progress;
    } completion:^(BOOL success, NSError *error) {
        
    }];
}

#pragma mark BLESession

- (void) session:(BLESession*)session transferOffered:(BLETransfer*)transfer {
    [self.session acceptTransfer:transfer progress:^(float progress) {
        self.progressView.progress = progress;
    } completion:^(BOOL success, NSError *error) {
        
    }];
}

@end
