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
#import "utilities.h"
#import "AppDelegate.h"

@implementation AppDelegate

@synthesize scanWindowController;
@synthesize aboutWindowController;
@synthesize prefsWindowController;
@synthesize welcomeWindowController;

//center window
// and make front
-(void)awakeFromNib
{
    //center
    [self.window center];
    
    //make it key window
    [self.window makeKeyAndOrderFront:self];
    
    //make window front
    [NSApp activateIgnoringOtherApps:YES];
    
    return;
}

//main app interface
// init user interface, etc...
-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //dbg msg
    logMsg(LOG_DEBUG, @"main (rules/pref) app launched");
    
    //toggle away
    [[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.loginwindow"] firstObject] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    
    //toggle back
    // work-around for menu not showing since we set Application is agent(UIElement): YES
    [[[NSRunningApplication runningApplicationsWithBundleIdentifier:APP_BUNDLE_ID] firstObject] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    
    //when launched via URL handler
    // no need to do anything here...
    if(YES == self.urlLaunch)
    {
        //all set
        goto bail;
    }

    //first time run?
    // show welcome window(s)
    if(YES != [[[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME] boolForKey:SHOWED_SPLASH])
    {
        //show welcome
        [self showWelcome];
    }
    
    //subsequent run(s)
    // default to showing scan window
    else
    {
        //show scan window
        [self showScan:nil];
        
        //if needed
        // start login item
        if(nil == [[NSRunningApplication runningApplicationsWithBundleIdentifier:LOGIN_ITEM_BUNDLE_ID] firstObject])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^{
                //start
                startApplication([NSURL fileURLWithPath:loginItemPath()], NSWorkspaceLaunchWithoutActivation);
            });
        }
    }

bail:
    
    return;
}

//(custom) url handler
// invoked automatically when user clicks on menu item in login item
-(void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls
{
    //url components
    NSURLComponents *components = nil;
    
    //tap ID
    NSNumber* tapID = nil;
    
    //set flag
    self.urlLaunch = YES;
    
    //parse each url
    // scan or show prefs...
    for(NSURL* url  in urls)
    {
        //show scan?
        if(YES == [url.host isEqualToString:@"scan"])
        {
            //split
            components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            
            //parse
            // find/extract tap id
            for(NSURLQueryItem *item in components.queryItems)
            {
                //tap id?
                if(YES == [item.name isEqualToString:TAP_ID])
                {
                    //extract tap id
                    tapID = [NSNumber numberWithInteger:item.value.integerValue];
                    
                    //done
                    break;
                }
            }
            
            //show
            [self showScan:tapID];
        }
        
        //show preferences?
        else if(YES == [url.host isEqualToString:@"preferences"])
        {
            //show
            [self showPreferences:nil];
        }
    }
    
    return;
}

//automatically close when user closes last window
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

//show welcome/splash view
-(void)showWelcome
{
    //disable all menu items except 'About ...'
    for(NSMenuItem* menuItem in NSApplication.sharedApplication.mainMenu.itemArray.firstObject.submenu.itemArray)
    {
        //not 'About ...'
        // disable menu item
        if(YES != [menuItem.title containsString:@"About"])
        {
            //disable
            menuItem.action = nil;
        }
    }
    
    //alloc welcome controller
    welcomeWindowController = [[WelcomeWindowController alloc] initWithWindowNibName:@"Welcome"];
    
    //center welcome window
    [self.welcomeWindowController.window center];
    
    //make key and front
    [self.welcomeWindowController.window makeKeyAndOrderFront:self];
    
    //set 'showed splash' key
    [[[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME] setBool:YES forKey:SHOWED_SPLASH];
    
    return;
}

//'Scan' menu item handler
// alloc and show scan window
-(IBAction)showScan:(id)sender
{
    //alloc rules window controller
    if(nil == self.scanWindowController)
    {
        //alloc
        scanWindowController = [[ScanWindowController alloc] initWithWindowNibName:@"Scan"];
    }
    
    //set tag id
    if( (nil != sender) &&
        (YES == [sender isKindOfClass:[NSNumber class]]) )
    {
        //set
        self.scanWindowController.tapID = sender;
    }
    //otherwise
    // reset tag id
    else
    {
        self.scanWindowController.tapID = nil;
    }
    
    //center
    [self.scanWindowController.window center];
    
    //show it
    [self.scanWindowController showWindow:self];
    
    //make it key window
    [[self.scanWindowController window] makeKeyAndOrderFront:self];
    
    //trigger scan
    [self.scanWindowController reScan:nil];
    
    return;
}

//'preferences' menu item handler
// alloc and show preferences window
-(IBAction)showPreferences:(id)sender
{
    //alloc prefs window controller
    if(nil == self.prefsWindowController)
    {
        //alloc
        prefsWindowController = [[PrefsWindowController alloc] initWithWindowNibName:@"Preferences"];
    }
    
    //center
    [self.prefsWindowController.window center];

    //show it
    [self.prefsWindowController showWindow:self];
    
    //make it key window
    [[self.prefsWindowController window] makeKeyAndOrderFront:self];
    
    return;
}

//'about' menu item handler
// ->alloc/show about window
-(IBAction)showAbout:(id)sender
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
    
    //invoke function in background that will make window modal
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //make modal
        makeModal(self.aboutWindowController);
        
    });
    
    return;
}

@end
