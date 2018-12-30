//
//  EventTaps.h
//  ReiKey
//
//  Created by Patrick Wardle on 12/24/18.
//  Copyright © 2018 Objective-See. All rights reserved.
//

#import <Foundation/Foundation.h>

/* TYPEDEFS */

//callback
typedef void (^TapCallbackBlock)(NSDictionary*);

@interface EventTaps : NSObject

/* PROPERTIES */

//previous event taps
@property(nonatomic, retain)NSMutableDictionary* previousTaps;

/* METHODS */

//listen for new taps
// note: method doesn't return!
-(void)observe:(TapCallbackBlock)callback;

//enumerate event taps
// activated keyboard taps
-(NSMutableDictionary*)enumerate;

@end

