//Create by Jaxktg on 29/11/2024
#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <substrate.h>

@interface KeychainDeletionButton : UIButton
+ (void)showFloatingButtonInView:(UIView *)parentView;
+ (BOOL)isButtonAlreadyPresent:(UIView *)parentView;
- (void)deleteKeychainItems;
@end

@implementation KeychainDeletionButton {
    CGRect _safeArea;
}

+ (BOOL)isButtonAlreadyPresent:(UIView *)parentView {
    for (UIView *subview in parentView.subviews) {
        if ([subview isKindOfClass:[KeychainDeletionButton class]]) {
            return YES;
        }
    }
    return NO;
}

+ (void)showFloatingButtonInView:(UIView *)parentView {
    // Check if button already exists
    if ([self isButtonAlreadyPresent:parentView]) {
        return;
    }

    KeychainDeletionButton *floatingButton = [KeychainDeletionButton buttonWithType:UIButtonTypeCustom];

    // Button styling
    floatingButton.backgroundColor = [UIColor blackColor];
    floatingButton.layer.cornerRadius = 30;

    // Add shadow
    floatingButton.layer.shadowColor = [UIColor blackColor].CGColor;
    floatingButton.layer.shadowOffset = CGSizeMake(0, 4);
    floatingButton.layer.shadowRadius = 6;
    floatingButton.layer.shadowOpacity = 0.3;

    // Calculate safe area insets
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = parentView.safeAreaInsets;
    }

    // Position button in bottom right of safe area
    CGFloat buttonSize = 60;
    floatingButton.frame = CGRectMake(
        parentView.frame.size.width - buttonSize - 10 - safeAreaInsets.right,
        parentView.frame.size.height - buttonSize - 10 - safeAreaInsets.bottom,
        buttonSize,
        buttonSize
    );

    // Store safe area bounds for dragging constraints
    floatingButton->_safeArea = CGRectMake(
        safeAreaInsets.left,
        safeAreaInsets.top,
        parentView.frame.size.width - buttonSize - safeAreaInsets.left - safeAreaInsets.right,
        parentView.frame.size.height - buttonSize - safeAreaInsets.top - safeAreaInsets.bottom
    );

    // Button icon using SF Symbol with version check
    UIImage *trashIcon;
    if (@available(iOS 13.0, *)) {
        trashIcon = [UIImage systemImageNamed:@"key.slash.fill"];
    } else {
        // Fallback for older iOS versions
        trashIcon = [UIImage imageNamed:@"trash-icon"]; // You'd need to provide this image
    }

    [floatingButton setImage:trashIcon forState:UIControlStateNormal];
    floatingButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    floatingButton.tintColor = [UIColor whiteColor];

    // Configure button state colors
    [floatingButton setImage:trashIcon forState:UIControlStateNormal];
    [floatingButton setImage:trashIcon forState:UIControlStateHighlighted];

    // Add target actions for state management
    [floatingButton addTarget:floatingButton action:@selector(buttonPressed) forControlEvents:UIControlEventTouchDown];
    [floatingButton addTarget:floatingButton action:@selector(buttonReleased) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];

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

- (void)buttonPressed {
    // On press: white background, black symbol
    self.backgroundColor = [UIColor whiteColor];
    self.tintColor = [UIColor blackColor];
}

- (void)buttonReleased {
    // On release: black background, white symbol
    self.backgroundColor = [UIColor blackColor];
    self.tintColor = [UIColor whiteColor];
}

- (void)buttonTapped:(UIButton *)sender {
    // Show confirmation alert
    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:@"Delete Keychain Items"
        message:@"Are you sure you want to delete all keychain items? This cannot be undone."
        preferredStyle:UIAlertControllerStyleAlert];

    // Cancel action
    UIAlertAction *cancelAction = [UIAlertAction
        actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel
        handler:nil];

    // Confirm action
    UIAlertAction *deleteAction = [UIAlertAction
        actionWithTitle:@"Delete"
        style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction * _Nonnull action) {
            [self deleteKeychainItems];

            // Provide visual feedback
            self.backgroundColor = [UIColor greenColor];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.backgroundColor = [UIColor blackColor];
            });
        }];

    [alertController addAction:cancelAction];
    [alertController addAction:deleteAction];

    // Present the alert from the top view controller
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    [topViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.superview];
    CGPoint newCenter = CGPointMake(
        recognizer.view.center.x + translation.x,
        recognizer.view.center.y + translation.y
    );

    // Constrain to safe area
    newCenter.x = MAX(CGRectGetMinX(_safeArea), MIN(newCenter.x, CGRectGetMaxX(_safeArea)));
    newCenter.y = MAX(CGRectGetMinY(_safeArea), MIN(newCenter.y, CGRectGetMaxY(_safeArea)));

    recognizer.view.center = newCenter;
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
