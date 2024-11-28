//Create by Jaxktg on 29/11/2024
#import <UIKit/UIKit.h>
#import <Security/Security.h>
#import <substrate.h>
#import <objc/runtime.h>

@interface KeychainDeletionButton : UIButton
+ (void)showFloatingButton;
- (void)deleteKeychainItems;
@end

@implementation KeychainDeletionButton {
    CGRect _safeArea;
}

+ (void)showFloatingButton {
    UIWindow *keyWindow = nil;

    if (@available(iOS 13.0, *)) {
        NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) {
                    break;
                }
            }
        }
    } else {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }

    if (!keyWindow) {
        return;
    }

    // Use associated object to check if the button is already added
    KeychainDeletionButton *floatingButton = objc_getAssociatedObject(keyWindow, @selector(showFloatingButton));

    if (floatingButton) {
        return;
    }

    floatingButton = [KeychainDeletionButton buttonWithType:UIButtonTypeCustom];

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
        safeAreaInsets = keyWindow.safeAreaInsets;
    }

    // Position button in bottom right of safe area
    CGFloat buttonSize = 60;
    floatingButton.frame = CGRectMake(
        keyWindow.frame.size.width - buttonSize - 10 - safeAreaInsets.right,
        keyWindow.frame.size.height - buttonSize - 10 - safeAreaInsets.bottom,
        buttonSize,
        buttonSize
    );

    // Store safe area bounds for dragging constraints
    floatingButton->_safeArea = CGRectMake(
        safeAreaInsets.left,
        safeAreaInsets.top,
        keyWindow.frame.size.width - buttonSize - safeAreaInsets.left - safeAreaInsets.right,
        keyWindow.frame.size.height - buttonSize - safeAreaInsets.top - safeAreaInsets.bottom
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
    [floatingButton addTarget:floatingButton action:@selector(buttonReleased) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit | UIControlEventTouchDragOutside];

    [floatingButton addTarget:floatingButton
                       action:@selector(buttonTapped:)
             forControlEvents:UIControlEventTouchUpInside];

    // Make button draggable
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]
        initWithTarget:floatingButton
        action:@selector(handlePan:)];
    [floatingButton addGestureRecognizer:panRecognizer];

    // Add long-press gesture recognizer for author info
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc]
        initWithTarget:floatingButton
        action:@selector(showAuthorInfo:)];
    [floatingButton addGestureRecognizer:longPressRecognizer];

    [keyWindow addSubview:floatingButton];

    // Associate the button with the key window to prevent duplicates
    objc_setAssociatedObject(keyWindow, @selector(showFloatingButton), floatingButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Reset button appearance when dragging begins
        [self buttonReleased];
    }

    CGPoint translation = [recognizer translationInView:self.superview];
    CGPoint newCenter = CGPointMake(
        recognizer.view.center.x + translation.x,
        recognizer.view.center.y + translation.y
    );

    // Constrain to safe area
    CGFloat halfWidth = self.bounds.size.width / 2;
    CGFloat halfHeight = self.bounds.size.height / 2;

    newCenter.x = MAX(CGRectGetMinX(_safeArea) + halfWidth,
                      MIN(newCenter.x, CGRectGetMaxX(_safeArea) + halfWidth));
    newCenter.y = MAX(CGRectGetMinY(_safeArea) + halfHeight,
                      MIN(newCenter.y, CGRectGetMaxY(_safeArea) + halfHeight));

    recognizer.view.center = newCenter;
    [recognizer setTranslation:CGPointZero inView:self.superview];
}

- (void)showAuthorInfo:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Show author info
        UIAlertController *alertController = [UIAlertController
            alertControllerWithTitle:@"Author Info"
            message:@"Name: Jaxktg\nRepo: https://github.com/Jaxktg/Keychain-destroyer\nMIT license"
            preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction
            actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault
            handler:nil];

        [alertController addAction:okAction];

        // Present the alert from the top view controller
        UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        }
        [topViewController presentViewController:alertController animated:YES completion:nil];
    }
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
            secClass, (__bridge id)kSecClass,
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

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    // Ensure the button is added only once
    [KeychainDeletionButton showFloatingButton];
}

%end
