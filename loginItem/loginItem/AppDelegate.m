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
#import "signing.h"
#import "EventTaps.h"
#import "utilities.h"
#import "AppDelegate.h"

@implementation AppDelegate

@synthesize alerts;
@synthesize currentAlert;
@synthesize statusBarController;
@synthesize updateWindowController;

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
    
    //init alerts
    alerts = [NSMutableDictionary dictionary];

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
        statusBarController = [[StatusBarItem alloc] init:self.statusMenu];
        
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
        //prev tap
        __block NSDictionary* previousTap = nil;
        
        //signing info
        __block NSDictionary* signingInfo = nil;
        
        //start listening
        // show alert when new tap detected
        // ...unless user has disabled the app or same process
        [eventTaps observe:^(NSDictionary* tap)
        {
            //dbg msg
            logMsg(LOG_DEBUG, [NSString stringWithFormat:@"new keyboard event tap: %@", tap]);
            
            //disabled?
            if(YES == [[[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME] boolForKey:PREF_IS_DISABLED])
            {
                //dbg msg
                logMsg(LOG_DEBUG, @"ingoring alert: ReiKey is disabled");
                
                //ignore
                return;
            }
            
            //muted process?
            if(YES == [[[[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME] arrayForKey:MUTED_ITEMS] containsObject:tap[TAP_SOURCE_PATH]])
            {
                //dbg msg
                logMsg(LOG_DEBUG, @"ingoring alert: tapping process has been muted");
                
                //ignore
                return;
            }
        
            //seen before (for same proc)?
            previousTap = self.alerts[tap[TAP_SOURCE_PID]];
            if( (nil != previousTap) &&
                (YES == [getProcessPath([previousTap[TAP_SOURCE_PID] intValue]) isEqualToString:getProcessPath([tap[TAP_SOURCE_PID] intValue])]) )
            {
                //dbg msg
                logMsg(LOG_DEBUG, @"ingoring alert: tapping process has already generated an alert");
                
                //ignore
                return;
            }
            
            //ignore apple?
            // and tapping process is apple?
            if(YES == [[[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME] boolForKey:PREF_IGNORE_APPLE_BINS])
            {
                //generate signing info
                // first dynamically (via pid)
                signingInfo = extractSigningInfo([tap[TAP_SOURCE_PID] intValue], nil, kSecCSDefaultFlags);
                if(nil == signingInfo)
                {
                    //extract signing info statically
                    signingInfo = extractSigningInfo(0, tap[TAP_SOURCE_PATH], kSecCSCheckAllArchitectures | kSecCSCheckNestedCode | kSecCSDoNotValidateResources);
                }
                
                //ignore is signed by apple
                if( (noErr == [signingInfo[KEY_SIGNATURE_STATUS] intValue]) &&
                    (Apple == [signingInfo[KEY_SIGNATURE_SIGNER] intValue]) )
                {
                    //dbg msg
                    logMsg(LOG_DEBUG, @"ingoring alert: preference set ('apple ignore') and tapping process is signed by apple");
                    
                    //ignore
                    return;
                }
            }
        
            //ok, show alert!
            [self showAlert:tap];
            
            //add and remove any old/dead pids
            @synchronized(self.alerts)
            {
                //save
                self.alerts[tap[TAP_SOURCE_PID]] = tap;
                
                //enpunge dead procs
                for(NSDictionary* tapID in self.alerts.allKeys)
                {
                    //dead?
                    // remove
                    if(YES != isProcessAlive([self.alerts[tapID][TAP_SOURCE_PID] intValue]))
                    {
                        //remove
                        [self.alerts removeObjectForKey:tapID];
                    }
                }
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
        //already showing?
        if(nil != self.statusBarController)
        {
            //bail
            goto bail;
        }
        
        //alloc/load status bar icon/menu
        // will configure, and show popup/menu
        statusBarController = [[StatusBarItem alloc] init:self.statusMenu];
    }
    //run without icon
    // just hide button
    else
    {
        //already removed?
        if(nil == self.statusBarController)
        {
            //bail
            goto bail;
        }
        
        //remove status item
        [self.statusBarController removeStatusItem];
        
        //unset
        self.statusBarController = nil;
    }
    
bail:
    
    return;
}

//show an alert
-(void)showAlert:(NSDictionary*)alert
{
    //notification
    NSUserNotification* notification = nil;
    
    //dbg msg
    logMsg(LOG_DEBUG, @"showing alert to user");
    
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
    
    //save alert
    self.currentAlert = alert;
    
    //set delegate to self
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    //show alert on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //deliver notification
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        //touch bar support
        [self initTouchBar];
        
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
    
    //hide touchbar
    self.touchBar = nil;
    
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

//init/show touch bar
-(void)initTouchBar
{
    //touch bar items
    NSArray *touchBarItems = nil;
    
    //touch bar API is only 10.12.2+
    if(@available(macOS 10.12.2, *))
    {
        //alloc/init
        self.touchBar = [[NSTouchBar alloc] init];
        if(nil == self.touchBar)
        {
            //no touch bar?
            goto bail;
        }
        
        //set delegate
        self.touchBar.delegate = self;
        
        //set id
        self.touchBar.customizationIdentifier = @"com.objective-see.reikey";
        
        //init items
        touchBarItems = @[@".icon", @".label", @".dismiss", @".details"];
        
        //set items
        self.touchBar.defaultItemIdentifiers = touchBarItems;
        
        //set customization items
        self.touchBar.customizationAllowedItemIdentifiers = touchBarItems;
        
        //activate so touchbar shows up
        [NSApp activateIgnoringOtherApps:YES];
    }
    
bail:
    
    return;
}

//touch bar handler
-(IBAction)touchBarEventHandler:(id)sender
{
    //url
    NSURL* url = nil;
    
    //dimiss (all) notification
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    
    //show more details?
    if(ALERT_DETAILS == ((NSButton*)sender).tag)
    {
        //init url
        url = [NSURL URLWithString:[NSString stringWithFormat:@"reikey://scan?%@=%@", TAP_ID, self.currentAlert[TAP_ID]]];
        
        //launch main app with 'scan' url
        // note: pass in tap id, so it can be selected in table
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
    
    //unset
    // will hide touchbar
    self.touchBar = nil;
    
    return;
}


//delegate method
// init item for touch bar
-(NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    //icon view
    NSImageView *iconView = nil;
    
    //icon
    NSImage* icon = nil;
    
    //item
    NSCustomTouchBarItem *touchBarItem = nil;
    
    //init item
    touchBarItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:identifier];
    
    //icon
    if(YES == [identifier isEqualToString: @".icon" ])
    {
        //init icon view
        iconView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 30.0, 30.0)];
        
        //enable layer
        [iconView setWantsLayer:YES];
        
        //set color
        [iconView.layer setBackgroundColor:[[NSColor windowBackgroundColor] CGColor]];
        
        //mask
        iconView.layer.masksToBounds = YES;
        
        //round corners
        iconView.layer.cornerRadius = 3.0;
        
        //load icon image
        icon = [NSImage imageNamed:@"ReiKeyIcon"];
        
        //set size
        icon.size = CGSizeMake(30, 30);
        
        //add image
        iconView.image = icon;
        
        //set view
        touchBarItem.view = iconView;
    }
    
    //label
    else if(YES == [identifier isEqualToString:@".label"])
    {
        //item label
        touchBarItem.view = [NSTextField labelWithString:[NSString stringWithFormat:@"New Keyboard Event Tap: %@ (%@)", [((NSString*)self.currentAlert[TAP_SOURCE_PATH]) lastPathComponent], self.currentAlert[TAP_SOURCE_PID]]];
    }
    
    //dismiss button
    else if(YES == [identifier isEqualToString:@".dismiss"])
    {
        //init button
        touchBarItem.view = [NSButton buttonWithTitle: @"Dismiss" target:self action: @selector(touchBarEventHandler:)];
        
        //set 'dismiss' tag
        ((NSButton*)touchBarItem.view).tag = ALERT_DISMISS;
    }
    
    //allow button
    else if(YES == [identifier isEqualToString:@".details"])
    {
        //init button
        touchBarItem.view = [NSButton buttonWithTitle: @"Details" target:self action: @selector(touchBarEventHandler:)];
        
        //set 'details' tag
        ((NSButton*)touchBarItem.view).tag = ALERT_DETAILS;
    }
    
    return touchBarItem;
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
