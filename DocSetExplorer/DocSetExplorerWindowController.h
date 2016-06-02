//
//  DocSetExplorerWindowController.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/18/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DocSetIndex;
@class SearchingViewController;

@interface DocSetExplorerWindowController : NSWindowController <NSTableViewDelegate, NSSplitViewDelegate>

#pragma mark - Search

/*! Perform a search using parameters that the user entered in vc's view. */
- (void)doSearchWithViewController:(SearchingViewController *)vc;

#pragma mark - Action methods

- (IBAction)selectDocSet:(id)sender;
- (IBAction)doSearch:(id)sender;
- (IBAction)useSavedSearch:(id)sender;

@end
