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


@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
- (IBAction)test:(id)sender;
@end


@implementation AppDelegate

#pragma mark - Action methods

- (IBAction)test:(id)sender
{
	NSLog(@"entity names: %@", self.docSetIndex.managedObjectModel.entitiesByName.allKeys);
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Token"];
	fetchRequest.fetchLimit = 100;
	NSError *fetchError;
	NSArray *tokens = [self.docSetIndex.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
	DSAToken *firstToken = tokens.firstObject;

	NSLog(@"first token: %@", firstToken);
}

#pragma mark - <NSApplicationDelegate> methods

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	NSString *pathToDocSetBundle = @"/Users/alee/_Developer/Cocoa Projects/AppKiDo/Exploration/com.apple.adc.documentation.OSX.docset";
	_docSetIndex = [[DocSetIndex alloc] initWithDocSetPath:pathToDocSetBundle];
}

@end
