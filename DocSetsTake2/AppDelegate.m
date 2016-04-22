//
//  AppDelegate.m
//  DocSetsTake2
//
//  Created by Andy Lee on 4/16/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "AppDelegate.h"
#import "DocSetIndex.h"
#import "DocSetModel.h"
#import "QuietLog.h"
#import "SimpleFetchViewController.h"


@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (strong) SimpleFetchViewController *fetchViewController;
@end

#pragma mark -

@implementation AppDelegate

#pragma mark - Action methods

- (IBAction)fetch:(id)sender
{
	[self.fetchViewController fetch:sender];
}

- (IBAction)test:(id)sender
{
	// Do a dump of all instances of these entities.
//	NSArray *outerArray = (@[
//						   @[@"APILanguage", @"fullName"],
//						   @[@"DistributionVersion", @"distributionName", @"versionString"],
//						   @[@"DocSet", @"configurationVersion"],
////						   @[@"TokenGroup", @"title"],
//						   @[@"TokenType", @"typeName"],
//						   ]);
//	for (NSArray *innerArray in outerArray) {
//		NSString *entityName = innerArray[0];
//		NSArray *keyPathsToPrint = [innerArray subarrayWithRange:NSMakeRange(1, innerArray.count - 1)];
//		[self _printValues:keyPathsToPrint forEntity:entityName sort:keyPathsToPrint where:nil];
//	}


	// Print a list of all tokens of the specified type in the specified language.
//	NSString *languageName = @"Swift";  // Change this to examine a diffrent language.
//	NSString *tokenType = @"cl";
//	[self _printValues:@[
//						 @"tokenName",
////						 @"tokenUSR",
////						 @"superclassContainers.containerName",
////						 @"protocolContainers.containerName",
//						 ]
//			 forEntity:@"Token"
//				  sort:@[ @"tokenName" ]
//				 where:(@"language.fullName = %@ "
//						@"and tokenType.typeName = %@ "
//						), languageName, tokenType];


	// See what token types are used by each language in the docset.
//	NSArray *allLanguageNames = [[self.docSetIndex fetchEntity:@"APILanguage" sort:@[ @"fullName" ] where:nil] valueForKey:@"fullName"];
//	for (NSString *languageOfInterest in allLanguageNames) {
//		NSArray *allTokensForThisLanguage = [self.docSetIndex fetchEntity:@"Token" sort:nil where:@"language.fullName = %@", languageOfInterest];
//		NSMutableSet *setOfTokenTypes = [NSMutableSet set];
//		for (DSAToken *token in allTokensForThisLanguage) {
//			[setOfTokenTypes addObject:token.tokenType.typeName];
//		}
//		NSArray *arrayOfTokenTypes = [setOfTokenTypes sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
//		QLog(@"%@ token types: %@\n", languageOfInterest, arrayOfTokenTypes);
//	}


	[self _testFetch];
}

#pragma mark - <NSApplicationDelegate> methods

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSString *pathToDocSetBundle = @"/Users/alee/_Developer/Cocoa Projects/AppKiDo/Exploration/com.apple.adc.documentation.OSX.docset";
	_docSetIndex = [[DocSetIndex alloc] initWithDocSetPath:pathToDocSetBundle];
	_fetchViewController = [[SimpleFetchViewController alloc] init];
	self.fetchViewController.docSetIndex = self.docSetIndex;
	[self.window setContentView:self.fetchViewController.view];



	self.fetchViewController.fetchCommandString = (@"FETCH \"Token\""
												   @" WHERE \"language.fullName = 'Objective-C'\""
												   @" DISPLAY \"tokenName, tokenType.typeName, container.containerName, parentNode.kName\"");
}

#pragma mark - Private methods

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

- (void)_printValues:(NSArray *)keyPaths forEntity:(NSString *)entityName sort:(NSArray *)sortSpecifiers where:(NSString *)format, ...
{
	va_list argList;
	va_start(argList, format);
	NSArray *fetchedObjects = [self.docSetIndex fetchEntity:entityName sort:sortSpecifiers predicateFormat:format va_args:argList];
	va_end(argList);

	[self _printValues:keyPaths forObjects:fetchedObjects];
}

- (void)_testFetch
{
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Header"];
	NSEntityDescription *entityDescription = self.docSetIndex.managedObjectModel.entitiesByName[@"Header"];

	fetchRequest.resultType = NSDictionaryResultType;
	fetchRequest.propertiesToFetch = @[entityDescription.propertiesByName[@"frameworkName"]];
	fetchRequest.returnsDistinctResults = YES;

	// Do the fetch.
//	fetchRequest.returnsObjectsAsFaults = NO;  //[agl] DEBUGGING
//	fetchRequest.fetchLimit = 50;  //[agl] DEBUGGING
	__block NSError *error;
	__block NSArray *fetchedObjects;
	[self.docSetIndex.managedObjectContext performBlockAndWait:^{
		fetchedObjects = [self.docSetIndex.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	}];
	if (fetchedObjects == nil) {
		QLog(@"[%s] [ERROR] %@", __PRETTY_FUNCTION__, error);  //TODO: Throw an exception.
	} else {
		QLog(@"fetched objects: %@", fetchedObjects);
	}
}

@end
