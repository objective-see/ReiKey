//
//  AppDelegate.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Cocoa;

#import "StatusBarMenu.h"
#import "UpdateWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate, NSTouchBarProvider, NSTouchBarDelegate>

/* METHODS */


/* PROPERTIES */

//status bar menu
@property(strong) IBOutlet NSMenu* statusMenu;

//status bar menu controller
@property(nonatomic, retain)StatusBarMenu* statusBarMenuController;

//touch bar
@property(nonatomic, retain)NSTouchBar* touchBar;

//update window controller
@property(nonatomic, retain)UpdateWindowController* updateWindowController;

//alerts
@property(nonatomic, retain)NSMutableDictionary* alerts;

/* METHODS */

@end
