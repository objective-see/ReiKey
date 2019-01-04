//
//  main.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/31/18
//  Copyright (c) 2018 Objective-See. All rights reserved.
//

#import "main.h"
#import "consts.h"
#import "logging.h"
#import "utilities.h"
#import "Configure.h"
#import <Cocoa/Cocoa.h>

//main interface
int main(int argc, const char * argv[])
{
    //status
    int status = -1;
    
    //init crash reporting
    initCrashReporting();
    
    //cmdline install?
    if(YES == [[[NSProcessInfo processInfo] arguments] containsObject:CMD_INSTALL])
    {
        //dbg msg
        logMsg(LOG_DEBUG, @"performing commandline install");
        
        //install
        if(YES != [[[Configure alloc] init] configure:ACTION_INSTALL])
        {
            //err msg
            printf("\nREIKEY ERROR: install failed\n\n");
            
            //bail
            goto bail;
        }
        
        //dbg msg
        printf("REIKEY: install ok\n\n");
        
        //happy
        status = 0;
        
        //done
        goto bail;
    }
    
    //cmdline uninstall?
    else if(YES == [[[NSProcessInfo processInfo] arguments] containsObject:CMD_UNINSTALL])
    {
        //dbg msg
        logMsg(LOG_DEBUG, @"performing commandline uninstall");
        
        //install
        if(YES != [[[Configure alloc] init] configure:ACTION_UNINSTALL])
        {
            //err msg
            printf("\nREIKEY ERROR: uninstall failed\n\n");
            
            //bail
            goto bail;
        }
        
        //dbg msg
        printf("REIKEY: uninstall ok!\n\n");
        
        //happy
        status = 0;
        
        //done
        goto bail;
    }
    
    //default run mode
    // just kick off main app logic
    status = NSApplicationMain(argc,  (const char **) argv);
    
bail:
    
    return status;
}
