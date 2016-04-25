//
//  SimpleFetchWindowController.m
//  DocSetsTake2
//
//  Created by Andy Lee on 4/18/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "SimpleFetchWindowController.h"
#import "DocSetIndex.h"
#import "DocSetModel.h"
#import "QuietLog.h"
#import <WebKit/WebKit.h>

#define MyErrorDomain @"com.appkido.DocSetsTake2"

@interface SimpleFetchWindowController ()
@property (strong) IBOutlet NSArrayController *fetchedResultsArrayController;
@property (weak) IBOutlet NSTableView *fetchedResultsTableView;
@property (weak) IBOutlet WebView *documentationWebView;
@property (strong) NSArray *keyPathsUsedByTableView;

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
	// Throughout this method we must make sure that if an error occurs we set this NSError variable.
	NSError *error;

	// Try to parse key paths into an array.
	NSArray *keyPaths;
	if (error == nil) {
		keyPaths = [self _parseKeyPathsStringWithError:&error];
		if (keyPaths == nil) {
			QLog(@"%@", @"[ERROR] Invalid key paths string: %@");
			if (error == nil) {
				error = [NSError errorWithDomain:MyErrorDomain
											code:9999
										userInfo:@{ NSLocalizedDescriptionKey : @"Key paths string is invalid.  Make sure it is a non-empty, comma-separated list of key paths." }];
			}
		}
	}

	// Try to fetch the specified objects.
	NSArray *fetchedObjects;
	if (error == nil) {
		fetchedObjects = [self _tryFetchWithError:&error];
		if (fetchedObjects == nil) {
			QLog(@"[ERROR] Fetch failed: %@", error);
			if (error == nil) {
				error = [NSError errorWithDomain:MyErrorDomain
											code:9999
										userInfo:@{ NSLocalizedDescriptionKey : @"Failed to fetch objects from the docset's Core Data store." }];
			}
		}
	}

	// Try to display our results.  An exception will be thrown if the results are not compatible with the key paths.
	if (error == nil) {
		@try {
			[self _populateTableViewWithObjects:fetchedObjects keyPaths:keyPaths];
		}
		@catch (NSException *ex) {
			error = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:@{ NSLocalizedDescriptionKey : ex.description }];
		}
	}

	// Did we get an error anywhere above?
	if (error) {
		[self presentError:error];
	}
}

- (IBAction)useSavedFetch:(id)sender
{
	NSInteger savedFetchIndex = sender ? (((NSMenuItem *)sender).tag - 1000) : 0;
	[self _useSavedFetchWithIndex:savedFetchIndex];
}

- (void)_useSavedFetchWithIndex:(NSInteger)savedFetchIndex
{
	NSArray *savedFetches = @[
							  // A basic Token query:
							  @{ @"entityName"		: @"Token",
								 @"keyPathsString"	:(@"tokenName, "
													  @"tokenType.typeName, "
													  @"metainformation.declaredIn.frameworkName"),
								 @"predicateString"	: @"language.fullName = 'Objective-C'" },

							  // A basic NodeURL query:
							  @{ @"entityName"		: @"NodeURL",
								 @"keyPathsString"	:(@"node.kName, "
													  @"node.kNodeType, "
													  @"node.kDocumentType, "
													  @"path, "
													  @"anchor"),
								 @"predicateString" : @"" },
							  ];
	if (savedFetchIndex < 0 || savedFetchIndex >= savedFetches.count) {
		QLog(@"+++ [ODD] %s Array index %@ is out of bounds for savedFetches", savedFetchIndex);
		return;
	}
	[self takeFetchParametersFromPlist:savedFetches[savedFetchIndex]];
	[self fetch:nil];
}


#pragma mark - <NSTableViewDelegate> methods

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if (aNotification.object != self.fetchedResultsTableView) {
		QLog(@"[ODD] %s Unexpected table view %@", aNotification.object);
		return;
	}

	NSURL *docURL = [self _documentationURLOfSelectedItem];
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
	[self _useSavedFetchWithIndex:0];
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
	pattern = [pattern stringByReplacingOccurrencesOfString:@"%keypath%" withString:@"(?:(?:%ident%(?:\\.%ident%)*))"];
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

#pragma mark - Private methods - handling fetch commands

