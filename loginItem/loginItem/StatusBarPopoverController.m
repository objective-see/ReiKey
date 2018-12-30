//
//  StatusBarPopoverController.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import "AppDelegate.h"
#import "StatusBarPopoverController.h"

@implementation StatusBarPopoverController

//'close' button handler
// simply dismiss/close popover
-(IBAction)closePopover:(NSControl *)sender
{
    //close
    [[[self view] window] close];
    
    return;
}

@end
