//
//  SimpleFetchWindowController.m
//  DocSetsTake2
//
//  Created by Andy Lee on 4/18/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "SimpleFetchWindowController.h"
#import "DocSetIndex.h"
#import "QuietLog.h"

@interface SimpleFetchWindowController ()
@property (strong) IBOutlet NSArrayController *fetchedResultsArrayController;
@property (strong) IBOutlet NSTextView *fetchCommandTextView;
@property (weak) IBOutlet NSTableView *fetchedResultsTableView;
@end

#pragma mark -

@implementation SimpleFetchWindowController

#pragma mark - Action methods

- (IBAction)fetch:(id)sender
{
	[self _tryFetchModelObjectsCommand:self.fetchCommandString]
	|| [self _tryFetchDistinctValuesForOneKeyPathCommand:self.fetchCommandString]
	|| [self _tryFetchCountCommand:self.fetchCommandString];
}

- (IBAction)selectQueryText:(id)sender
{
	[self.fetchCommandTextView selectAll:nil];
}

#pragma mark - <NSWindowDelegate> methods

- (void)windowDidLoad
{
	self.fetchCommandString = (@"FETCH \"Token\""
							   @" WHERE \"language.fullName = 'Objective-C'\""
							   @" DISPLAY \"tokenName, tokenType.typeName, container.containerName, parentNode.kName\"");
	[self selectQueryText:nil];
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
	if (inputString == nil) {
		QLog(@"%@", @"Can't handle nil input string");
		return nil;  //TODO: Revisit how to handle nil.
	}

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
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];

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

- (void)_displayObjects:(NSArray *)fetchedObjects keyPaths:(NSArray *)keyPaths
{
	QLog(@"key paths to display: %@", keyPaths);

	// Clear out the table view.
	self.fetchedResultsArrayController.content = nil;
	for (NSTableColumn *tableColumn in [self.fetchedResultsTableView.tableColumns copy]) {
		[self.fetchedResultsTableView removeTableColumn:tableColumn];
	}

	// Reconstruct the table columns based on the key paths they're supposed to display.
	// **NOTE:** This logic only works if the table view is cell-based.  It would have to be changed if we were to make it view-based.
	NSMutableArray *sortDescriptors = [NSMutableArray array];
	for (NSString *keyPath in keyPaths) {
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

	// Repopulate the table view by plugging the array into array controller.
	self.fetchedResultsArrayController.sortDescriptors = sortDescriptors;
	self.fetchedResultsArrayController.content = fetchedObjects;
}

- (BOOL)_tryFetchModelObjectsCommand:(NSString *)commandString
{
	QLog(@"%@", @"trying plain fetch...");

	// Try to parse the command string.
	NSString *pattern = (@"FETCH \"(%ident%)\""
						 @"(?: WHERE \"(%lit%)\")?"
						 @" DISPLAY \"(%keypath%(?:(?:,\\s*%keypath%)*))\"");
	NSDictionary *captureGroups = [self _matchPattern:pattern toEntireString:commandString];
	if (captureGroups == nil) {
		return NO;
	}

	// Construct the specified array of objects.
	NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:captureGroups[@1]];
	req.predicate = [NSPredicate predicateWithFormat:captureGroups[@2]];
	NSError *error;
	NSArray *fetchedObjects = [self.docSetIndex.managedObjectContext executeFetchRequest:req error:&error];

	if (fetchedObjects == nil) {
		QLog(@"Error in plain fetch: %@", error);
		return NO;
	}

	// Plug the objects into the table view.
	NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@" \t\r\n,"];
	NSMutableArray *keyPaths = [[captureGroups[@3] componentsSeparatedByCharactersInSet:separators] mutableCopy];
	[keyPaths removeObject:@""];
	[self _displayObjects:fetchedObjects keyPaths:keyPaths];

	return YES;
}

- (BOOL)_tryFetchDistinctValuesForOneKeyPathCommand:(NSString *)commandString
{
	QLog(@"%@", @"trying fetch distinct...");

	// Try to parse the command string.
	NSString *pattern = (@"DISTINCT  \"(%ident%)\\.(%keypath%)\""
						 @"(?:  WHERE  \"(%lit%)\")?");
	NSDictionary *captureGroups = [self _matchPattern:pattern toEntireString:commandString];
	if (captureGroups == nil) {
		return NO;
	}

	// Construct the specified array of objects.
	NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:captureGroups[@1]];
	req.predicate = [NSPredicate predicateWithFormat:captureGroups[@3]];
	NSError *error;
	NSArray *fetchedObjects = [self.docSetIndex.managedObjectContext executeFetchRequest:req error:&error];

	if (fetchedObjects == nil) {
		QLog(@"Error in fetch distinct: %@", error);
		return NO;
	}

	NSArray *unsortedValues = [fetchedObjects valueForKeyPath:captureGroups[@2]];
	NSArray *distinctValues = [[NSSet setWithArray:unsortedValues] allObjects];

	// Plug the objects into the table view.
	[self _displayObjects:distinctValues keyPaths:@[@"self"]];

	return YES;
}

- (BOOL)_tryFetchCountCommand:(NSString *)commandString
{
	QLog(@"%@", @"trying fetch count...");

	// Try to parse the command string.
	NSString *pattern = (@"COUNT  \"(%ident%)\""
						 @"(?:  WHERE  \"(%lit%)\")?");
	NSDictionary *captureGroups = [self _matchPattern:pattern toEntireString:commandString];
	if (captureGroups == nil) {
		return NO;
	}

	// Construct the specified array of objects.
	NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:captureGroups[@1]];
	req.predicate = [NSPredicate predicateWithFormat:captureGroups[@2]];
	req.resultType = NSCountResultType;
	NSError *error;
	NSArray *fetchedObjects = [self.docSetIndex.managedObjectContext executeFetchRequest:req error:&error];

	if (fetchedObjects == nil) {
		QLog(@"Error in fetch count: %@", error);
		return NO;
	}

	// Plug the objects into the table view.
	[self _displayObjects:fetchedObjects keyPaths:@[@"self"]];

	return YES;
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
