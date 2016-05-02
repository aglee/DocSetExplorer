//
//  SimpleFetchWindowController.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/18/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "SimpleFetchWindowController.h"
#import "DocSetIndex.h"
#import "DocSetModel.h"
#import "MOBItem.h"
#import "QuietLog.h"
#import <WebKit/WebKit.h>

#define MyErrorDomain @"com.appkido.DocSetExplorer"

@interface SimpleFetchWindowController ()
@property (strong) IBOutlet NSArrayController *fetchedObjectsArrayController;
@property (weak) IBOutlet NSTableView *fetchedObjectsTableView;
@property (weak) IBOutlet NSBrowser *browserView;
@property (weak) IBOutlet WebView *documentationWebView;

@property (strong) MOBItem *rootBrowserItem;
@end

#pragma mark -

@implementation SimpleFetchWindowController

#pragma mark - Using plists for fetch parameters

- (NSDictionary *)fetchParametersAsPlist
{
	return [self dictionaryWithValuesForKeys:@[ @"entityName",
												@"keyPathsString",
												@"distinct",
												@"predicateString" ]];
}

- (void)takeFetchParametersFromPlist:(NSDictionary *)plist
{
	[self setValuesForKeysWithDictionary:plist];
}

#pragma mark - Action methods

- (IBAction)fetch:(id)sender
{
	NSError *error;

	// Try to parse the key paths string into an array.
	NSArray *keyPaths = [self _parseKeyPathsStringWithError:&error];

	// If that worked, try to construct the fetch request.
	NSFetchRequest *fetchRequest;
	if (keyPaths) {
		fetchRequest = [self _createFetchRequestWithError:&error];
		if (self.distinct) {
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
		tableViewUpdateDidSucceed = [self _populateTableViewWithObjects:fetchedObjects keyPaths:keyPaths error:&error];
	}

	// If we got an error anywhere above, report it.
	if (tableViewUpdateDidSucceed == NO) {
		if (error == nil) {
			error = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:@{ NSLocalizedDescriptionKey : @"Unknown error trying to fetch or display the requested data." }];
		}
		[self.window presentError:error];
	}
}

- (IBAction)useSavedFetch:(id)sender
{
	NSInteger savedFetchIndex = sender ? (((NSMenuItem *)sender).tag - 1000) : 0;
	[self _useSavedFetchWithIndex:savedFetchIndex];
}

#pragma mark - <NSBrowserDelegate> methods

- (id)rootItemForBrowser:(NSBrowser *)browser
{
	return self.rootBrowserItem;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
	return ((MOBItem *)item).childItems.count;
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
	return ((MOBItem *)item).childItems[index];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
	return ((MOBItem *)item).displayedTitle;
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item
{
	return (((MOBItem *)item).childItems == nil);

}

#pragma mark - <NSTableViewDelegate> methods

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	id selectedObject = nil;
	NSIndexSet *selectedRowIndexes = self.fetchedObjectsTableView.selectedRowIndexes;
	if (selectedRowIndexes.count == 1) {
		NSInteger selectedRow = [selectedRowIndexes firstIndex];
		selectedObject = self.fetchedObjectsArrayController.arrangedObjects[selectedRow];
	}

	// Update the browser view to reflect the selected object.
	if (selectedObject == nil) {
		self.rootBrowserItem = nil;
	} else {
		MOBItem *item = [[MOBItem alloc] init];
		item.managedObject = selectedObject;
		self.rootBrowserItem = item;
	}
	[self.browserView loadColumnZero];

	// Update the web view to reflect the selected object.
	NSURL *docURL = [self.docSetIndex documentationURLForObject:selectedObject];
	QLog(@"+++ Documentation URL for selected item is %@", docURL);
	if (docURL) {
		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:docURL];
		[self.documentationWebView.mainFrame loadRequest:urlRequest];
	} else {
		[self.documentationWebView.mainFrame loadHTMLString:@"<h1>N/A</h1>" baseURL:nil];  //TODO: Show something nice when there is no doc to display.
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return NO;
}

#pragma mark - <NSWindowDelegate> methods

- (void)windowDidLoad
{
//	[self takeFetchParametersFromPlist:[self _savedFetches][0]];

//	self.entityName = @"TokenType";
//	self.keyPathsString = @"typeName";
//	[self fetch:nil];

	self.entityName = @"Token";
	self.keyPathsString = @"tokenName, tokenType.typeName";
	self.predicateString = @"tokenName like '*Select*'";
	[self fetch:nil];

	self.browserView.defaultColumnWidth = 100;
}

#pragma mark - Private methods - regexes

- (NSString *)_makeAllWhitespaceStretchyInPattern:(NSString *)pattern
{
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+" options:0 error:NULL];

	pattern = [regex stringByReplacingMatchesInString:pattern options:0 range:NSMakeRange(0, pattern.length) withTemplate:@"(?:\\\\s+)"];

	return pattern;
}

