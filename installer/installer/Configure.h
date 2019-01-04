//
//  Configure.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/31/18.
//  Copyright (c) 2018 Objective-See. All rights reserved.
//

#ifndef Configure_h
#define Configure_h

#import <Foundation/Foundation.h>

@interface Configure : NSObject
{
    
}

/* METHODS */

//invokes appropriate install || uninstall logic
-(BOOL)configure:(NSUInteger)parameter;

//install
-(BOOL)install;

//uninstall
-(BOOL)uninstall:(NSUInteger)type;

@end

#endif
