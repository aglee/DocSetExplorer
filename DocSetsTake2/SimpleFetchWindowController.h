//
//  SimpleFetchWindowController.h
//  DocSetsTake2
//
//  Created by Andy Lee on 4/18/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DocSetIndex;

@interface SimpleFetchWindowController : NSWindowController

@property (strong) DocSetIndex *docSetIndex;
@property (copy) NSString *entityName;
@property (copy) NSString *keyPathsString;
@property (assign) BOOL distinct;
@property (copy) NSString *predicateString;

#pragma mark - Action methods

- (IBAction)fetch:(id)sender;

@end
