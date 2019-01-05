//
//  Configure.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/31/18.
//  Copyright (c) 2018 Objective-See. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>

#import "consts.h"
#import "logging.h"
#import "utilities.h"
#import "Configure.h"

@implementation Configure

//invokes appropriate install || uninstall logic
-(BOOL)configure:(NSUInteger)parameter
{
    //return var
    BOOL wasConfigured = NO;
    
    //upgrade flag
    BOOL isUpgrade = NO;

    //install
    if(ACTION_INSTALL == parameter)
    {
        //dbg msg
        logMsg(LOG_DEBUG, @"installing...");
        
        //if already installed though
        // uninstall everything first...
        if(YES == isInstalled())
        {
            //set upgrade flag
            isUpgrade = YES;
            
            //dbg msg
            logMsg(LOG_DEBUG, @"already installed, so stopping/uninstalling...");
            
            //stop
            // kill main app/login item
            [self stop];
            
            //uninstall
            // but do partial (leave prefs)
            if(YES != [self uninstall:UNINSTALL_PARTIAL])
            {
                //bail
                goto bail;
            }
            
            //dbg msg
            logMsg(LOG_DEBUG, @"uninstalled");
            
            //nap
            // give time for login item etc to be killed
            [NSThread sleepForTimeInterval:1.0];
        }
        
        //install
        if(YES != [self install])
        {
            //err msg
            logMsg(LOG_ERR, @"installation failed");
            
            //bail
            goto bail;
        }
        
        //upgrade?
        // start login item
        if(YES == isUpgrade)
        {
            //dbg msg
            logMsg(LOG_DEBUG, @"installed, now will start (login item)");
           
            //start
            if(YES != [self start])
            {
                //err msg
                logMsg(LOG_ERR, @"starting failed");
                
                //bail
                goto bail;
            }
        }
    }
    //uninstall
    // stops main app, login item and uninstalls
    else if(ACTION_UNINSTALL == parameter)
    {
        //dbg msg
        logMsg(LOG_DEBUG, @"stopping login item");
        
        //stop
        // kill app and login item
        [self stop];
         
        //dbg msg
        logMsg(LOG_DEBUG, @"uninstalling...");
        
        //uninstall
        if(YES != [self uninstall:UNINSTALL_FULL])
        {
            //bail
            goto bail;
        }
        
        //dbg msg
        logMsg(LOG_DEBUG, @"uninstalled!");
    }

    //no errors
    wasConfigured = YES;
    
bail:
    
    return wasConfigured;
}

//install
// copy to /Applications
-(BOOL)install
{
    //return/status var
    BOOL wasInstalled = NO;
    
    //error
    NSError* error = nil;
    
    //path to app (src)
    NSString* appPathSrc = nil;
    
    //path to app (dest)
    NSString* appPathDest = nil;
    
    //set src path
    // orginally stored in installer app's /Resource bundle
    appPathSrc = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:APP_NAME];
    
    //set dest path
    appPathDest = appPath();
    
    //user install
    // make sure ~/Applications exist
    if( (0 != geteuid()) &&
        (YES != [[NSFileManager defaultManager] fileExistsAtPath:[USER_APPS_FOLDER stringByExpandingTildeInPath]]) )
    {
        //create it
        if(YES != [[NSFileManager defaultManager] createDirectoryAtPath:[USER_APPS_FOLDER stringByExpandingTildeInPath] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            //err msg
            logMsg(LOG_ERR, [NSString stringWithFormat:@"failed to create %@ (%@)", [USER_APPS_FOLDER stringByExpandingTildeInPath], error]);
            
            //bail
            goto bail;
        }
        
        //dbg msg
        logMsg(LOG_DEBUG, [NSString stringWithFormat:@"created %@", [USER_APPS_FOLDER stringByExpandingTildeInPath]]);
    }
        
    //move app to its destination
    if(YES != [[NSFileManager defaultManager] copyItemAtPath:appPathSrc toPath:appPathDest error:&error])
    {
        //err msg
        logMsg(LOG_ERR, [NSString stringWithFormat:@"failed to copy %@ -> %@ (%@)", appPathSrc, appPathDest, error]);
        
        //bail
        goto bail;
    }

    //dbg msg
    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"copied %@ -> %@", appPathSrc, appPathDest]);
    
    //remove xattrs
    execTask(XATTR, @[@"-cr", appPathDest], YES);
    
    //dbg msg
    logMsg(LOG_DEBUG, @"removed xattr");
    
    //no error
    wasInstalled = YES;
    
bail:
    
    return wasInstalled;
}

//start login item
-(BOOL)start
{
    //login item
    NSString* loginItem = nil;
    
    //init path
    loginItem = [appPath() stringByAppendingPathComponent:[NSString stringWithFormat:@"/Contents/Library/LoginItems/%@.app", LOGIN_ITEM_NAME]];
    
    return startApplication([NSURL fileURLWithPath:loginItem], NSWorkspaceLaunchWithoutActivation);

}

//stop
-(void)stop
{
    //kill main app
    execTask(KILL, @[[APP_NAME stringByDeletingPathExtension]], YES);
    
    //kill login item
    execTask(KILL, @[LOGIN_ITEM_NAME], YES);
    
    return;
}

//uninstall
// delete app, remove login item, etc
-(BOOL)uninstall:(NSUInteger)type
{
    //return/status var
    BOOL wasUninstalled = NO;
    
    //status var
    // since want to try (most) uninstall steps, but record if any fail
    BOOL bAnyErrors = NO;
    
    //path to installed app
    NSString* installedAppPath = nil;
    
    //path to login item
    NSString* installedLoginItem = nil;
    
    //error
    NSError* error = nil;
    
    //init path to installed app
    installedAppPath = appPath();
    
    //init path to login item
    installedLoginItem = [installedAppPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/Contents/Library/LoginItems/%@.app", LOGIN_ITEM_NAME]];
    
    //delete app
    if(YES != [[NSFileManager defaultManager] removeItemAtPath:installedAppPath error:&error])
    {
        //err msg
        logMsg(LOG_ERR, [NSString stringWithFormat:@"failed to delete app %@ (%@)", installedAppPath, error]);
        
        //set flag
        bAnyErrors = YES;
        
        //keep uninstalling...
    }
    
    //unregister login item
    // don't care about error, cuz it might not be there (user prefs)
    toggleLoginItem([NSURL fileURLWithPath:installedLoginItem], ACTION_UNINSTALL);
    
    //full uninstall?
    // also remove preferences
    if(UNINSTALL_FULL == type)
    {
        //dbg msg
        logMsg(LOG_DEBUG, @"full uninstall, so also deleting preferenences, etc...");
        
        //delete app prefs
        [[NSFileManager defaultManager] removeItemAtPath:[[@"~/Library/Containers/" stringByAppendingPathComponent:APP_BUNDLE_ID] stringByExpandingTildeInPath] error:&error];
        
        //delete login item prefs
        [[NSFileManager defaultManager] removeItemAtPath:[[@"~/Library/Containers/" stringByAppendingPathComponent:LOGIN_ITEM_BUNDLE_ID] stringByExpandingTildeInPath] error:&error];
        
        //force remove preferences
        //[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:SUITE_NAME];
        [[[NSUserDefaults alloc] initWithSuiteName:SUITE_NAME] removePersistentDomainForName:SUITE_NAME];
    
    }
    
    //only success when there were no errors
    if(YES != bAnyErrors)
    {
        //happy
        wasUninstalled = YES;
    }

bail:

    return wasUninstalled;
}

@end
