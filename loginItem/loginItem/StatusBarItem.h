//
//  StatusBarMenu.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Cocoa;

@interface StatusBarItem : NSObject <NSPopoverDelegate>
{

}

//status item
@property(nonatomic, retain)NSStatusItem* statusItem;

//status menu
@property(nonatomic, retain)NSMenu* statusMenu;

//popover
@property(retain, nonatomic)NSPopover *popover;

//disabled flag
@property BOOL isDisabled;

/* METHODS */

//init
-(id)init:(NSMenu*)menu;

//create status item
-(void)createStatusItem;

//remove status item
-(void)removeStatusItem;

@end
