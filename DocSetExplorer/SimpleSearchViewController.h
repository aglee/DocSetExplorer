//
//  SimpleSearchViewController.h
//  DocSetExplorer
//
//  Created by Andy Lee on 5/6/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "SearchingViewController.h"

/*!
 * Implements getter methods for the inherited properties.
 */
@interface SimpleSearchViewController : SearchingViewController

@property (copy) NSString *searchString;
@property (assign) NSInteger entityTag;
@property (assign) BOOL ignoreCase;
@property (assign, readonly) BOOL canSearchByLanguage;
@property (assign) BOOL includeSwift;
@property (assign) BOOL includeObjectiveC;
@property (assign) BOOL includeC;
@property (assign) BOOL includeCPlusPlus;
@property (assign) BOOL includeJavaScript;

@end
