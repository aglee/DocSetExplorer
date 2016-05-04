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

@implementation MOBrowserViewController

#pragma mark - Action methods

- (IBAction)doBrowserAction:(id)sender
{
	QLog(@"+++ %s", __PRETTY_FUNCTION__);
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
