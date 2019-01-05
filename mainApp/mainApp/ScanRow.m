//
//  RuleRow.m
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import "ScanRow.h"

@implementation ScanRow

//custom row selection
-(void)drawSelectionInRect:(NSRect)dirtyRect
{
    //selection rect
    NSRect selectionRect = {0};
    
    //selection path
    NSBezierPath* selectionPath = nil;
    
    //selection color
    NSColor* selectionColor = nil;
    
    //highlight selected rows
    if(self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone)
    {
        //make selection rect
        selectionRect = NSInsetRect(self.bounds, 2.5, 2.5);
        
        //default color
        selectionColor = [NSColor systemGrayColor];
        
        //10.4, set to unemphasized
        if (@available(macOS 10.14, *))
        {
            //set
            selectionColor = [NSColor unemphasizedSelectedContentBackgroundColor];
        }
        
        //set stroke
        [selectionColor setStroke];
        
        //set fill
        [selectionColor setFill];
        
        //create selection path
        // with rounded corners
        selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:5 yRadius:5];
        
        //fill
        [selectionPath fill];
        
        //stroke
        [selectionPath stroke];
    }
    
    return;
}

@end
