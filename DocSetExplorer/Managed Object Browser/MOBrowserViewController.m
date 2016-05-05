//
//  MOBrowserViewController.m
//  DocSetExplorer
//
//  Created by Andy Lee on 5/3/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBrowserViewController.h"
#import "MOBAttributeItem.h"
#import "MOBIndexedObjectItem.h"
#import "MOBToManyRelationshipItem.h"
#import "QuietLog.h"
#import <WebKit/WebKit.h>

@interface MOBrowserViewController ()
@property (strong) MOBItem *rootBrowserItem;
@end

@implementation MOBrowserViewController

#pragma mark - Getters and setters

- (NSManagedObject *)rootObject
{
	return self.rootBrowserItem.managedObject;
}

- (void)setRootObject:(NSManagedObject *)managedObject
{
	if (managedObject) {
		MOBItem *browserItem = [[MOBObjectItem alloc] init];
		browserItem.managedObject = managedObject;
		self.rootBrowserItem = browserItem;
	} else {
		self.rootBrowserItem = nil;
	}
	[self.objectBrowserView loadColumnZero];
	[self _updateDetailView];
}

#pragma mark - Action methods

- (IBAction)doBrowserAction:(id)sender
{
	[self _updateDetailView];
}

#pragma mark - NSViewController methods

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.objectBrowserView.defaultColumnWidth = 100;
}

#pragma mark - <NSBrowserDelegate> methods

- (id)rootItemForBrowser:(NSBrowser *)browser
{
	return self.rootBrowserItem;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(MOBItem *)item
{
	return item.childItems.count;
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(MOBItem *)item
{
	return item.childItems[index];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(MOBItem *)item
{
	return item.displayedTitle;
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(MOBItem *)item
{
	return (item.childItems == nil);
}

#pragma mark - Private methods

- (void)_updateDetailView
{
	NSIndexPath *indexPath = self.objectBrowserView.selectionIndexPath;
	if (indexPath.length == 0) {
		[self _updateDetailViewWithItem:self.rootBrowserItem];
	} else {
		[self _updateDetailViewWithItem:[self.objectBrowserView itemAtIndexPath:indexPath]];
	}
}

- (void)_updateDetailViewWithItem:(MOBItem *)item
{
	NSMutableString *html = [NSMutableString string];
	[html appendString:@"<html><head><title></title></head><body><pre>\n"];
	if (item == nil) {
		[html appendString:@"No item selected.\n"];
	} else {
		[self _appendDetailsOfItem:item toString:html];
	}
	[html appendString:@"</pre></body></html>"];

	[self.detailWebView.mainFrame loadHTMLString:html baseURL:nil];
}

- (void)_appendDetailsOfItem:(MOBItem *)item toString:(NSMutableString *)html
{
	NSManagedObject *obj = item.managedObject;
	NSString *prop = item.propertyName;

	// Check the MOBIndexedObjectItem case first, since it's a subclass of MOBObjectItem.
	if ([item isKindOfClass:[MOBObjectItem class]]) {

		if (prop == nil) {
			[html appendFormat:@"ROOT OBJECT (entity=%@)\n\n", obj.entity.name];
		} else if ([item isKindOfClass:[MOBIndexedObjectItem class]]) {
			NSString *dest = obj.entity.relationshipsByName[prop].destinationEntity.name;
			NSInteger index = ((MOBIndexedObjectItem *)item).objectIndex;
			[html appendFormat:@"%@[%zd] (entity=%@)\n\n", prop, index, dest];
		} else {
			[html appendFormat:@"%@ (entity=%@)\n\n", prop, obj.entity.name];
		}
		[self _appendDetailsOfObject:item.propertyValue toString:html];

	} else if ([item isKindOfClass:[MOBAttributeItem class]]) {

		[html appendFormat:@"%@ : %@\n", prop, [self _escapeAttribute:prop ofObject:obj]];

	} else if ([item isKindOfClass:[MOBToManyRelationshipItem class]]) {

		NSString *dest = obj.entity.relationshipsByName[prop].destinationEntity.name;
		NSInteger count = ((NSSet *)[obj valueForKey:prop]).count;
		[html appendFormat:@"%@ (entity=%@, count=%zd)\n", prop, dest, count];

	} else {

		QLog(@"+++ [ODD] Property item %@ has unexpected class %@", item, item.className);
		
	}
}

- (void)_appendDetailsOfObject:(NSManagedObject *)obj toString:(NSMutableString *)html
{
	NSEntityDescription *entity = obj.entity;
	NSArray *sortedNames;

	[html appendFormat:@"Attributes:\n"];
	sortedNames = [entity.attributeKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	for (NSString *prop in entity.attributeKeys) {
		[html appendFormat:@"  %@ : %@\n", prop, [self _escapeAttribute:prop ofObject:obj]];
	}
	[html appendString:@"\n"];

	[html appendFormat:@"To-one relationships:\n"];
	sortedNames = [entity.toOneRelationshipKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	for (NSString *prop in sortedNames) {
		NSString *dest = entity.relationshipsByName[prop].destinationEntity.name;
		[html appendFormat:@"  %@ (entity=%@)\n", prop, dest];
	}
	[html appendString:@"\n"];

	[html appendFormat:@"To-many relationships:\n"];
	sortedNames = [entity.toManyRelationshipKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	for (NSString *prop in sortedNames) {
		NSString *dest = entity.relationshipsByName[prop].destinationEntity.name;
		NSInteger index = ((NSSet *)[obj valueForKey:prop]).count;
		[html appendFormat:@"  %@ (entity=%@, count=%zd)\n", prop, dest, index];
	}
	[html appendString:@"\n"];
}

- (NSString *)_escapeAttribute:(NSString *)prop ofObject:(NSManagedObject *)obj
{
	NSString *valueString = [[obj valueForKey:prop] description];
	valueString = [valueString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	return valueString;
}

@end
