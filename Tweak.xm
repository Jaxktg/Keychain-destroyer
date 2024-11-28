//Create by Jaxktg on 29/11/2024
//Credits to https://stackoverflow.com/questions/7142774/how-do-you-reset-an-iphone-apps-keychain/16136513#16136513 

#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <substrate.h>

@interface KeychainDeletionButton : UIButton
+ (void)showFloatingButtonInView:(UIView *)parentView;
- (void)deleteKeychainItems;
@end

@implementation KeychainDeletionButton

+ (void)showFloatingButtonInView:(UIView *)parentView {
    KeychainDeletionButton *floatingButton = [KeychainDeletionButton buttonWithType:UIButtonTypeCustom];
    
    // Button styling
    floatingButton.backgroundColor = [UIColor redColor];
    floatingButton.layer.cornerRadius = 30;
    floatingButton.frame = CGRectMake(
        parentView.frame.size.width - 70, 
        parentView.frame.size.height - 100, 
        60, 
        60
    );
    
    // Button icon (using text for simplicity)
    [floatingButton setTitle:@"🗑️" forState:UIControlStateNormal];
    floatingButton.titleLabel.font = [UIFont systemFontOfSize:30];
    
    // Add target action
    [floatingButton addTarget:floatingButton 
                       action:@selector(buttonTapped:) 
             forControlEvents:UIControlEventTouchUpInside];
    
    // Make button draggable
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] 
        initWithTarget:floatingButton 
        action:@selector(handlePan:)];
    [floatingButton addGestureRecognizer:panRecognizer];
    
    [parentView addSubview:floatingButton];
}

- (void)buttonTapped:(UIButton *)sender {
    [self deleteKeychainItems];
    
    // Provide visual feedback
    self.backgroundColor = [UIColor greenColor];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.backgroundColor = [UIColor redColor];
    });
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.superview];
    recognizer.view.center = CGPointMake(
        recognizer.view.center.x + translation.x,
        recognizer.view.center.y + translation.y
    );
    [recognizer setTranslation:CGPointZero inView:self.superview];
}

- (void)deleteKeychainItems {
    NSArray *secClasses = @[
        (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecClassInternetPassword,
        (__bridge id)kSecClassCertificate,
        (__bridge id)kSecClassKey,
        (__bridge id)kSecClassIdentity
    ];
    
    for (id secClass in secClasses) {
        NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            secClass, kSecClass,
            nil];
        
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        
        switch (status) {
            case errSecSuccess:
                NSLog(@"[KeychainDeletion] Successfully deleted keychain items for class: %@", secClass);
                break;
            case errSecItemNotFound:
                NSLog(@"[KeychainDeletion] No keychain items found for class: %@", secClass);
                break;
            default:
                NSLog(@"[KeychainDeletion] Failed to delete keychain items for class: %@. Error: %d", secClass, (int)status);
                break;
        }
    }
}

@end

%hook UIViewController

// Hook into viewDidAppear to add the floating button
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    // Only add button to main app's root view controller
    if (self.view.window.rootViewController == self) {
        [KeychainDeletionButton showFloatingButtonInView:self.view];
    }
}

%end
