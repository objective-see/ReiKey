//
//  EventTaps.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import <notify.h>

#import "consts.h"
#import "logging.h"
#import "signing.h"
#import "utilities.h"
#import "EventTaps.h"

@implementation EventTaps

@synthesize previousTaps;

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
    
    //key taps
    CGEventMask keyUpTap = CGEventMaskBit(kCGEventKeyUp);
    CGEventMask keyDownTap = CGEventMaskBit(kCGEventKeyDown);
    
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
            (((keyUpTap & tap.eventsOfInterest) != keyUpTap) &&
            ((keyDownTap & tap.eventsOfInterest) != keyDownTap)) )
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
        
        //unset
        taps = NULL;
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
    
    //signing info
    __block NSMutableDictionary* signingInfo = nil;
    
    //grab existing taps
    self.previousTaps = [self enumerate];
    
    //register 'kCGNotifyEventTapAdded' notification
    notify_register_dispatch(kCGNotifyEventTapAdded, &notifyToken, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(int token) {
        
        //sync to assure thread safety
        @synchronized(self)
        {
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
                
                //dbg msg
                logMsg(LOG_DEBUG, [NSString stringWithFormat:@"kCGNotifyEventTapAdded fired (new tap: %@)", currentTaps[tapID]]);
                
                //ignore taps from vmware
                // it creates a temporary event tap while one interacts with a VM
                if(YES == [[currentTaps[tapID][TAP_SOURCE_PATH] lastPathComponent] isEqualToString:@"vmware-vmx"])
                {
                    //generate signing info
                    // and make sure its vmware
                    signingInfo = extractSigningInfo([currentTaps[tapID][TAP_SOURCE_PID] intValue], nil, kSecCSDefaultFlags);
                    if( (nil != signingInfo) &&
                        (noErr == [signingInfo[KEY_SIGNATURE_STATUS] intValue]) &&
                        (DevID == [signingInfo[KEY_SIGNATURE_SIGNER] intValue]) &&
                        (YES == [signingInfo[KEY_SIGNATURE_IDENTIFIER] isEqualToString:@"com.vmware.vmware-vmx"]) )
                    {
                        //dbg msg
                        logMsg(LOG_DEBUG, @"ingoring alert: 'com.vmware.vmware-vmx'");
                        
                        //skip
                        continue;
                    }
                }

                //just nap a bit
                // some notifications seem temporary
                else
                {
                    //wait a few seconds and recheck
                    // some notifications seem temporary (i.e. vmware)
                    [NSThread sleepForTimeInterval:1.0f];
                }
                
                //(re)enumerate
                // ignore if the tap went away
                if(YES != [[[self enumerate] allKeys] containsObject:tapID])
                {
                    //dbg msg
                    logMsg(LOG_DEBUG, [NSString stringWithFormat:@"tap %@, was temporary, so ignoring", currentTaps[tapID]]);
                    
                    //skip
                    continue;
                }
                
                //new
                // and not temporary...
                callback(currentTaps[tapID]);
            
            }//all taps
            
            //update taps
            self.previousTaps = currentTaps;
        
        } //sync
    
    });

    //run loop
    [[NSRunLoop currentRunLoop] run];
    
    return;
}

@end
