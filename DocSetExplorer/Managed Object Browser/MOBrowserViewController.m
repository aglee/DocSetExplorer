//
//  MOBrowserViewController.m
//  DocSetExplorer
//
//  Created by Andy Lee on 5/3/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBrowserViewController.h"
#import "MOBItem.h"
#import "QuietLog.h"

@interface MOBrowserViewController ()
@property (strong) MOBItem *rootBrowserItem;
@end

@implementation MOBrowserViewController

#pragma mark - Getters and setters

- (NSManagedObject *)managedObject
{
	return self.rootBrowserItem.managedObject;
}

- (void)setManagedObject:(NSManagedObject *)managedObject
{
	if (managedObject) {
		MOBItem *browserItem = [[MOBItem alloc] init];
		browserItem.managedObject = managedObject;
		self.rootBrowserItem = browserItem;
	} else {
		self.rootBrowserItem = nil;
	}
	[self.objectBrowserView loadColumnZero];
}

#pragma mark - Action methods

- (IBAction)doBrowserAction:(id)sender
{
	QLog(@"+++ %s", __PRETTY_FUNCTION__);
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

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
	return ((MOBItem *)item).childItems.count;
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
	return ((MOBItem *)item).childItems[index];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
	return ((MOBItem *)item).displayedTitle;
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item
{
	return (((MOBItem *)item).childItems == nil);
}

@end
