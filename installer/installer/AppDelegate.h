//
//  AppDelegate.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/31/18.
//  Copyright (c) 2018 Objective-See. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AboutWindowController.h"
#import "ConfigureWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate>
{
    
}

/* PROPERTIES */

//about window controller
@property(nonatomic, retain)AboutWindowController* aboutWindowController;

//configure window controller
@property(nonatomic, retain)ConfigureWindowController* configureWindowController;

/* METHODS */

@end


