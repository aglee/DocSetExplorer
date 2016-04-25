//
//  DocSetIndex.m
//  DocSetsTake2
//
//  Created by Andy Lee on 4/17/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "DocSetIndex.h"
#import "QuietLog.h"

@interface DocSetIndex ()
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation DocSetIndex

// We need to explicitly synthesize these because we provide custom getter methods.
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

#pragma mark - Init/awake/dealloc

- (instancetype)initWithDocSetPath:(NSString *)docSetPath
{
	self = [super init];
	if (self) {
		_docSetPath = docSetPath;  //TODO: Fail if doesn't look like a docset bundle.
	}
	return self;
}

- (instancetype)init
{
	return [self initWithDocSetPath:nil];
}

#pragma mark - Getters and setters

- (NSManagedObjectModel *)managedObjectModel
{
	if (_managedObjectModel) {
		return _managedObjectModel;
	}

	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DocSetModel" withExtension:@"momd"];
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

	return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (_persistentStoreCoordinator) {
		return _persistentStoreCoordinator;
	}

	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
	NSString *pathToPersistentStoreFile = [self.docSetPath stringByAppendingPathComponent:@"Contents/Resources/docSet.dsidx"];
	NSURL *storeFileURL = [NSURL fileURLWithPath:pathToPersistentStoreFile];
	NSError *error;
	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType
								   configuration:nil
											 URL:storeFileURL
										 options:@{ NSReadOnlyPersistentStoreOption: @YES }
										   error:&error]) {
		coordinator = nil;
	}
	_persistentStoreCoordinator = coordinator;

	if (error) {
		QLog(@"[%s] [ERROR] %@", __PRETTY_FUNCTION__, error);  //TODO: Throw an exception.
		return nil;
	}

	return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
	if (_managedObjectContext) {
		return _managedObjectContext;
	}

	NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
	if (!coordinator) {
		return nil;
	}
	_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	_managedObjectContext.persistentStoreCoordinator = coordinator;

	return _managedObjectContext;
}

#pragma mark - Queries

- (NSString *)_documentsDirPath
{
	return [self.docSetPath stringByAppendingPathComponent:@"Contents/Resources/Documents"];
}

- (NSURL *)documentationURLForToken:(DSAToken *)token
{
	NSString *pathString = [self _documentsDirPath];
	pathString = [pathString stringByAppendingPathComponent:token.metainformation.file.path];
	NSURL *url = [NSURL fileURLWithPath:pathString];
	NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
	urlComponents.fragment = token.metainformation.anchor;

	return [urlComponents URL];
}

- (NSURL *)documentationURLForNode:(DSANode *)node
{
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"NodeURL"];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"node = %@", node];
	fetchRequest.predicate = predicate;
	NSError *error;
	NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

	if (fetchResults == nil) {
		QLog(@"+++ [ERROR] %s Fetch failed with error '%@'", __PRETTY_FUNCTION__, error);  //TODO: Handle fetch error.
		return nil;
	}
	if (fetchResults.count == 0) {
		QLog(@"[ODD] %s Got no NodeURL objects in fetch result", __PRETTY_FUNCTION__, error);
		return nil;
	}
	if (fetchResults.count > 1) {
		QLog(@"[ODD] %s Got multiple NodeURL objects in fetch result", __PRETTY_FUNCTION__, error);
		return nil;
	}

	DSANodeURL *nodeURLInfo = (DSANodeURL *)fetchResults.firstObject;
	//QLog(@"+++ [INFO] NodeURL says: baseURL=[%@], path=[%@], fileName=[%@], anchor=[%@] (compare with token's anchor=[%@])", nodeURLInfo.baseURL, nodeURLInfo.path, nodeURLInfo.fileName, nodeURLInfo.anchor, token.metainformation.anchor);

	NSString *pathString = [self _documentsDirPath];  //TODO: Handle fallback to online URL if local docset has not been installed.
	pathString = [pathString stringByAppendingPathComponent:nodeURLInfo.path];

	return [NSURL fileURLWithPath:pathString];
}

@end