// Replaces %ident%, %lit%, %keypath% with canned sub-patterns.
// Ignores leading and trailing whitespace with \\s*.
// Allows internal whitespace to be any length of any whitespace.
// Returns dictionary with NSNumber keys indication position of capture group (1-based).
// Returns nil if invalid pattern.
- (NSDictionary *)_matchPattern:(NSString *)pattern toEntireString:(NSString *)inputString
{
	// Assume leading and trailing whitespace can be ignored, and remove it from both the input string and the pattern.
	inputString = [inputString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (inputString.length == 0) {
		QLog(@"%@", @"Can't handle empty string");
		return nil;  //TODO: Revisit how to handle nil.
	}
	pattern = [pattern stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	// Interpret any internal whitespace in the pattern as meaning "non-empty whitespace of any length".
	pattern = [self _makeAllWhitespaceStretchyInPattern:pattern];

	// Expand %...% placeholders.  Replace %keypath% before replacing %ident%, because the expansion of %keypath% contains "%ident%".
	pattern = [pattern stringByReplacingOccurrencesOfString:@"%keypath%" withString:@"(?:(?:%ident%(?:\\.%ident%)*)(?:\\.@count)?)"];
	pattern = [pattern stringByReplacingOccurrencesOfString:@"%ident%" withString:@"(?:[A-Za-z][0-9A-Za-z]*)"];
	pattern = [pattern stringByReplacingOccurrencesOfString:@"%lit%" withString:@"(?:(?:[^\"]|(?:\\\"))*)"];

	// Apply the regex to the input string.
	NSError *error;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];

	if (regex == nil) {
		QLog(@"regex construction error: %@", error);
		return nil;
	}

	NSRange rangeOfEntireString = NSMakeRange(0, inputString.length);
	NSTextCheckingResult *matchResult = [regex firstMatchInString:inputString options:0 range:rangeOfEntireString];
	if (matchResult == nil) {
		QLog(@"%@", @"failed to match regex");
		return nil;
	} else if (!NSEqualRanges(matchResult.range, rangeOfEntireString)) {
		QLog(@"%@", @"regex did not match entire string");
		return nil;
	}

	// Collect all the capture groups that were matched.  We start iterating at 1 because the zeroeth capture group is the entire matching string.
	NSMutableDictionary *captureGroupsByIndex = [NSMutableDictionary dictionary];
	for (NSInteger rangeIndex = 1; rangeIndex < matchResult.numberOfRanges; rangeIndex++) {
		NSRange captureGroupRange = [matchResult rangeAtIndex:rangeIndex];
		if (captureGroupRange.location != NSNotFound) {
			captureGroupsByIndex[@(rangeIndex)] = [inputString substringWithRange:captureGroupRange];
		}
	}
	//	QLog(@"parse result: %@", captureGroupsByIndex);
	[[captureGroupsByIndex.allKeys sortedArrayUsingSelector:@selector(compare:)] enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		QLog(@"    @%@: [%@]", obj, captureGroupsByIndex[obj]);
	}];

	return captureGroupsByIndex;
}

#pragma mark - Private methods - saved fetch parameters

- (NSArray *)_savedFetches
{
	NSDictionary *exampleTokenQuery = @{ @"entityName" : @"Token",
										 @"keyPathsString" : (@"tokenName, "
															  @"tokenType.typeName, "
															  @"metainformation.declaredIn.frameworkName"),
										 @"predicateString" : @"language.fullName = 'Objective-C'" };

	NSDictionary *exampleNodeURLQuery = @{ @"entityName" : @"NodeURL",
										   @"keyPathsString" : (@"node.kName, "
																@"node.kNodeType, "
																@"node.kDocumentType, "
																@"path, "
																@"anchor"),
										   @"predicateString" : @"" };

	return @[ exampleTokenQuery, exampleNodeURLQuery ];
}

- (void)_useSavedFetchWithIndex:(NSInteger)savedFetchIndex
{
	if (savedFetchIndex < 0 || savedFetchIndex >= [self _savedFetches].count) {
		QLog(@"+++ [ODD] %s Array index %@ is out of bounds for savedFetches", savedFetchIndex);
		return;
	}
	[self takeFetchParametersFromPlist:[self _savedFetches][savedFetchIndex]];
//	[self fetch:nil];
}

#pragma mark - Private methods - handling fetch commands

- (NSArray *)_executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)errorPtr
{
	@try {
		return [self.docSetIndex.managedObjectContext executeFetchRequest:fetchRequest error:errorPtr];
	}
	@catch (NSException *ex) {
		if (errorPtr) {
			NSString *errorMessage = [NSString stringWithFormat:@"Exception during attempt to fetch data: %@. Error: %@.", ex, (errorPtr ? *errorPtr : @"unknown")];
			*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:@{ NSLocalizedDescriptionKey : errorMessage }];
		}
		return nil;
	}
}

