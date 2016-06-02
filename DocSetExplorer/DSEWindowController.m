//
//  DSEWindowController.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/18/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "DSEWindowController.h"
#import "AdvancedSearchViewController.h"
#import "AKRegexUtils.h"
#import "DocSetIndex+DocSetExplorer.h"
#import "DocSetModel.h"
#import "DSEPrefUtils.h"
#import "MOBrowserViewController.h"
#import "QuietLog.h"
#import "SimpleSearchViewController.h"
#import <WebKit/WebKit.h>

#define MyErrorDomain @"com.appkido.DocSetExplorer"

@interface DSEWindowController ()

// Selecting from the available docsets.
@property (strong) IBOutlet NSArrayController *availableDocSetsArrayController;
@property (strong, readonly) DocSetIndex *selectedDocSetIndex;

// Search UI.
@property (strong) IBOutlet NSTabViewItem *simpleSearchTabViewItem;
@property (strong) IBOutlet NSTabViewItem *advancedSearchTabViewItem;
@property (strong) IBOutlet SimpleSearchViewController *simpleSearchViewController;
@property (strong) IBOutlet AdvancedSearchViewController *advancedSearchViewController;

// Search results.
@property (strong) IBOutlet NSArrayController *searchResultsArrayController;
@property (weak) IBOutlet NSTableView *searchResultsTableView;

// Viewing the selected search result's documentation.
@property (weak) IBOutlet NSTextField *docPathField;
@property (weak) IBOutlet NSTextField *docTitleField;
@property (weak) IBOutlet WebView *docWebView;

// Browsing the selected search result's attributes and relationships.
@property (strong) MOBrowserViewController *moBrowserViewController;
@property (weak) IBOutlet NSView *moBrowserContainerView;

@end

#pragma mark -

@implementation DSEWindowController

#pragma mark - Search

- (void)doSearchWithViewController:(SearchingViewController *)vc
{
	NSError *error;

	// Try to parse the key paths string into an array.
	NSArray *keyPaths = [self _parseKeyPaths:vc.keyPathsString error:&error];

	// If that worked, try to construct the fetch request.
	NSFetchRequest *fetchRequest;
	if (keyPaths) {
		fetchRequest = [self _fetchRequestWithEntityName:vc.entityName
										 predicateString:vc.predicateString
												   error:&error];
		if (vc.distinct) {
			fetchRequest.returnsDistinctResults = YES;
			fetchRequest.resultType = NSDictionaryResultType;
			fetchRequest.propertiesToFetch = keyPaths;
		}
	}

	// If that worked, try to execute the fetch request.
	NSArray *fetchedObjects;
	if (fetchRequest) {
		fetchedObjects = [self _executeFetchRequest:fetchRequest error:&error];
	}

	// If that worked, try to display the fetched objects.
	BOOL tableViewUpdateDidSucceed = NO;
	if (fetchedObjects) {
		tableViewUpdateDidSucceed = [self _updateWithSearchResults:fetchedObjects
														  keyPaths:keyPaths
															 error:&error];
	}

	// If we got an error anywhere above, report it.
	if (tableViewUpdateDidSucceed == NO) {
		if (error == nil) {
			error = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:@{ NSLocalizedDescriptionKey : @"Unknown error trying to fetch or display the requested data." }];
		}
		[self.window presentError:error];
	}
}

#pragma mark - Getters and setters

- (DocSetIndex *)selectedDocSetIndex
{
	return self.availableDocSetsArrayController.selectedObjects.firstObject;
}

#pragma mark - Action methods

- (IBAction)selectDocSet:(id)sender
{
	[self _selectedDocSetDidChange];
}

- (IBAction)doSearch:(id)sender
{
	if (!self.simpleSearchViewController.view.isHidden) {
		[self doSearchWithViewController:self.simpleSearchViewController];
	} else if (!self.advancedSearchViewController.view.isHidden) {
		[self doSearchWithViewController:self.advancedSearchViewController];
	} else {
		QLog(@"+++ [ODD] %s Neither the simple nor advanced search view seems to be active.", __PRETTY_FUNCTION__);
	}
}

- (IBAction)useSavedSearch:(id)sender
{
	NSInteger savedSearchIndex = ((NSMenuItem *)sender).tag;
	[self _useSavedSearchWithIndex:savedSearchIndex];
}

#pragma mark - NSWindowController methods

