//
//  DocSetIndex.m
//  DocSetsTake2
//
//  Created by Andy Lee on 4/17/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "DocSetIndex.h"

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
		_docSetPath = docSetPath;
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
	//	_managedObjectModel = [NSManagedObjectModel modelByMergingModels:nil];

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
	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeFileURL options:nil error:&error]) {
		coordinator = nil;
	}
	_persistentStoreCoordinator = coordinator;

	if (error) {
		//TODO: Better error handling when fail to create PSC.
		NSDictionary *dict = @{
							   NSLocalizedDescriptionKey: @"Failed to add the docset's persistent store.",
							   NSUnderlyingErrorKey: error,
							   };
		error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
		[[NSApplication sharedApplication] presentError:error];
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

@end