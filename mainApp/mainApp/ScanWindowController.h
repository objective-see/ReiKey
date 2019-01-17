//
//  ScanWindowController.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Cocoa;

#import "EventTaps.h"

/* CONSTS */

//id (tag) for detailed text in category table
#define TABLE_ROW_NAME_TAG 100

//id (tag) for detailed text in category table
#define TABLE_ROW_SUB_TEXT_TAG 101

//menu item for mute/unmute
#define MENU_ITEM_ACTION 0

//menu item for show in finder
#define MENU_ITEM_SHOW_IN_FINDER 1

/* INTERFACE */

@interface ScanWindowController : NSWindowController <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate>
{
    
}

/* PROPERTIES */

//event tap obj
@property(nonatomic, retain)EventTaps* eventTapsObj;

//(optional) tap id to select
@property(nonatomic, retain)NSNumber* tapID;

//event taps
// array used to populate table
@property(nonatomic, retain)NSMutableArray* eventTaps;

//refresh/rescan button
@property (weak) IBOutlet NSButton *rescan;

//'scanning' overlay
@property (weak) IBOutlet NSView *overlay;

//'scanning' activity indicator
@property (weak) IBOutlet NSProgressIndicator *activityIndicator;

//'scanning' activity message
@property (weak) IBOutlet NSTextField *activityMessage;

//scan results
@property (weak) IBOutlet NSTextField *scanResults;

//top level view
@property (weak) IBOutlet NSView *view;

//window toolbar
@property (weak) IBOutlet NSToolbar *toolbar;

//table view
@property (weak) IBOutlet NSTableView *tableView;

/* METHODS */

//(re)scan button handler
// can also call directly to trigger scan...
-(IBAction)reScan:(id)sender;

@end
