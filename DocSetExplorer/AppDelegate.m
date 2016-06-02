//
//  AppDelegate.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/16/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "AppDelegate.h"
#import "DocSetIndex.h"
#import "DocSetModel.h"
#import "QuietLog.h"
#import "DocSetExplorerWindowController.h"


@interface AppDelegate ()
@property (strong) NSMutableArray *windowControllers;
@property (weak) id windowCloseObserver;
@end

#pragma mark -

@implementation AppDelegate

#pragma mark - Action methods

- (IBAction)newFetchWindow:(id)sender
{
	// Add a new window controller to our list.
	DocSetExplorerWindowController *windowController = [[DocSetExplorerWindowController alloc] initWithWindowNibName:@"DocSetExplorerWindowController"];
	[self.windowControllers addObject:windowController];

	// Ask to be notified when the window closes, so we can remove it from our list.
	self.windowCloseObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:windowController.window queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
		id windowDelegate = ((NSWindow *)note.object).delegate;
		[self.windowControllers removeObject:windowDelegate];
	}];

	// Display the window.
	[windowController showWindow:nil];
}

#pragma mark - <NSApplicationDelegate> methods

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// Initialize ivars.
//	NSString *pathToDocSetBundle = @"/Users/alee/Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.OSX.docset/";
//	_docSetIndex = [[DocSetIndex alloc] initWithDocSetPath:pathToDocSetBundle];
	_windowControllers = [NSMutableArray array];

	// Do startup stuff.
	[self newFetchWindow:nil];
}

@end
