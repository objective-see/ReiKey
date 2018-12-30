//
//  AppDelegate.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import "consts.h"
#import "Update.h"
#import "logging.h"
#import "EventTaps.h"
#import "utilities.h"
#import "AppDelegate.h"

@implementation AppDelegate

@synthesize updateWindowController;
@synthesize statusBarMenuController;

//app's main interface
// load status bar
-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //shared defaults
    NSUserDefaults* sharedDefaults = nil;
    
    //event tap obj
    EventTaps* eventTaps = nil;
    
    //dbg msg
    logMsg(LOG_DEBUG, @"starting login item");
    
    //alloc init event taps obj
    eventTaps = [[EventTaps alloc] init];

    //register notification listener for preferences changing...
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_PREFS_CHANGED object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification)
    {
        //handle
        [self preferencesChanged];
        
    }];
    
    //load shared defaults
    sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME];

    //run w/ status bar icon?
    if(YES == [sharedDefaults boolForKey:PREF_RUN_WITH_ICON])
    {
        //alloc/load status bar icon/menu
        // will configure, and show popup/menu
        statusBarMenuController = [[StatusBarMenu alloc] init:self.statusMenu];
        
        //dbg msg
        logMsg(LOG_DEBUG, @"initialized/loaded status bar (icon/menu)");
    }
    
    //automatically check for updates?
    if(YES != [sharedDefaults boolForKey:PREF_NO_UPDATES])
    {
        //after a 30 seconds
        // check for updates in background
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
           //dbg msg
           logMsg(LOG_DEBUG, @"checking for update");
           
           //check
           [self check4Update];
           
       });
    }
    
    //in background
    // listen for new event taps
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
    ^{
        //start listening
        // show alert when new tap detected
        // ...unless user has disabled the app
        [eventTaps observe:^(NSDictionary* tap)
        {
            //enabled?
            // show alert
            if(YES != [[[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME] boolForKey:PREF_IS_DISABLED])
            {
                //alert
                [self showAlert:tap];
            }
        }];
    });
    
    return;
}

//preferences changed
// for now, just check status bar icon setting
-(void)preferencesChanged
{
    //should run with icon?
    // init status bar, and show button
    if(YES == [[[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME] boolForKey:PREF_RUN_WITH_ICON])
    {
        //need to init?
        if(nil == self.statusBarMenuController)
        {
            //alloc/load status bar icon/menu
            // will configure, and show popup/menu
            statusBarMenuController = [[StatusBarMenu alloc] init:self.statusMenu];
        }
        
        //(always) show
        statusBarMenuController.statusItem.button.hidden = NO;
    }
    //run without icon
    // just hide button
    else
    {
        //hide
        statusBarMenuController.statusItem.button.hidden = YES;
    }
    
    return;
}

//show an alert
-(void)showAlert:(NSDictionary*)alert
{
    //notification
    NSUserNotification* notification = nil;

    //dbg msg
    logMsg(LOG_DEBUG, @"XPC request from daemon: alert show");
    
    //alloc notification
    notification = [[NSUserNotification alloc] init];
    
    //set action button
    notification.hasActionButton = YES;
    
    //set action button title
    notification.actionButtonTitle = @"Details";
    
    //set other button title
    notification.otherButtonTitle = @"Dismiss";

    //set title
    notification.title = @"⚠️ New Keyboard Event Tap";
    
    //set subtitle
    notification.subtitle = [NSString stringWithFormat:@"process: %@ (%@)", [((NSString*)alert[TAP_SOURCE_PATH]) lastPathComponent], alert[TAP_SOURCE_PID]];
    
    //add alert
    notification.userInfo = alert;
    
    //set delegate to self
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    //show alert on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //deliver notification
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        //TODO:
        // add touch bar support
        //[((AppDelegate*)[[NSApplication sharedApplication] delegate]) initTouchBar];
        
    });
    
    return;
}

//always present notifications
-(BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

//automatically invoked when user interacts w/ the notification popup
// launch main app, to scan & give more details about all event taps...
-(void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    //url
    NSURL* url = nil;
    
    //only want to process when user clicks on action button (i.e. "Details")
    if(NSUserNotificationActivationTypeActionButtonClicked != notification.activationType)
    {
        //ignore
        goto bail;
    }
    
    //init url
    url = [NSURL URLWithString:[NSString stringWithFormat:@"reikey://scan?%@=%@", TAP_ID, notification.userInfo[TAP_ID]]];
    
    //launch main app with 'scan' url
    // note: pass in tap id, so it can be selected in table
    [[NSWorkspace sharedWorkspace] openURL:url];
    
bail:

    return;
}

//call into Update obj
// check to see if there an update?
-(IBAction)check4Update
{
    //update obj
    Update* update = nil;
    
    //init update obj
    update = [[Update alloc] init];
    
    //check for update
    // ->'updateResponse newVersion:' method will be called when check is done
    [update checkForUpdate:^(NSUInteger result, NSString* newVersion) {
        
        //process response
        [self updateResponse:result newVersion:newVersion];
        
    }];
    
    return;
}

//process update response
// error, no update, update/new version
-(void)updateResponse:(NSInteger)result newVersion:(NSString*)newVersion
{
    //details
    NSString* details = nil;
    
    //action
    NSString* action = nil;
    
    //new version?
    if(UPDATE_NEW_VERSION == result)
    {
        //set details
        details = [NSString stringWithFormat:@"a new version (%@) is available!", newVersion];
        
        //set action
        action = @"Update";
        
        //alloc update window
        updateWindowController = [[UpdateWindowController alloc] initWithWindowNibName:@"UpdateWindow"];
        
        //configure
        [self.updateWindowController configure:details buttonTitle:action];
        
        //center window
        [[self.updateWindowController window] center];
        
        //show it
        [self.updateWindowController showWindow:self];
        
        //invoke function in background that will make window modal
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            //make modal
            makeModal(self.updateWindowController);
            
        });
    }
    
    return;
}

@end
