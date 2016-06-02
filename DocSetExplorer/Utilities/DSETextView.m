//
//  DSETextView.m
//  DocSetExplorer
//
//  Created by Andy Lee on 5/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "DSETextView.h"
#import "DSEWindowController.h"

@implementation DSETextView

- (void)insertNewline:(id)sender
{
	(void)[NSApp sendAction:@selector(doSearch:) to:nil from:nil];
}

@end
