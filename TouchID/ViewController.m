//
//  ViewController.m
//  TouchID
//
//  Created by Felix Kurniawan on 10/30/14.
//  Copyright (c) 2014 Felix Kurniawan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize authenticationLabel = _authenticationLabel;
@synthesize textField = _textField;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self performAuthentication];
}

- (void) performAuthentication {
    LAContext *context = [LAContext new];
    NSError *error;
    if([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        [self doEvaluation:context];
    } else {
        _authenticationLabel.text = @"Authentication Not Available";
    }
}

- (void)doEvaluation:(LAContext *)context {
    [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:@"To access your private data" reply:^(BOOL success, NSError *authenticationError) {
        if(success) {
            [self changeLabel:@"Hello you!"];
        } else {
            [self changeLabel:@"Sorry, I don't know you"];
        }
    }];
}

- (void)changeLabel:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        _authenticationLabel.text = text;
    });
}

- (void)setDataExist {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setBool:true forKey:@"dataExist"];
    [def synchronize];
}

- (BOOL)dataExist {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    return [def objectForKey:@"dataExist"];
}

- (IBAction)storeData:(id)sender {
    [self.view endEditing:YES];
    
    if(![self dataExist]) {
        // new
        SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, nil);
        
        NSData* secret = [_textField.text dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *query = @{
                                (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrService: @"myservice",
                                (__bridge id)kSecAttrAccount: @"my account",
                                (__bridge id)kSecValueData: secret,
                                (__bridge id)kSecAttrAccessControl: (__bridge id)sacObject};
        NSLog(@"Prepare store %@", [NSThread currentThread]);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSLog(@"Storing %@", [NSThread currentThread]);
            OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, nil);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setDataExist];
                [self showAlert:status withSuccessMessage:true];
            });
        });
    } else {
        [self updateData];
    }
}

- (IBAction)loadData:(id)sender {

    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: @"myservice",
                            (__bridge id)kSecAttrAccount: @"my account",
                            (__bridge id)kSecReturnData: @YES,
                            (__bridge id)kSecUseOperationPrompt: @"Ndelok datamu"};
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        CFTypeRef dataTypeRef = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataTypeRef);
        [self showAlert:status withSuccessMessage:false];
        NSData *resultData = (__bridge NSData *)dataTypeRef;
        NSString * result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{ _textField.text = result; });
    });
}

- (void)updateData {
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: @"myservice",
                            (__bridge id)kSecAttrAccount: @"my account",
                            (__bridge id)kSecUseOperationPrompt: @"Ngapdate datamu"};

    NSDictionary *update = @{
                             (__bridge id)kSecValueData: [_textField.text dataUsingEncoding:NSUTF8StringEncoding]
                             };
    NSLog(@"Prepare update %@", [NSThread currentThread]);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSLog(@"Updating %@", [NSThread currentThread]);
        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)(query), (__bridge CFDictionaryRef)(update));
        dispatch_async(dispatch_get_main_queue(), ^{ [self showAlert:status withSuccessMessage:true]; });
    });
}

- (void)showAlert:(NSInteger)status withSuccessMessage:(BOOL)successMessage{
    NSLog(@"After store %@", [NSThread currentThread]);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Shit happen" message:@"Can't save data!" delegate:self cancelButtonTitle:@"Oh Shit!" otherButtonTitles:nil];
    NSLog(@"%ld", status);
    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Iso" message:@"Iso rek!" delegate:self cancelButtonTitle:@"Yo wes!" otherButtonTitles:nil];
    switch (status) {
        case errSecSuccess:
            [_textField setText:@""];
            if(successMessage) {
                [successAlert show];
            }
            break;
        case errSecDuplicateItem:
            [self setDataExist];
            break;
        default:
            [alert show];
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
