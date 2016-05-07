//
//  SearchingViewController.m
//  DocSetExplorer
//
//  Created by Andy Lee on 5/6/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "SearchingViewController.h"
#import "DocSetExplorerWindowController.h"

@implementation SearchingViewController

@dynamic entityName;
@dynamic keyPathsString;
@dynamic distinct;
@dynamic predicateString;

#pragma mark - Action methods

- (IBAction)doSearch:(id)sender
{
	DocSetExplorerWindowController *wc = (DocSetExplorerWindowController *)self.view.window.delegate;
	[wc doSearchWithViewController:self];
}

@end