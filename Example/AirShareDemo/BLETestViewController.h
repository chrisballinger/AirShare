//
//  BLETestViewController.h
//  AirShare
//
//  Created by Christopher Ballinger on 3/24/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLETestViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *authorTextField;
@property (strong, nonatomic) IBOutlet UITextView *quoteTextView;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;
@property (strong, nonatomic) IBOutlet UIButton *receiveButton;

- (IBAction)sendButtonPressed:(id)sender;
- (IBAction)receiveButtonPressed:(id)sender;

@end
