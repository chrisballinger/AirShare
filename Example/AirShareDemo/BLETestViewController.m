//
//  BLETestViewController.m
//  AirShare
//
//  Created by Christopher Ballinger on 3/24/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "BLETestViewController.h"
#import <AirShare/BLEPeerBrowserViewController.h>
#import <AirShare/BLECrypto.h>

static NSString * const kCachedLocalPeerKey = @"kCachedLocalPeerKey";


@interface BLETestViewController ()
@property (nonatomic, strong) BLESessionManager *sessionManager;
@end

@implementation BLETestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.authorTextField.delegate = self;
    self.authorTextField.returnKeyType = UIReturnKeyDone;
    self.quoteTextView.delegate = self;
    self.quoteTextView.returnKeyType = UIReturnKeyDone;
    
    NSData *localPeerData = [[NSUserDefaults standardUserDefaults] objectForKey:kCachedLocalPeerKey];
    BLELocalPeer *localPeer = nil;
    if (!localPeerData) {
        BLEKeyPair *keyPair = [BLEKeyPair keyPairWithType:BLEKeyTypeEd25519];
        localPeer = [[BLELocalPeer alloc] initWithPublicKey:keyPair.publicKey privateKey:keyPair.privateKey];
        NSData *peerData = [NSKeyedArchiver archivedDataWithRootObject:localPeer];
        [[NSUserDefaults standardUserDefaults] setObject:peerData forKey:kCachedLocalPeerKey];
    } else {
        localPeer = [NSKeyedUnarchiver unarchiveObjectWithData:localPeerData];
        NSParameterAssert(localPeer != nil);
    }
    self.sessionManager = [[BLESessionManager alloc] initWithLocalPeer:localPeer delegate:nil];
    
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)sendButtonPressed:(id)sender {
    BLEPeerBrowserViewController *peerBrowser = [[BLEPeerBrowserViewController alloc] initWithSessionManager:self.sessionManager];
    peerBrowser.mode = BLEPeerBrowserModeSend;
    NSDictionary *outgoingHeaders = @{@"author": self.authorTextField.text,
                                      @"quote": self.quoteTextView.text};
    [peerBrowser addOutgoingData:nil headers:outgoingHeaders];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:peerBrowser];
    [self presentViewController:nav animated:YES completion:nil];
}

- (IBAction)receiveButtonPressed:(id)sender {
    BLEPeerBrowserViewController *peerBrowser = [[BLEPeerBrowserViewController alloc] initWithSessionManager:self.sessionManager];
    peerBrowser.mode = BLEPeerBrowserModeReceive;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:peerBrowser];
    [self presentViewController:nav animated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}


@end
