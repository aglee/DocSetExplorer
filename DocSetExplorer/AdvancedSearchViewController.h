//
//  AdvancedSearchViewController.h
//  DocSetExplorer
//
//  Created by Andy Lee on 5/6/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "SearchingViewController.h"

/*!
 * Redeclares the inherited properties to be readwrite, and synthesizes them.
 */
@interface AdvancedSearchViewController : SearchingViewController

@property (copy) NSString *entityName;
@property (copy) NSString *keyPathsString;
@property (assign) BOOL distinct;
@property (copy) NSString *predicateString;

@end