- (NSFetchRequest *)_createFetchRequestWithError:(NSError **)errorPtr
{
	// Require the entity name to be a non-empty identifier.
	NSDictionary *captureGroups = [self _matchPattern:@"%ident%" toEntireString:self.entityName];
	if (captureGroups == nil) {
		if (errorPtr) {
			*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:@{ NSLocalizedDescriptionKey : @"Entity name is not a valid identifier." }];
		}
		return nil;
	}

	// Try to make an NSPredicate, if one was specified.
	NSPredicate *predicate = nil;
	if (self.predicateString.length) {
		predicate = [self _createPredicateWithError:errorPtr];
		if (predicate == nil) {
			return nil;
		}
	}

	// If we got this far, everything is okay.
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
	fetchRequest.predicate = predicate;
	return fetchRequest;
}

- (NSPredicate *)_createPredicateWithError:(NSError **)errorPtr
{
	@try {
		return [NSPredicate predicateWithFormat:self.predicateString];
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

- (NSArray *)_parseKeyPathsStringWithError:(NSError **)errorPtr
{
	NSMutableArray *keyPaths = [NSMutableArray array];
	NSDictionary *errorInfo;
	NSArray *commaSeparatedComponents = [self.keyPathsString componentsSeparatedByString:@","];
	for (__strong NSString *expectedKeyPath in commaSeparatedComponents) {
		expectedKeyPath = [expectedKeyPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (![self _matchPattern:@"%keypath%" toEntireString:expectedKeyPath]) {
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

// Tears down and re-adds table columns based on the key paths the table view is now being asked to display.
// Reuses existing NSTableColumns where possible, so if the user had meticulously set a column width or sort order they liked, we don't blow away those settings.
// **NOTE:** The logic here only works if the table view is cell-based.  In a view-based table view, the column bindings are at the level of the cell view, not the NSTableColumn.
- (void)_reconstructTableColumnsWithKeyPaths:(NSArray *)keyPathsForTableColumns
{
	// Remove all existing table columns, but keep them around so we can reuse them where possible.
	NSMutableDictionary *oldTableColumnsByKeyPath = [NSMutableDictionary dictionary];
	for (NSTableColumn *tableColumn in [self.fetchedObjectsTableView.tableColumns copy]) {
		oldTableColumnsByKeyPath[tableColumn.sortDescriptorPrototype.key] = tableColumn;
		[self.fetchedObjectsTableView removeTableColumn:tableColumn];
	}

	// Re-add table columns as specified.
	NSMutableArray *sortDescriptors = [NSMutableArray array];
	for (NSString *keyPath in keyPathsForTableColumns) {
		NSTableColumn *tableColumn = oldTableColumnsByKeyPath[keyPath];
		if (tableColumn == nil) {
			tableColumn = [[NSTableColumn alloc] initWithIdentifier:keyPath];
			tableColumn.title = keyPath;
			tableColumn.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:keyPath ascending:YES];
			[tableColumn bind:@"value"
					 toObject:self.fetchedObjectsArrayController
				  withKeyPath:[@"arrangedObjects." stringByAppendingString:keyPath]
					  options:nil];
		}
		[self.fetchedObjectsTableView addTableColumn:tableColumn];
		[sortDescriptors addObject:tableColumn.sortDescriptorPrototype];
	}
	self.fetchedObjectsTableView.sortDescriptors = sortDescriptors;
}

- (BOOL)_populateTableViewWithObjects:(NSArray *)fetchedObjects keyPaths:(NSArray *)keyPathsForTableColumns error:(NSError **)errorPtr
{
	// An exception will be thrown if the objects in fetchedObjects are not KVO-compatible with the key paths.
	@try {
		// I start by removing all existing table rows, so the table view won't try to display objects that aren't compatible with the new key paths.  I'm not sure this is necessary, but it seems safer to do it.
		self.fetchedObjectsArrayController.content = nil;
		[self _reconstructTableColumnsWithKeyPaths:keyPathsForTableColumns];
		self.fetchedObjectsArrayController.sortDescriptors = self.fetchedObjectsTableView.sortDescriptors;
		self.fetchedObjectsArrayController.content = fetchedObjects;
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
		NSMutableString *valuesString = [NSMutableString stringWithFormat:@"[%lu] %@", (unsigned long)objectIndex, [obj className]];

		for (NSString *kp in keyPaths) {
			[valuesString appendFormat:@" [%@]", [obj valueForKeyPath:kp]];
		}

		QLog(@"%@", valuesString);
	}];

	QLog(@"%@ objects", @(array.count));
}

@end
