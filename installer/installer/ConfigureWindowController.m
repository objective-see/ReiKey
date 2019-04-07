//
//  ConfigureWindowController.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/31/18
//  Copyright (c) 2018 Objective-See. All rights reserved.
//

#import "Consts.h"
#import "Logging.h"
#import "Configure.h"
#import "Utilities.h"
#import "ConfigureWindowController.h"

#import <Quartz/Quartz.h>

@implementation ConfigureWindowController

@synthesize statusMsg;
@synthesize moreInfoButton;

//automatically called when nib is loaded
// ->just center window
-(void)awakeFromNib
{
    //center
    [self.window center];

    return;
}

//configure window/buttons
-(void)configure
{
    //set window title
    [self window].title = [NSString stringWithFormat:@"version %@", getAppVersion()];
    
    //init status msg
    [self.statusMsg setStringValue:@"scan, detect, and monitor keyboard taps!"];
        
    //enable 'uninstall'
    // when app is installed already
    if(YES == isInstalled())
    {
        //enable
        self.uninstallButton.enabled = YES;
    }
    //otherwise disable
    else
    {
        //disable
        self.uninstallButton.enabled = NO;
    }
    
    //make 'install' have focus
    // more likely they'll be upgrading, but do after a delay so it sticks...
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        //set responder
       [self.window makeFirstResponder:self.installButton];
        
    });

    //set delegate
    [self.window setDelegate:self];

    return;
}

//display (show) window
// center, make front, set bg to white, etc
-(void)display
{
    //indicated title bar is tranparent (too)
    self.window.titlebarAppearsTransparent = YES;
    
    //center window
    [[self window] center];
    
    //show (now configured) windows
    [self showWindow:self];
    
    //make it key window
    [self.window makeKeyAndOrderFront:self];
    
    //make window front
    [NSApp activateIgnoringOtherApps:YES];
    
    //not in dark mode?
    // make window white
    if(YES != isDarkMode())
    {
        //make white
        self.window.backgroundColor = NSColor.whiteColor;
    }
    
    return;
}

//button handler for (all) buttons
-(IBAction)buttonHandler:(id)sender
{
    //button title
    NSString* buttonTitle = nil;
    
    //extact button title
    buttonTitle = ((NSButton*)sender).title;
    
    //action
    NSUInteger action = 0;
    
    //dbg msg
    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"handling action click: %@", buttonTitle]);
    
    //Close/No?
    // close window and bail
    if( (YES == [buttonTitle isEqualToString:UI_NO]) ||
        (YES == [buttonTitle isEqualToString:UI_CLOSE]) )
    {
        //close
        [self.window close];
        
        //bail
        goto bail;
    }
    
    //Next >>?
    // show 'support us' view
    if(YES == [buttonTitle isEqualToString:UI_NEXT])
    {
        //frame
        NSRect frame = {0};
        
        //unset window title
        self.window.title = @"";
        
        //get main window's frame
        frame = self.window.contentView.frame;
        
        //set origin to 0/0
        frame.origin = CGPointZero;
        
        //increase y offset
        frame.origin.y += 5;
        
        //reduce height
        frame.size.height -= 5;
        
        //pre-req
        [self.supportView setWantsLayer:YES];
        
        //update overlay to take up entire window
        self.supportView.frame = frame;
        
        //not in dark mode?
        // make window white
        if(YES != isDarkMode())
        {
            //make white
            self.supportView.layer.backgroundColor = NSColor.whiteColor.CGColor;
        }
        //otherwise
        // match window's color
        else
        {
            //match window
            self.supportView.layer.backgroundColor = self.window.backgroundColor.CGColor;
        }
    
        //nap for UI purposes
        [NSThread sleepForTimeInterval:0.10f];
        
        //add to main window
        [self.window.contentView addSubview:self.supportView];
        
        //show
        self.supportView.hidden = NO;
        
        //make 'yes!' button active
        [self.window makeFirstResponder:self.supportButton];
        
        //bail
        goto bail;
    }
    
    //'Yes' for support
    // load patreon URL in browser
    if(YES == [buttonTitle isEqualToString:UI_YES])
    {
        //open URL
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:PATREON_URL]];
        
        //close
        [self.window close];
        
        //bail
        goto bail;
    }
    
    //install/uninstall logic handlers
    else
    {
        //hide 'get more info' button
        self.moreInfoButton.hidden = YES;
        
        //set action
        // install daemon
        if(YES == [buttonTitle isEqualToString:UI_INSTALL])
        {
            //set
            action = ACTION_INSTALL;
            
            //set upgrade flag here
            if(YES == isInstalled())
            {
                //set flag
                self.isUpgrade = YES;
            }
        }
        //set action
        // uninstall daemon
        else
        {
            //set
            action = ACTION_UNINSTALL;
        }
        
        //disable 'x' button
        // don't want user killing app during install/upgrade
        [[self.window standardWindowButton:NSWindowCloseButton] setEnabled:NO];
        
        //clear status msg
        [self.statusMsg setStringValue:@""];
        
        //force redraw of status msg
        // sometime doesn't refresh (e.g. slow VM)
        [self.statusMsg setNeedsDisplay:YES];
        
        //invoke logic to install/uninstall
        // do in background so UI doesn't block
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
            //install/uninstall
            [self lifeCycleEvent:action];
            
        });
    }
    
bail:

    return;
}

//button handler for '?' button (on an error)
// load documentation for error(s) in default browser
-(IBAction)info:(id)sender
{
    //open URL
    // invokes user's default browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ERRORS_URL]];
    
    return;
}

