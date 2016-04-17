//
//  AppDelegate.m
//  DocSetsTake2
//
//  Created by Andy Lee on 4/16/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "AppDelegate.h"
#import "DocSetModel.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
- (IBAction)test:(id)sender;
@end


@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

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
	NSURL *storeFileURL = [NSURL fileURLWithPath:[self _pathToDocSetStoreFile]];
	NSError *error;
	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeFileURL options:nil error:&error]) {
		coordinator = nil;
	}
	_persistentStoreCoordinator = coordinator;

	if (error) {
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

#pragma mark - Action methods

- (IBAction)test:(id)sender
{
	NSLog(@"entity names: %@", self.managedObjectModel.entitiesByName.allKeys);
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Token"];
	fetchRequest.fetchLimit = 100;
	NSError *fetchError;
	NSArray *tokens = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
	DSAToken *firstToken = tokens.firstObject;

	NSLog(@"first token: %@", firstToken);
}

#pragma mark - Private methods

- (NSString *)_pathToDocSetBundle
{
	return @"/Users/alee/_Developer/Cocoa Projects/AppKiDo/Exploration/com.apple.adc.documentation.OSX.docset";
}

- (NSString *)_pathToDocSetStoreFile
{
	return [[self _pathToDocSetBundle] stringByAppendingPathComponent:@"Contents/Resources/docSet.dsidx"];
}

@end
