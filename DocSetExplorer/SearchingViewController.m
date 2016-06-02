//
//  SearchingViewController.m
//  DocSetExplorer
//
//  Created by Andy Lee on 5/6/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "SearchingViewController.h"
#import "DSEWindowController.h"

@implementation SearchingViewController

@dynamic entityName;
@dynamic keyPathsString;
@dynamic distinct;
@dynamic predicateString;

#pragma mark - Action methods

- (IBAction)doSearch:(id)sender
{
	DSEWindowController *wc = (DSEWindowController *)self.view.window.delegate;
	[wc doSearchWithViewController:self];
}

@end