//perform install | uninstall via control obj
// invoked on background thread so that UI doesn't block
-(void)lifeCycleEvent:(NSUInteger)event
{
    //status var
    BOOL status = NO;
    
    //configure object
    Configure* configureObj = nil;
    
    //alloc control object
    configureObj = [[Configure alloc] init];
    
    //begin event
    // ->updates ui on main thread
    dispatch_sync(dispatch_get_main_queue(),
    ^{
        //complete
        [self beginEvent:event];
    });
    
    //sleep
    // allow 'install' || 'uninstall' msg to show up
    [NSThread sleepForTimeInterval:1.0f];
    
    //perform action (install | uninstall)
    // perform background (non-UI) actions...
    if(YES == [configureObj configure:event])
    {
        //set flag
        status = YES;
    }
    
    //error occurred
    else
    {
        //set flag
        status = NO;
    }
    
    //complet event
    // updates ui on main thread
    dispatch_async(dispatch_get_main_queue(),
    ^{
        //complete
        [self completeEvent:status event:event];
    });
    
    return;
}

//begin event
// ->basically just update UI
-(void)beginEvent:(NSUInteger)event
{
    //align text left
    [self.statusMsg setAlignment:NSLeftTextAlignment];
    
    //install msg
    if(ACTION_INSTALL == event)
    {
        //update status msg
        // with space to avoid spinner
        [self.statusMsg setStringValue:@"\t  Installing..."];
    }
    //uninstall msg
    else
    {
        //update status msg
        // with space to avoid spinner
        [self.statusMsg setStringValue:@"\t  Uninstalling..."];
    }
    
    //disable action button
    self.uninstallButton.enabled = NO;
    
    //disable cancel button
    self.installButton.enabled = NO;
    
    //show spinner
    [self.activityIndicator setHidden:NO];
    
    //start spinner
    [self.activityIndicator startAnimation:nil];
    
    return;
}

//complete event
// update UI after background event has finished
-(void)completeEvent:(BOOL)success event:(NSUInteger)event
{
    //action
    NSString* action = nil;
    
    //result msg
    NSMutableString* resultMsg = nil;
    
    //msg font
    NSColor* resultMsgColor = nil;
    
    //generally want centered text
    [self.statusMsg setAlignment:NSCenterTextAlignment];
    
    //set action msg for install
    if(ACTION_INSTALL == event)
    {
        //set msg
        action = @"install";
    }
    //set action msg for uninstall
    else
    {
        //set msg
        action = @"uninstall";
    }
    
    //success
    if(YES == success)
    {
        //set result msg
        resultMsg = [NSMutableString stringWithFormat:@"ReiKey %@ed!", action];
        
        //reset
        resultMsgColor = NSColor.controlTextColor;
    }
    //failure
    else
    {
        //set result msg
        resultMsg = [NSMutableString stringWithFormat:@"error: %@ failed", action];
        
        //set font to red
        resultMsgColor = [NSColor redColor];
        
        //show 'get more info' button
        self.moreInfoButton.hidden = NO;
    }
    
    //stop/hide spinner
    [self.activityIndicator stopAnimation:nil];
    
    //hide spinner
    [self.activityIndicator setHidden:YES];
    
    //set font to bold
    [self.statusMsg setFont:[NSFont fontWithName:@"Menlo-Bold" size:13]];
    
    //set msg color
    [self.statusMsg setTextColor:resultMsgColor];
    
    //set status msg
    [self.statusMsg setStringValue:resultMsg];
    
    //update button
    // after install change button to 'Next', unless error
    if(ACTION_INSTALL == event)
    {
        //error
        // set button to 'close'
        if(YES != success)
        {
            //set button title
            self.installButton.title = UI_CLOSE;
        }
        
        //install ok
        // set button to 'next'
        else
        {
            //set button title
            self.installButton.title = UI_NEXT;
        }
    
        //enable
        self.installButton.enabled = YES;
        
        //make it active
        [self.window makeFirstResponder:self.installButton];
    }
    //update button
    // after uninstall change butter to 'close'
    else
    {
        //set button title to 'close'
        self.uninstallButton.title = UI_CLOSE;
        
        //enable
        self.uninstallButton.enabled = YES;
        
        //make it active
        [self.window makeFirstResponder:self.uninstallButton];
    }

    //ok to re-enable 'x' button
    [[self.window standardWindowButton:NSWindowCloseButton] setEnabled:YES];
    
    //(re)make window window key
    [self.window makeKeyAndOrderFront:self];
    
    //(re)make window front
    [NSApp activateIgnoringOtherApps:YES];
    
    return;
}

//automatically invoked when window is closing
// on install, launch main app (to trigger welcome screen)
-(void)windowWillClose:(NSNotification *)notification
{
    //dbg msg
    logMsg(LOG_DEBUG, @"window closing...");
    
    //launch main app?
    if( (YES == isInstalled()) &&
        (YES != self.isUpgrade) )
    {
        //dbg msg
        logMsg(LOG_DEBUG, @"install, so kicking off main app to show welcome screen");
        
        //in background
        // launch main app, then exit
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
            //nap
            [NSThread sleepForTimeInterval:1.0f];
            
            //launch
            startApplication([NSURL fileURLWithPath:appPath()], NSWorkspaceLaunchDefault);
            
            //exit
            [NSApp terminate:self];
        });
    }
    
    //otherwise just exit
    else
    {
        //exit
        [NSApp terminate:self];
    }

    return;
}

@end
