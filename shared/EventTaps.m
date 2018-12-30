//
//  EventTaps.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import <notify.h>

#import "consts.h"
#import "utilities.h"
#import "EventTaps.h"

@implementation EventTaps

@synthesize previousTaps;

//init method
// set some intial flags, init daemon comms, etc.
-(id)init
{
    //super
    self = [super init];
    if(self != nil)
    {
        /*
        //alloc set
        currentTaps = [NSMutableSet set];
        
        //init current taps
        for(NSDictionary* tap in [self enumerate])
        {
            //add
            [currentTaps addObject:tap[@"tapID"]];
        }
        */
    }
 
    return self;
}

//enumerate event taps
// activated keyboard taps
-(NSMutableDictionary*)enumerate
{
    //keyboard taps
    NSMutableDictionary* keyboardTaps = nil;
    
    //event taps
    uint32_t eventTapCount = 0;
    
    //taps
    CGEventTapInformation *taps = NULL;
    
    //current tap
    CGEventTapInformation tap = {0};
    
    //key tap
    CGEventMask keyboardTap = CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventKeyDown);
    
    //tapping process
    NSString* sourcePath = nil;
    
    //target process
    NSString* destinationPath = nil;
    
    //options (type)
    NSString* options = nil;
    
    //alloc
    keyboardTaps = [NSMutableDictionary dictionary];
    
    //get number of existing taps
    if( (kCGErrorSuccess != CGGetEventTapList(0, NULL, &eventTapCount)) ||
        (0 == eventTapCount) )
    {
        //bail
        goto bail;
    }
    
    //alloc
    taps = malloc(sizeof(CGEventTapInformation) * eventTapCount);
    if(NULL == taps)
    {
        //bail
        goto bail;
    }
    
    //get all taps
    if(kCGErrorSuccess != CGGetEventTapList(eventTapCount, taps, &eventTapCount))
    {
        //bail
        goto bail;
    }
    
    //iterate/process all taps
    for(int i=0; i<eventTapCount; i++)
    {
        //current tap
        tap = taps[i];
        
        //ignore disabled taps
        // or non-keyboard taps
        if( (true != tap.enabled) ||
            ((keyboardTap & tap.eventsOfInterest) != keyboardTap) )
        {
            //skip
            continue;
        }
        
        //get path to tapping process
        sourcePath = getProcessPath(tap.tappingProcess);
        if(0 == sourcePath.length)
        {
            //default
            sourcePath = @"<unknown>";
        }
        
        //when target is 0
        // means all/system-wide
        if(0 == tap.processBeingTapped)
        {
            //set
            destinationPath = GLOBAL_EVENT_TAP;
        }
        //specific target
        // get path for target process
        else
        {
            //get path to target process
            destinationPath = getProcessPath(tap.processBeingTapped);
            if(0 == destinationPath.length)
            {
                //default
                destinationPath = @"<unknown>";
            }
        }
        
        //set option
        switch (tap.options)
        {
            //filter
            case kCGEventTapOptionDefault:
                options = @"Active filter";
                break;
                
            //listener
            case kCGEventTapOptionListenOnly:
                options = @"Passive listener";
                break;
                
            //unknown
            default:
                options = @"<unknown>";
                break;
        }
        
        //add
        keyboardTaps[@(tap.eventTapID)] = @{TAP_ID:@(tap.eventTapID), TAP_OPTIONS:options, TAP_SOURCE_PATH:sourcePath, TAP_SOURCE_PID:@(tap.tappingProcess), TAP_DESTINATION_PATH:destinationPath, TAP_DESTINATION_PID:@(tap.processBeingTapped)};
    }
    
bail:
    
    //free taps
    if(NULL != taps)
    {
        //free
        free(taps);
    }
    
    return keyboardTaps;
}

//listen for new taps
// note: method doesn't return!
-(void)observe:(TapCallbackBlock)callback;
{
    //token
    int notifyToken = NOTIFY_TOKEN_INVALID;
    
    //current taps
    // ...that include any news ones
    __block NSMutableDictionary* currentTaps = nil;
    
    //grab existing taps
    self.previousTaps = [self enumerate];
    
    //register 'kCGNotifyEventTapAdded' notification
    notify_register_dispatch(kCGNotifyEventTapAdded, &notifyToken, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(int token) {
        
        //grab current taps
        // ...should now include any new ones
        currentTaps = [self enumerate];
        
        //identify any new taps
        // invoke callback for those...
        for(NSNumber* tapID in currentTaps.allKeys)
        {
            //not new?
            if(nil != self.previousTaps[tapID])
            {
                //skip
                continue;
            }
            
            //new!
            callback(currentTaps[tapID]);
        }
        
        //update taps
        self.previousTaps = currentTaps;
        
    });

    //run loop
    [[NSRunLoop currentRunLoop] run];
    
    return;
}


@end