- (void)windowDidLoad
{
	[super windowDidLoad];

	// Initialize the list of available docsets.
	NSSortDescriptor *sort;
	sort = [NSSortDescriptor sortDescriptorWithKey:@"docSetName"
										 ascending:YES
										  selector:@selector(caseInsensitiveCompare:)];
	self.availableDocSetsArrayController.sortDescriptors = @[sort];
	self.availableDocSetsArrayController.content = [DocSetIndex arrayWithStandardInstances];

	// Try to select the docset indicated in prefs.
	NSString *docSetPath = DSEPrefs.defaultDocSetPath;
	for (DocSetIndex *docSetIndex in self.availableDocSetsArrayController.arrangedObjects) {
		if ([docSetIndex.docSetPath isEqualToString:docSetPath]) {
			self.availableDocSetsArrayController.selectedObjects = @[docSetIndex];
		}
	}

	// Initialize the managed object browser.
	self.moBrowserViewController = [[MOBrowserViewController alloc] initWithNibName:@"MOBrowserViewController" bundle:nil];
	[self _fillView:self.moBrowserContainerView withSubview:self.moBrowserViewController.view];
}

#pragma mark - <NSTableViewDelegate> methods

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *whichTableView = aNotification.object;

	if (whichTableView == self.searchResultsTableView) {
		[self _selectedSearchResultDidChange];
	} else {
		QLog(@"+++ [ODD] Unexpected table view %@", whichTableView);
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return NO;
}

#pragma mark - <NSSplitViewDelegate> methods

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	// Seems to work out okay if I constrain all panes to 300 in both directions.
	return 300;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	// Seems to work out okay if I constrain all panes to 300 in both directions.
	return (splitView.isVertical
			? NSMaxX(splitView.bounds) - 300
			: NSMaxY(splitView.bounds) - 300);
}

#pragma mark - <WebFrameLoadDelegate> methods

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
	self.docTitleField.stringValue = title;
}

#pragma mark - Private methods - init

- (void)_fillView:(NSView *)outerView withSubview:(NSView *)innerView
{
	[outerView addSubview:innerView];
	innerView.frame = outerView.bounds;
	innerView.autoresizingMask = NSViewWidthSizable |  NSViewHeightSizable;
}

#pragma mark - Private methods - saved search parameters

- (NSArray *)_savedSearches
{
	static dispatch_once_t once;
	static NSArray *s_savedSearches;
	dispatch_once(&once, ^{
		s_savedSearches = @[@{ @"entityName" : @"Token",
							   @"keyPathsString" : (@"tokenName, "
													@"tokenType.typeName, "
													@"metainformation.declaredIn.frameworkName"),
							   @"distinct" : @NO,
							   @"predicateString" : (@"language.fullName = 'Objective-C'"
													 @" and tokenName like[c] '*View*'") },
							@{ @"entityName" : @"NodeURL",
							   @"keyPathsString" : (@"node.kName, "
													@"node.kNodeType, "
													@"node.kDocumentType, "
													@"path, "
													@"anchor"),
							   @"distinct" : @NO,
							   @"predicateString" : @"node.kName like[c] '*Guide*'" },
							@{ @"entityName" : @"Token",
							   @"keyPathsString" : @"tokenType.typeName",
							   @"distinct" : @YES,
							   @"predicateString" : @"language.fullName = 'Swift'" }];
	});
	return s_savedSearches;
}

- (void)_useSavedSearchWithIndex:(NSInteger)savedSearchIndex
{
	if (savedSearchIndex < 0 || savedSearchIndex >= [self _savedSearches].count) {
		QLog(@"+++ [ODD] %s Array index %@ is out of bounds for savedSearches", __PRETTY_FUNCTION__, savedSearchIndex);
		return;
	}

	// Display the saved search parameters in the advanced-search pane.
	NSDictionary *searchParams = [self _savedSearches][savedSearchIndex];
	[self.advancedSearchViewController setValuesForKeysWithDictionary:searchParams];
	NSTabView *tabView = self.advancedSearchTabViewItem.tabView;
	[tabView selectTabViewItem:self.advancedSearchTabViewItem];

	// Perform the search.
	[self doSearchWithViewController:self.advancedSearchViewController];
}

#pragma mark - Private methods - handling fetch commands

