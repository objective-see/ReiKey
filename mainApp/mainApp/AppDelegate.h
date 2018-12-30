//
//  AppDelegate.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Cocoa;

#import "ScanWindowController.h"
#import "AboutWindowController.h"
#import "PrefsWindowController.h"
#import "WelcomeWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

/* PROPERTIES */

//main window
@property(weak)IBOutlet NSWindow* window;

//welcome view controller
@property(nonatomic, retain)WelcomeWindowController* welcomeWindowController;

//about window controller
@property(nonatomic, retain)AboutWindowController* aboutWindowController;

//scan window controller
@property(nonatomic, retain)ScanWindowController* scanWindowController;

//preferences window controller
@property(nonatomic, retain)PrefsWindowController* prefsWindowController;

//flag for launch method
@property BOOL urlLaunch;

/* METHODS */

@end

