//
//  ViewController.h
//  TouchID
//
//  Created by Felix Kurniawan on 10/30/14.
//  Copyright (c) 2014 Felix Kurniawan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <LocalAuthentication/LocalAuthentication.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *authenticationLabel;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

