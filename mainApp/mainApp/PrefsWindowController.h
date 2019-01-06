//
//  PrefsWindowController.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Cocoa;

#import "UpdateWindowController.h"

/* CONSTS */

//to select, need string ID
#define TOOLBAR_GENERAL_ID @"General"

@interface PrefsWindowController : NSWindowController

/* PROPERTIES */

//toolbar
@property (weak) IBOutlet NSToolbar *toolbar;

//general prefs view
@property (strong) IBOutlet NSView *generalView;

//update prefs view
@property (strong) IBOutlet NSView *updateView;

//'start at login' button
@property (weak) IBOutlet NSButton *startAtLogin;

//'run with icon' button
@property (weak) IBOutlet NSButton *runWithIcon;

//'ignore apple programs' button
@property (weak) IBOutlet NSButton *ignoreAppleBinaries;

//disable automatic update check
@property (weak) IBOutlet NSButton *noUpdates;

//check for update button
@property (weak) IBOutlet NSButtonCell *updateButton;

//check for update activity indicator
@property (weak) IBOutlet NSProgressIndicator *updateIndicator;

//check for update label
@property (weak) IBOutlet NSTextField *updateLabel;

//update window controller
@property(nonatomic, retain)UpdateWindowController* updateWindowController;

/* METHODS */

//button handler for all preference buttons
-(IBAction)toggle:(id)sender;

@end
