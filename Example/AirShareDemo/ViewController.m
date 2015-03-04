//
//  ViewController.m
//  IOCipherServer
//
//  Created by Christopher Ballinger on 1/22/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "ViewController.h"
#import "BLEPeerBrowserViewController.h"
#import "BLESessionViewController.h"
#import "BLESessionManager.h"
#import "BLECrypto.h"
#import "BLELocalPeer.h"

static NSString * const CellIdentifier = @"CellIdentifier";

@interface ViewController ()
@property (nonatomic, strong) BLELocalPeer *localPeer;
@property (nonatomic, strong) BLESessionManager *sessionManager;
@end



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    BLEKeyPair *keyPair = [BLEKeyPair keyPairWithType:BLEKeyTypeEd25519];
    BLELocalPeer *localPeer = [[BLELocalPeer alloc] initWithPublicKey:keyPair.publicKey privateKey:keyPair.privateKey];
    self.localPeer = localPeer;
    self.sessionManager = [[BLESessionManager alloc] initWithLocalPeer:self.localPeer delegate:nil];
}

- (IBAction) shareButtonPressed:(id)sender {
    NSURL *fileURL = nil;
    BLETransfer *transfer = [BLETransfer transferWithFileURL:fileURL];
    BLESessionViewController *sessionView = [[BLESessionViewController alloc] initWithOutgoingTransfer:transfer sessionManager:self.sessionManager];
    sessionView.transferCompletionBlock = ^void(BLETransfer *transfer, NSError *error) {
        //outgoing transfer finished
        
    };
    [self presentViewController:sessionView animated:YES completion:nil];
}

- (IBAction) browseButtonPressed:(id)sender {
    BLEPeerBrowserViewController *peerBrowser = [[BLEPeerBrowserViewController alloc] initWithSessionManager:self.sessionManager];
    peerBrowser.transferCompletionBlock = ^void(BLETransfer *transfer, NSError *error) {
        //incoming transfer finished
        NSURL *fileURL = transfer.fileURL;
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:peerBrowser];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
