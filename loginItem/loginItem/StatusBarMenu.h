//
//  StatusBarMenu.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Cocoa;

@interface StatusBarMenu : NSObject <NSPopoverDelegate>
{

}

//status item
@property(nonatomic, strong, readwrite)NSStatusItem *statusItem;

//popover
@property(retain, nonatomic)NSPopover *popover;

//disabled flag
@property BOOL isDisabled;

/* METHODS */

//init
-(id)init:(NSMenu*)menu;

@end
