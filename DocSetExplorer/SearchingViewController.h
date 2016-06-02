//
//  SearchingViewController.h
//  DocSetExplorer
//
//  Created by Andy Lee on 5/6/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * Abstract base class.  Presents a UI for searching a DocSetIndex.
 */
@interface SearchingViewController : NSViewController

@property (copy, readonly) NSString *entityName;
@property (copy, readonly) NSString *keyPathsString;
@property (assign, readonly) BOOL distinct;
@property (copy, readonly) NSString *predicateString;

- (IBAction)doSearch:(id)sender;

@end