- (NSArray *)_parseKeyPaths:(NSString *)keyPathsString error:(NSError **)errorPtr
{
	NSMutableArray *keyPaths = [NSMutableArray array];
	NSDictionary *errorInfo;
	NSArray *commaSeparatedComponents = [keyPathsString componentsSeparatedByString:@","];
	for (__strong NSString *expectedKeyPath in commaSeparatedComponents) {
		expectedKeyPath = [expectedKeyPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (![AKRegexUtils matchPattern:@"%keypath%" toEntireString:expectedKeyPath]) {
			if (errorPtr) {
				NSString *errorMessage = [NSString stringWithFormat:@"'%@' is not a key path.  Make sure to comma-separate key paths.", expectedKeyPath];
				errorInfo = @{ NSLocalizedDescriptionKey : errorMessage };
				*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:errorInfo];
			}
			return nil;
		} else {
			[keyPaths addObject:expectedKeyPath];
		}
	}
	if (keyPaths.count == 0) {
		if (errorPtr) {
			errorInfo = @{ NSLocalizedDescriptionKey : @"One or more comma-separated key paths must be specified." };
			*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:errorInfo];
		}
		return nil;
	}
	return keyPaths;
}

- (NSFetchRequest *)_fetchRequestWithEntityName:(NSString *)entityName
								predicateString:(NSString *)predicateString
										  error:(NSError **)errorPtr
{
	// Require the entity name to be a non-empty identifier.
	NSDictionary *captureGroups = [AKRegexUtils matchPattern:@"%ident%" toEntireString:entityName];
	if (captureGroups == nil) {
		if (errorPtr) {
			*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:@{ NSLocalizedDescriptionKey : @"Entity name is not a valid identifier." }];
		}
		return nil;
	}

	// Try to make an NSPredicate, if one was specified.
	NSPredicate *predicate = nil;
	if (predicateString.length) {
		predicate = [self _predicateWithString:predicateString error:errorPtr];
		if (predicate == nil) {
			return nil;
		}
	}

	// If we got this far, we can return a fetch request.
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
	fetchRequest.predicate = predicate;
	return fetchRequest;
}

- (NSPredicate *)_predicateWithString:(NSString *)predicateString error:(NSError **)errorPtr
{
	@try {
		return [NSPredicate predicateWithFormat:predicateString];
	}
	@catch (NSException *ex) {
		if ([ex.name isEqualToString:NSInvalidArgumentException]) {
			if (errorPtr) {
				*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:@{ NSLocalizedDescriptionKey : @"Invalid predicate string." }];
			}
		} else {
			@throw ex;
		}
		return nil;
	}
}

- (NSArray *)_executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)errorPtr
{
	@try {
		return [self.selectedDocSetIndex.managedObjectContext executeFetchRequest:fetchRequest error:errorPtr];
	}
	@catch (NSException *ex) {
		if (errorPtr) {
			NSString *errorMessage = [NSString stringWithFormat:@"Exception during attempt to fetch data: %@. Error: %@.", ex, (errorPtr ? *errorPtr : @"unknown")];
			*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:@{ NSLocalizedDescriptionKey : errorMessage }];
		}
		return nil;
	}
}

// Tears down and re-adds table columns based on the key paths the table view is
// now being asked to display.  Reuses existing NSTableColumns where possible,
// so if the user had meticulously set a column width or sort order they liked,
// we don't blow away those settings.
//
// **NOTE:** The logic here only works if the table view is cell-based.  In a
// view-based table view, the column bindings are at the level of the cell view,
// not the NSTableColumn.
- (void)_reconstructTableColumnsWithKeyPaths:(NSArray *)keyPathsForTableColumns
{
	// Remove all existing table columns, but keep them around so we can reuse
	// them where possible.
	NSMutableDictionary *oldTableColumnsByKeyPath = [NSMutableDictionary dictionary];
	for (NSTableColumn *tableColumn in [self.searchResultsTableView.tableColumns copy]) {
		oldTableColumnsByKeyPath[tableColumn.sortDescriptorPrototype.key] = tableColumn;
		[self.searchResultsTableView removeTableColumn:tableColumn];
	}

	// Re-add table columns as specified.
	NSMutableArray *sortDescriptors = [NSMutableArray array];
	for (NSString *keyPath in keyPathsForTableColumns) {
		NSTableColumn *tableColumn = oldTableColumnsByKeyPath[keyPath];
		if (tableColumn == nil) {
			tableColumn = [[NSTableColumn alloc] initWithIdentifier:keyPath];
			tableColumn.title = keyPath;
			tableColumn.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:keyPath
																				ascending:YES];
			[tableColumn bind:@"value"
					 toObject:self.searchResultsArrayController
				  withKeyPath:[@"arrangedObjects." stringByAppendingString:keyPath]
					  options:nil];
		}
		[self.searchResultsTableView addTableColumn:tableColumn];
		[sortDescriptors addObject:tableColumn.sortDescriptorPrototype];
	}
	self.searchResultsTableView.sortDescriptors = sortDescriptors;
}

