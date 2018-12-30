//
//  PrefsWindowController.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>

#import "consts.h"
#import "Update.h"
#import "logging.h"
#import "utilities.h"
#import "AppDelegate.h"
#import "PrefsWindowController.h"

//general view
#define TOOLBAR_GENERAL 0

//update view
#define TOOLBAR_UPDATE 1

@implementation PrefsWindowController

@synthesize toolbar;
@synthesize updateLabel;
@synthesize updateButton;
@synthesize updateIndicator;
@synthesize updateWindowController;

//init 'general' view
// add it, and make it selected
-(void)awakeFromNib
{
    //shared defaults
    NSUserDefaults* sharedDefaults = nil;
    
    //load shared defaults
    sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME];
    
    //set title
    self.window.title = [NSString stringWithFormat:@"ReiKey (v. %@)", getAppVersion()];
    
    //set general prefs as default
    [self.toolbar setSelectedItemIdentifier:TOOLBAR_GENERAL_ID];
    
    //set general prefs as default
    [self toolbarButtonHandler:nil];
    
    //set 'start at login' button state
    self.startAtLogin.state = [sharedDefaults boolForKey:PREF_START_AT_LOGIN];
    
    //set 'run with icon' button state
    self.runWithIcon.state = [sharedDefaults boolForKey:PREF_RUN_WITH_ICON];
    
    //set 'disable update check' button state
    self.noUpdates.state = [sharedDefaults boolForKey:PREF_NO_UPDATES];
    
    return;
}

//toolbar view handler
// toggle view based on user selection
-(IBAction)toolbarButtonHandler:(id)sender
{
    //view
    NSView* view = nil;
    
    //shared defaults
    NSUserDefaults* sharedDefaults = nil;
    
    //load shared defaults
    sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME];
    
    //when we've prev added a view
    // remove the prev view cuz adding a new one
    if(nil != sender)
    {
        //remove
        [[[self.window.contentView subviews] lastObject] removeFromSuperview];
    }
    
    //assign view
    switch(((NSToolbarItem*)sender).tag)
    {
        //general
        case TOOLBAR_GENERAL:
        {
            //set view
            view = self.generalView;
            
            //set 'start at login' button state
            self.startAtLogin.state = [sharedDefaults boolForKey:PREF_START_AT_LOGIN];
            
            //set 'run with icon' button state
            self.runWithIcon.state = [sharedDefaults boolForKey:PREF_RUN_WITH_ICON];
            
            break;
        }
            
        //update
        case TOOLBAR_UPDATE:
        {
            //set view
            view = self.updateView;
            
            //set 'disable update check' button state
            self.noUpdates.state = [sharedDefaults boolForKey:PREF_NO_UPDATES];
            
            break;
        }
            
        default:
            return;
    }
    
    //set frame rect
    view.frame = CGRectMake(0, 0, self.window.contentView.frame.size.width, self.window.contentView.frame.size.height);
    
    //add to window
    [self.window.contentView addSubview:view];
    
    return;
}

//invoked when user toggles button
// update preferences for that button
-(IBAction)toggle:(id)sender
{
    //shared defaults
    NSUserDefaults* sharedDefaults = nil;

    //state
    NSInteger buttonState = NSControlStateValueOff;
    
    //load shared defaults
    sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME];
    
    //'start at login'
    // toggle login item state
    if(sender == self.startAtLogin)
    {
        //enable/disable
        //SMLoginItemSetEnabled((__bridge CFStringRef)LOGIN_ITEM, (Boolean)self.startAtLogin.state);
        
        //grab state
        // dispatch (below) execs code on bg
        buttonState = (NSInteger)self.startAtLogin.state;
        
        //toggle login item in background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
               //toggle
               if(YES != toggleLoginItem([NSURL fileURLWithPath:loginItemPath()], (int)buttonState))
               {
                   //err msg
                   logMsg(LOG_ERR, @"failed to toggle login item");
               }
        });
        
        //set 'start at login'
        [sharedDefaults setBool:(BOOL)self.startAtLogin.state forKey:PREF_START_AT_LOGIN];
        
        //sync defaults to save
        [sharedDefaults synchronize];

    }
    //'run with icon'
    // restart login item...
    else if(sender == self.runWithIcon)
    {
        //set 'run with icon'
        [sharedDefaults setBool:(BOOL)self.runWithIcon.state forKey:PREF_RUN_WITH_ICON];
        
        //sync defaults to save
        [sharedDefaults synchronize];
        
        //broadcast notification
        // tells login item to hide/show icon
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PREFS_CHANGED object:nil userInfo:nil deliverImmediately:YES];
    }
    
    //'disable update checks'
    // ...just set preference
    else if(sender == self.noUpdates)
    {
        //set 'run with icon'
        [sharedDefaults setBool:(BOOL)self.noUpdates.state forKey:PREF_NO_UPDATES];
        
        //sync defaults to save
        [sharedDefaults synchronize];
    }

    return;
}

//'check for update' button handler
-(IBAction)check4Update:(id)sender
{
    //update obj
    Update* update = nil;
    
    //disable button
    self.updateButton.enabled = NO;
    
    //reset
    self.updateLabel.stringValue = @"";
    
    //show/start spinner
    [self.updateIndicator startAnimation:self];
    
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
    //re-enable button
    self.updateButton.enabled = YES;
    
    //stop/hide spinner
    [self.updateIndicator stopAnimation:self];
    
    //handle response
    // new version, show popup
    switch(result)
    {
        //error
        case UPDATE_ERROR:
            
            //set label
            self.updateLabel.stringValue = @"error: update check failed";
            
            break;
            
        //no updates
        case UPDATE_NOTHING_NEW:
            
            //set label
            self.updateLabel.stringValue = @"no new versions";
            
            break;
            
        //new version
        case UPDATE_NEW_VERSION:
            
            //alloc update window
            updateWindowController = [[UpdateWindowController alloc] initWithWindowNibName:@"UpdateWindow"];
            
            //configure
            [self.updateWindowController configure:[NSString stringWithFormat:@"a new version (%@) is available!", newVersion] buttonTitle:@"update"];
            
            //center window
            [[self.updateWindowController window] center];
            
            //show it
            [self.updateWindowController showWindow:self];
            
            //invoke function in background that will make window modal
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                //make modal
                makeModal(self.updateWindowController);
                
            });
            
            break;
    }
    
    return;
}

@end
