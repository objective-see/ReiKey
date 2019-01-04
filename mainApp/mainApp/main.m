//
//  main.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/29/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Cocoa;

#import "main.h"
#import "consts.h"
#import "EventTaps.h"
#import "logging.h"
#import "utilities.h"

//main
// process cmdline args, show UI, etc
int main(int argc, const char * argv[])
{
    //return var
    int status = -1;
    
    //disable stderr
    // crash reporter dumps info here
    disableSTDERR();
    
    //init crash reporting
    // kicks off sentry.io
    initCrashReporting();
    
    //dbg msg
    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"starting main app (args: %@)", [[NSProcessInfo processInfo] arguments]]);
    
    //handle '-h' or '-help'
    if( (YES == [[[NSProcessInfo processInfo] arguments] containsObject:@"-h"]) ||
        (YES == [[[NSProcessInfo processInfo] arguments] containsObject:@"-help"]) )
    {
        //print usage
        usage();
        
        //done
        goto bail;
    }
    
    //handle '-scan'
    // cmdline scan without UI
    if(YES == [[[NSProcessInfo processInfo] arguments] containsObject:@"-scan"])
    {
        //scan
        cmdlineScan();
        
        //happy
        status = 0;
        
        //done
        goto bail;
    }
    
    //running non-cmdline mode
    // so, make foreground so app has an dock icon, etc
    transformApp(kProcessTransformToForegroundApplication);
    
    //launch app normally
    status = NSApplicationMain(argc, argv);
    
bail:
    
    return status;
}

//print usage
void usage()
{
    //usage
    printf("\nREIKEY USAGE:\n");
    printf(" -h or -help  display this usage info\n");
    printf(" -scan        enumerate all keyboard event taps\n");
    printf(" -pretty      during command line scan, JSON output is 'pretty-printed'\n\n");

    return;
}

//perform a cmdline scan
void cmdlineScan()
{
    //event taps
    NSArray* eventTaps = nil;
    
    //output
    NSMutableString* output = nil;
    
    //scan
    eventTaps = [[[[EventTaps alloc] init] enumerate] allValues];

    //init output string
    output = [NSMutableString string];
    
    //start JSON
    [output appendString:@"["];
    
    //add each tap
    for(NSDictionary* eventTap in eventTaps)
    {
        [output appendFormat:@"{\"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\", \"%@\": \"%@\"},", TAP_ID, eventTap[TAP_ID], TAP_SOURCE_PID, eventTap[TAP_SOURCE_PID], TAP_SOURCE_PATH, eventTap[TAP_SOURCE_PATH], TAP_DESTINATION_PID, eventTap[TAP_DESTINATION_PID], TAP_DESTINATION_PATH, eventTap[TAP_DESTINATION_PATH]];
    }
    
    //remove last ','
    if(YES == [output hasSuffix:@","])
    {
        //remove
        [output deleteCharactersInRange:NSMakeRange([output length]-1, 1)];
    }
    
    //terminate list
    [output appendString:@"]"];
    
    //pretty print?
    if(YES == [[[NSProcessInfo processInfo] arguments] containsObject:@"-pretty"])
    {
        //make me pretty!
        printf("%s\n", prettifyJSON(output).UTF8String);
    }
    else
    {
        //output
        printf("%s\n", output.UTF8String);
    }
    
    return;
}
