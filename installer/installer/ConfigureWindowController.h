//
//  ConfigureWindowController.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/31/18
//  Copyright (c) 2018 Objective-See. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ConfigureWindowController : NSWindowController <NSWindowDelegate>
{
    
}

/* PROPERTIES */
@property (weak) IBOutlet NSView *installView;
@property (weak) IBOutlet NSProgressIndicator *activityIndicator;
@property (weak) IBOutlet NSTextField *statusMsg;
@property (weak) IBOutlet NSButton *installButton;
@property (weak) IBOutlet NSButton *uninstallButton;
@property (weak) IBOutlet NSButton *moreInfoButton;
@property (weak) IBOutlet NSButton *supportButton;
@property (strong) IBOutlet NSView *supportView;

//upgrade flag
@property BOOL isUpgrade;

/* METHODS */

//install/uninstall button handler
-(IBAction)buttonHandler:(id)sender;

//(more) info button handler
-(IBAction)info:(id)sender;

//configure window/buttons
-(void)configure;

//display (show) window
-(void)display;

@end
