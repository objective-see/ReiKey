//
//  AboutWindowController.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

@import Cocoa;

@interface AboutWindowController : NSWindowController <NSWindowDelegate>
{
    
}

/* PROPERTIES */

//version label/string
@property (weak) IBOutlet NSTextField *versionLabel;

//patrons
@property (unsafe_unretained) IBOutlet NSTextView *patrons;

/* METHODS */

//automatically invoked when user clicks any of the buttons
// perform actions, such as loading patreon or products URL
-(IBAction)buttonHandler:(id)sender;

@end
