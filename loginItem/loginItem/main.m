//
//  main.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Cocoa;

#import "consts.h"
#import "logging.h"
#import "utilities.h"

//main interface
// init crash reporting, check if running, launch
int main(int argc, const char * argv[])
{
    //return var
    int iReturn = -1;
    
    //init crash reporting
    initCrashReporting();
    
    //dbg msg
    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"starting login item (args: %@)", [[NSProcessInfo processInfo] arguments]]);
    
    //launch app normally
    iReturn = NSApplicationMain(argc, argv);
    
bail:
    
    return iReturn;
}
