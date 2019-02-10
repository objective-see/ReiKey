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
#import "logging.h"
#import "signing.h"
#import "EventTaps.h"
#import "utilities.h"

//main
// process cmdline args, show UI, etc
int main(int argc, const char * argv[])
{
    //return var
    int status = -1;
 
    //args
    NSArray* arguments = nil;
    
    //grab args
    arguments = [[NSProcessInfo processInfo] arguments];
    
    //disable stderr
    // crash reporter dumps info here
    disableSTDERR();
    
    //init crash reporting
    // kicks off sentry.io
    initCrashReporting();
    
    //dbg msg
    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"starting main app (args: %@)", [[NSProcessInfo processInfo] arguments]]);
    
    //handle '-h' or '-help'
    if( (YES == [arguments containsObject:@"-h"]) ||
        (YES == [arguments containsObject:@"-help"]) )
    {
        //print usage
        usage();
        
        //done
        goto bail;
    }
    
    //handle '-scan'
    // cmdline scan without UI
    if(YES == [arguments containsObject:@"-scan"])
    {
        //scan
        cmdlineScan();
        
        //happy
        status = 0;
        
        //done
        goto bail;
    }
    
    //handle invalid args
    // allow `-psn_` cuz OS sometimes adds this?
    if( (arguments.count > 1) &&
        (YES != [arguments[1] hasPrefix:@"-psn_"]) )
    {
        //print usage
        usage();
        
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
    printf(" -pretty      JSON output is 'pretty-printed' for readability\n");
    printf(" -skipApple   ignore event taps that belong to Apple processes \n\n");

    return;
}

//perform a cmdline scan
void cmdlineScan()
{
    //event taps
    NSMutableArray* eventTaps = nil;
    
    //current tap
    NSDictionary* eventTap = nil;
    
    //signing info
    NSDictionary* signingInfo = nil;
    
    //output
    NSMutableString* output = nil;
    
    //scan
    eventTaps = [[[[[EventTaps alloc] init] enumerate] allValues] mutableCopy];
    
    //ingore apple signed event taps?
    if(YES == [[[NSProcessInfo processInfo] arguments] containsObject:@"-skipApple"])
    {
        //remove any apple event taps
        // iterate backwards so we can enumerate and remove at same time
        for(NSInteger index = eventTaps.count-1; index >= 0; index--)
        {
            //tap
            eventTap = eventTaps[index];
            
            //generate signing info
            // first dynamically (via pid)
            signingInfo = extractSigningInfo([eventTap[TAP_SOURCE_PID] intValue], nil, kSecCSDefaultFlags);
            if(nil == signingInfo)
            {
                //extract signing info statically
                signingInfo = extractSigningInfo(0, eventTap[TAP_SOURCE_PATH], kSecCSCheckAllArchitectures | kSecCSCheckNestedCode | kSecCSDoNotValidateResources);
            }
            
            //ignore if signed by apple
            if( (noErr == [signingInfo[KEY_SIGNATURE_STATUS] intValue]) &&
                (Apple == [signingInfo[KEY_SIGNATURE_SIGNER] intValue]) )
            {
                //ignore
                [eventTaps removeObjectAtIndex:index];
            }
        }
    }

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