- (NSArray *)_tryFetchWithError:(NSError **)errorPtr
{
	NSDictionary *errorInfo;

	// Require the entity name to be a non-empty identifier.
	NSDictionary *captureGroups = [self _matchPattern:@"%ident%" toEntireString:self.entityName];
	if (captureGroups == nil) {
		errorInfo = @{ NSLocalizedDescriptionKey : @"Entity name is not a valid identifier." };
		*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:errorInfo];
		return nil;
	}

	// Try to make an NSPredicate, if one was specified.
	NSPredicate *predicate = nil;
	if (self.predicateString.length) {
		@try {
			predicate = [NSPredicate predicateWithFormat:self.predicateString];
		}
		@catch (NSException *ex) {
			if ([ex.name isEqualToString:NSInvalidArgumentException]) {
				errorInfo = @{ NSLocalizedDescriptionKey : @"Invalid predicate string." };
				*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:errorInfo];
				return nil;
			} else {
				@throw ex;
			}
		}
	}

	NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
	req.predicate = predicate;
	if (self.distinct) {
		req.returnsDistinctResults = YES;
		req.resultType = NSDictionaryResultType;
		req.propertiesToFetch = [self _parseKeyPathsStringWithError:NULL];
	}

	// Try to execute the fetch.
	NSArray *fetchedObjects;
	@try {
		fetchedObjects = [self.docSetIndex.managedObjectContext executeFetchRequest:req error:errorPtr];
	}
	@catch (NSException *ex) {
		NSString *errorMessage = [NSString stringWithFormat:@"Exception during attempt to fetch data: %@. Error: %@.", ex, (errorPtr ? *errorPtr : @"unknown")];
		errorInfo = @{ NSLocalizedDescriptionKey : errorMessage };
		*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:errorInfo];
		return nil;
	}

	// If we got this far, all was successful.
	return fetchedObjects;
}

- (NSArray *)_parseKeyPathsStringWithError:(NSError **)errorPtr
{
	NSMutableArray *keyPaths = [NSMutableArray array];
	NSDictionary *errorInfo;
	NSArray *commaSeparatedComponents = [self.keyPathsString componentsSeparatedByString:@","];
	for (__strong NSString *expectedKeyPath in commaSeparatedComponents) {
		expectedKeyPath = [expectedKeyPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (![self _matchPattern:@"%keypath%" toEntireString:expectedKeyPath]) {
			NSString *errorMessage = [NSString stringWithFormat:@"'%@' is not a key path.", expectedKeyPath];
			errorInfo = @{ NSLocalizedDescriptionKey : errorMessage };
			*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:errorInfo];
			return nil;
		} else {
			[keyPaths addObject:expectedKeyPath];
		}
	}
	if (keyPaths.count == 0) {
		errorInfo = @{ NSLocalizedDescriptionKey : @"At least one key path must be specified." };
		*errorPtr = [NSError errorWithDomain:MyErrorDomain code:9999 userInfo:errorInfo];
		return nil;
	}
	return keyPaths;
}

// Reconstructs the table columns based on the key paths they're supposed to display.
// Does nothing if the key paths haven't changed since the last time we did this.  This way, if the user had spent time setting column widths and sort orders, those settings won't get blown away.
// **NOTE:** This logic only works if the table view is cell-based.  The code would have to be changed if we were to make it view-based.
- (void)_reconstructTableColumnsWithKeyPaths:(NSArray *)keyPathsForTableColumns
{
	if ([keyPathsForTableColumns isEqualToArray:self.keyPathsUsedByTableView]) {
		return;
	}

	for (NSTableColumn *tableColumn in [self.fetchedResultsTableView.tableColumns copy]) {
		[self.fetchedResultsTableView removeTableColumn:tableColumn];
	}
	NSMutableArray *sortDescriptors = [NSMutableArray array];
	for (NSString *keyPath in keyPathsForTableColumns) {
		NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:keyPath];
		tableColumn.title = keyPath;
		tableColumn.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:keyPath ascending:YES];
		[sortDescriptors addObject:tableColumn.sortDescriptorPrototype];
		[tableColumn bind:@"value"
				 toObject:self.fetchedResultsArrayController
			  withKeyPath:[@"arrangedObjects." stringByAppendingString:keyPath]
				  options:nil];

		[self.fetchedResultsTableView addTableColumn:tableColumn];
	}

	self.keyPathsUsedByTableView = keyPathsForTableColumns;
}

- (void)_populateTableViewWithObjects:(NSArray *)fetchedObjects keyPaths:(NSArray *)keyPathsForTableColumns
{
	// Remove all table rows, so the table view won't try to display objects that aren't compatible with the new key paths.
	self.fetchedResultsArrayController.content = nil;

	// Reconstruct table columns.
	[self _reconstructTableColumnsWithKeyPaths:keyPathsForTableColumns];

	// Repopulate the table view by plugging the objects into array controller.
	NSMutableArray *sortDescriptors = [NSMutableArray array];
	for (NSTableColumn *tableColumn in self.fetchedResultsTableView.tableColumns) {
		[sortDescriptors addObject:tableColumn.sortDescriptorPrototype];
	}
	self.fetchedResultsArrayController.sortDescriptors = sortDescriptors;
	self.fetchedResultsArrayController.content = fetchedObjects;
}

- (NSURL *)_documentationURLOfSelectedItem
{
	NSIndexSet *selectedRowIndexes = self.fetchedResultsTableView.selectedRowIndexes;
	if (selectedRowIndexes.count != 1) {
		return nil;
	}
	NSInteger selectedRow = [selectedRowIndexes firstIndex];
	id selectedObject = self.fetchedResultsArrayController.arrangedObjects[selectedRow];

	if ([selectedObject isKindOfClass:[DSAToken class]]) {
		return [self.docSetIndex documentationURLForToken:(DSAToken *)selectedObject];
	} else if ([selectedObject isKindOfClass:[DSANodeURL class]]) {
		return [self.docSetIndex documentationURLForNodeURL:(DSANodeURL *)selectedObject];
	}

	return nil;
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
