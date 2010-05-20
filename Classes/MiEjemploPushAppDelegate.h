//
//  MiEjemploPushAppDelegate.h
//  MiEjemploPush
//
//  Created by Alberto Moraga on 13/05/10.
//  Copyright GotFeeling 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MiEjemploPushViewController;

@interface MiEjemploPushAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MiEjemploPushViewController *viewController;

	NSString *pushBadge;
	NSString *pushAlert;
	NSString *pushSound;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MiEjemploPushViewController *viewController;

@end

