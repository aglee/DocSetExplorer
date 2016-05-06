//
//  SimpleFetchWindowController.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/18/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DocSetIndex;

@interface SimpleFetchWindowController : NSWindowController <NSTableViewDelegate>

@property (strong, readonly) DocSetIndex *selectedDocSetIndex;
@property (copy) NSString *entityName;
@property (copy) NSString *keyPathsString;
@property (assign) BOOL distinct;
@property (copy) NSString *predicateString;

#pragma mark - Using plists for fetch parameters

- (NSDictionary *)fetchParametersAsPlist;
- (void)takeFetchParametersFromPlist:(NSDictionary *)plist;

#pragma mark - Action methods

- (IBAction)fetch:(id)sender;
- (IBAction)useSavedFetch:(id)sender;

@end
