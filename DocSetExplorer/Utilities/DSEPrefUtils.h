//
//  DSEPrefUtils.h
//  DocSetExplorer
//
//  Created by Andy Lee on 5/28/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DSEPrefs [DSEPrefUtils sharedPrefs]

@interface DSEPrefUtils : NSObject

/*! Path to the .docset bundle that should be used when a new window is opened. */
@property (copy) NSString *defaultDocSetPath;

+ (instancetype)sharedPrefs;

@end
