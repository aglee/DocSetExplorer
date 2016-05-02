//
//  AppDelegate.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/16/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DocSetIndex;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong, nonatomic) DocSetIndex *docSetIndex;

@end
