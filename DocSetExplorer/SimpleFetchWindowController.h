//
//  SimpleFetchWindowController.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/18/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DocSetIndex;
@class SearchingViewController;

@interface SimpleFetchWindowController : NSWindowController <NSTableViewDelegate>

@property (strong, readonly) DocSetIndex *selectedDocSetIndex;

- (void)doSearchWithViewController:(SearchingViewController *)vc;

#pragma mark - Action methods

- (IBAction)doSearch:(id)sender;
- (IBAction)useSavedSearch:(id)sender;

@end
