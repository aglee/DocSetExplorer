//
//  SimpleSearchViewController.m
//  DocSetExplorer
//
//  Created by Andy Lee on 5/6/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "SimpleSearchViewController.h"
#import "QuietLog.h"

@implementation SimpleSearchViewController

#pragma mark - Getters and setters

- (NSString *)entityName
{
	switch (self.entityTag) {
		case 0: {
			return @"Token";
		}
		case 1: {
			return @"NodeURL";
		}
		default: {
			QLog(@"+++ [ODD] %s Unexpected entity tag %zd", __PRETTY_FUNCTION__, self.entityTag);
			return nil;
		}
	}
}

- (NSString *)keyPathsString
{
	switch (self.entityTag) {
		case 0: {
			return @"tokenName, language.fullName, tokenType.typeName";
		}
		case 1: {
			return @"node.kName, fileName, anchor, path";
		}
		default: {
			QLog(@"+++ [ODD] %s Unexpected entity tag %zd", __PRETTY_FUNCTION__, self.entityTag);
			return @"";
		}
	}
}

- (BOOL)distinct
{
	return NO;
}

- (NSString *)predicateString
{
	NSString *pred = [self _predicateStringFragmentForStringMatch];

	// We can only impose language constraints for tokens -- nodes don't have a language.
	if (self.entityTag == 0) {
		NSMutableArray *langs = [NSMutableArray array];
		if (self.includeSwift) {
			[langs addObject:@"language.fullName = 'Swift'"];
		}
		if (self.includeObjectiveC) {
			[langs addObject:@"language.fullName = 'Objective-C'"];
		}
		if (self.includeC) {
			[langs addObject:@"language.fullName = 'C'"];
		}
		if (self.includeCPlusPlus) {
			[langs addObject:@"language.fullName = 'C++'"];
		}
		if (self.includeJavaScript) {
			[langs addObject:@"language.fullName = 'JavaScript'"];
		}

		NSString *langConstraint = [langs componentsJoinedByString:@" or "];
		pred = [NSString stringWithFormat:@"(%@) and (%@)", pred, langConstraint];
	}

	return pred;
}

#pragma mark - NSViewController methods

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.searchString = @"*view*";
	self.entityTag = 0;
	self.ignoreCase = YES;
	self.includeSwift = YES;
	self.includeObjectiveC = YES;
	self.includeC = YES;
	self.includeCPlusPlus = YES;
	self.includeJavaScript = YES;
}

#pragma mark - Private methods

- (NSString *)_predicateStringFragmentForStringMatch
{
	NSString *nameOfValueToMatch;
	switch (self.entityTag) {
		case 0: {
			nameOfValueToMatch = @"tokenName";
			break;
		}
		case 1: {
			nameOfValueToMatch = @"node.kName";
			break;
		}
		default: {
			QLog(@"+++ [ODD] %s Unexpected entity tag %zd", __PRETTY_FUNCTION__, self.entityTag);
			return @"";
		}
	}

	NSString *caseOption = (self.ignoreCase ? @"[c]" : @"");
	NSString *likeWhat = [self _punctuatedSearchString];
	return [NSString stringWithFormat:@"%@ like%@ %@", nameOfValueToMatch, caseOption, likeWhat];
}

- (NSString *)_punctuatedSearchString
{
	NSString *quotedString = self.searchString;
	quotedString = [quotedString stringByReplacingOccurrencesOfString:@"'" withString:@"\'"];
	quotedString = [quotedString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
	return [NSString stringWithFormat:@"'%@'", quotedString];
}

@end