- (BOOL)_updateWithSearchResults:(NSArray *)searchResults
						keyPaths:(NSArray *)keyPathsForTableColumns
						   error:(NSError **)errorPtr
{
	// An exception will be thrown if the objects in fetchedObjects are not
	// KVO-compatible with the key paths.
	@try {
		// Start by removing all existing table rows, so the table view won't
		// try to display objects that aren't compatible with the new key paths.
		// I'm not positive this is necessary, but it seems safer to do it.
		self.searchResultsArrayController.content = nil;
		[self _reconstructTableColumnsWithKeyPaths:keyPathsForTableColumns];
		self.searchResultsArrayController.sortDescriptors = self.searchResultsTableView.sortDescriptors;
		self.searchResultsArrayController.content = searchResults;
		return YES;
	}
	@catch (NSException *ex) {
		if (errorPtr) {
			*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:@{ NSLocalizedDescriptionKey : ex.description }];
		}
		return NO;
	}
}

- (void)_printValues:(NSArray *)keyPaths forObjects:(NSArray *)array
{
	if (array == nil) {
		QLog(@"array is nil");
		return;
	}

	[array enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger objectIndex, BOOL * _Nonnull stop) {
		NSMutableString *valuesString = [NSMutableString stringWithFormat:@"[%lu] %@",
										 (unsigned long)objectIndex,
										 [obj className]];

		for (NSString *kp in keyPaths) {
			[valuesString appendFormat:@" [%@]", [obj valueForKeyPath:kp]];
		}

		QLog(@"%@", valuesString);
	}];

	QLog(@"%@ objects", @(array.count));
}

#pragma mark - Private methods - selection changes

- (void)_selectedSearchResultDidChange
{
	id selectedSearchResult = self.searchResultsArrayController.selectedObjects.firstObject;
	NSURL *docURL = [self.selectedDocSetIndex documentationURLForObject:selectedSearchResult];

	// Update the managed object browser.
	if (selectedSearchResult == nil || ![selectedSearchResult isKindOfClass:[NSManagedObject class]]) {
		self.moBrowserViewController.rootObject = nil;
	} else {
		self.moBrowserViewController.rootObject = selectedSearchResult;
	}

	// Update docPathField.
	if (docURL == nil) {
		self.docPathField.stringValue = @"";
	} else if (docURL.isFileURL) {
		NSString *itemPath;
		NSString *itemAnchor;
		if ([selectedSearchResult isKindOfClass:[DSAToken class]]) {
			itemPath = ((DSAToken *)selectedSearchResult).metainformation.file.path;
			itemAnchor = ((DSAToken *)selectedSearchResult).metainformation.anchor;
		} else if ([selectedSearchResult isKindOfClass:[DSANodeURL class]]) {
			itemPath = ((DSANodeURL *)selectedSearchResult).path;
			itemAnchor = ((DSANodeURL *)selectedSearchResult).anchor;
		}
		if (itemAnchor.length) {
			itemPath = [NSString stringWithFormat:@"%@#%@", itemPath, itemAnchor];
		}
		self.docPathField.stringValue = (itemPath.length ? itemPath : @"");
	} else {
		self.docPathField.stringValue = docURL.absoluteString;
	}

	// Update docTitleField and docWebView.
	self.docTitleField.stringValue = @"";  // We will fill this in as the web view loads.
	QLog(@"+++ Documentation URL for selected item is %@", docURL);
	if (docURL) {
		// For local HTML files, turn off JavaScript, which interferes by hiding
		// stuff we don't want to hide.
		self.docWebView.preferences.javaScriptEnabled = !docURL.isFileURL;

		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:docURL];
		[self.docWebView.mainFrame loadRequest:urlRequest];
	} else {
		[self.docWebView.mainFrame loadHTMLString:@"<h1>?</h1>" baseURL:nil];
	}
}

- (void)_selectedDocSetDidChange
{
	DocSetIndex *docSetIndex = self.availableDocSetsArrayController.selectedObjects.firstObject;
	DSEPrefs.defaultDocSetPath = docSetIndex.docSetPath;
}

@end
