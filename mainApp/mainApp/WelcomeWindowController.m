//
//  file: WelcomeWindowController.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import "consts.h"
#import "logging.h"
#import "utilities.h"
#import "AppDelegate.h"
#import "WelcomeWindowController.h"

#define VIEW_WELCOME 0
#define VIEW_CONFIGURE 1
#define VIEW_FRIENDS 2
#define VIEW_CLOSE 3

@implementation WelcomeWindowController

@synthesize welcomeViewController;

//welcome!
-(void)windowDidLoad {
    
    //super
    [super windowDidLoad];
    
    //center
    [self.window center];
    
    //not in dark mode?
    // make window white
    if(YES != isDarkMode())
    {
        //make white
        self.window.backgroundColor = NSColor.whiteColor;
    }
    
    //when supported
    // indicate title bar is transparent (too)
    if(YES == [self.window respondsToSelector:@selector(titlebarAppearsTransparent)])
    {
        //set transparency
        self.window.titlebarAppearsTransparent = YES;
    }
    
    //show first view
    // 'welcome' ...blah blah
    [self buttonHandler:nil];

    return;
}

//button handler for all views
// show next view, sometimes, with view specific logic
-(IBAction)buttonHandler:(id)sender
{
    //shared defaults
    NSUserDefaults* sharedDefaults = nil;
    
    //prev view was config?
    // save user specified prefs
    if((VIEW_CONFIGURE+1) == ((NSToolbarItem*)sender).tag)
    {
        //load shared defaults
        sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME];
        
        //set 'start at login'
        [sharedDefaults setBool:(BOOL)self.startAtLogin.state forKey:PREF_START_AT_LOGIN];
        
        //set 'run with icon'
        [sharedDefaults setBool:(BOOL)self.runWithIcon.state forKey:PREF_RUN_WITH_ICON];
        
        //set 'ignore apple programs'
        [sharedDefaults setBool:(BOOL)self.ignoreAppleBinaries.state forKey:PREF_IGNORE_APPLE_BINS];

        //act on 'start at login'
        if(NSControlStateValueOn == self.startAtLogin.state)
        {
            //enable login item in background
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^{
                   //enable
                   if(YES != toggleLoginItem([NSURL fileURLWithPath:loginItemPath()], NSControlStateValueOn))
                   {
                       //err msg
                       logMsg(LOG_ERR, @"failed to toggle login item");
                   }
            });
        }
    }
    
    //set next view
    switch(((NSButton*)sender).tag)
    {
        //start:
        // show welcome
        case 0:
        {
            //remove prev. subview
            [[[self.window.contentView subviews] lastObject] removeFromSuperview];
            
            //set view
            [self.window.contentView addSubview:self.welcomeView];
            
            //make 'next' button first responder
            [self.window makeFirstResponder:[self.welcomeView viewWithTag:VIEW_CONFIGURE]];
        
            break;
        }
            
        //configure
        case VIEW_CONFIGURE:
        {
            //remove prev. subview
            [[[self.window.contentView subviews] lastObject] removeFromSuperview];
            
            //set view
            [self.window.contentView addSubview:self.configureView];
            
            //make 'next' button first responder
            [self.window makeFirstResponder:[self.configureView viewWithTag:VIEW_FRIENDS]];
            
            break;
        }
        
        //support
        case VIEW_FRIENDS:
        {
            //remove prev. subview
            [[[self.window.contentView subviews] lastObject] removeFromSuperview];
            
            //set view
            [self.window.contentView addSubview:self.friendsView];
            
            //make 'close' button first responder
            [self.window makeFirstResponder:[self.friendsView viewWithTag:VIEW_CLOSE]];
            
            break;
        }
            
        //close
        case VIEW_CLOSE:
            
            //hide window
            [self.window orderOut:self];
            
            //in background
            // start login item, then exit installer
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^{
                //start login item
                startApplication([NSURL fileURLWithPath:loginItemPath()], NSWorkspaceLaunchWithoutActivation);
                
                //exit
                [NSApp terminate:nil];
            });
            
        default:
            
            break;
    }

    return;
}

@end
