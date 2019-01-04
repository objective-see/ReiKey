//
//  AppDelegate.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/31/18
//  Copyright (c) 2018 Objective-See. All rights reserved.
//

#import "consts.h"
#import "Configure.h"
#import "utilities.h"
#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

@synthesize aboutWindowController;
@synthesize configureWindowController;

//main app interface
// just show configure window...
-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //alloc/init config
    configureWindowController = [[ConfigureWindowController alloc] initWithWindowNibName:@"ConfigureWindowController"];
    
    //indicated title bar is tranparent (too)
    self.configureWindowController.window.titlebarAppearsTransparent = YES;
    
    //display it
    // call this first to so that outlets are connected
    [self.configureWindowController display];
    
    //configure it
    [self.configureWindowController configure];
    
    return;
}

//automatically invoked when user clicks 'About/Info'
-(IBAction)about:(id)sender
{
    //alloc/init settings window
    if(nil == self.aboutWindowController)
    {
        //alloc/init
        aboutWindowController = [[AboutWindowController alloc] initWithWindowNibName:@"AboutWindow"];
    }
    
    //center window
    [[self.aboutWindowController window] center];
    
    //show it
    [self.aboutWindowController showWindow:self];
    
    return;
}

@end
