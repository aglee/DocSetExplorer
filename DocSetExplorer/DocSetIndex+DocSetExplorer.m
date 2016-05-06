//
//  DocSetIndex+DocSetExplorer.m
//  DocSetExplorer
//
//  Created by Andy Lee on 5/5/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "DocSetIndex+DocSetExplorer.h"

@implementation DocSetIndex (DocSetExplorer)

+ (NSArray *)arrayWithStandardInstances
{
	NSMutableArray *array = [NSMutableArray array];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *docSetsDirPath = [self _standardDocSetsDirPath];
	NSError *error;
	NSArray *dirContents = [fm contentsOfDirectoryAtPath:docSetsDirPath error:&error];

	for (NSString *itemName in dirContents) {
		if ([itemName.pathExtension isEqualToString:@"docset"]) {
			NSString *docSetPath = [docSetsDirPath stringByAppendingPathComponent:itemName];
			DocSetIndex *docSetIndex = [[DocSetIndex alloc] initWithDocSetPath:docSetPath];
			NSArray *acceptedSuffixes = @[ @".documentation.OSX",
										   @".documentation.iOS",
										   @".documentation.watchOS",
										   @".documentation.tvOS" ];
			for (NSString *suffix in acceptedSuffixes) {
				if ([docSetIndex.bundleIdentifier hasSuffix:suffix]) {
					[array addObject:docSetIndex];
					break;
				}
			}
		}
	}

	return array;
}

- (NSURL *)documentationURLForObject:(id)obj
{
	if ([obj isKindOfClass:[DSAToken class]]) {
		return [self _documentationURLForToken:(DSAToken *)obj];
	} else if ([obj isKindOfClass:[DSANodeURL class]]) {
		return [self _documentationURLForNodeURL:(DSANodeURL *)obj];
	}

	return nil;
}

#pragma mark - Private methods

+ (NSString *)_standardDocSetsDirPath
{
	return [@"~/Library/Developer/Shared/Documentation/DocSets/" stringByExpandingTildeInPath];
}

- (NSString *)_documentsDirPath
{
	return [self.docSetPath stringByAppendingPathComponent:@"Contents/Resources/Documents"];
}

- (NSURL *)_documentationURLForToken:(DSAToken *)token
{
	NSString *pathString = [self _documentsDirPath];
	pathString = [pathString stringByAppendingPathComponent:token.metainformation.file.path];
	NSURL *url = [NSURL fileURLWithPath:pathString];
	if (token.metainformation.anchor) {
		NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
		urlComponents.fragment = token.metainformation.anchor;
		url = [urlComponents URL];
	}

	return url;
}

- (NSURL *)_documentationURLForNodeURL:(DSANodeURL *)nodeURLInfo
{
	NSString *pathString = [self _documentsDirPath];  //TODO: Handle fallback to online URL if local docset has not been installed.
	pathString = [pathString stringByAppendingPathComponent:nodeURLInfo.path];
	NSURL *url = [NSURL fileURLWithPath:pathString];;
	if (nodeURLInfo.anchor) {
		NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
		urlComponents.fragment = nodeURLInfo.anchor;
		url = [urlComponents URL];
	}

	return url;
}

@end
