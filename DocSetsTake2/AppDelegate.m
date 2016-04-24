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
#import "QuietLog.h"
#import "SimpleFetchWindowController.h"


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
	SimpleFetchWindowController *windowController = [[SimpleFetchWindowController alloc] initWithWindowNibName:@"SimpleFetchWindowController"];
	windowController.docSetIndex = self.docSetIndex;
	windowController.fetchCommandString = (@"FETCH \"Token\""
										   @" WHERE \"language.fullName = 'Objective-C'\""
										   @" DISPLAY \"tokenName, tokenType.typeName, container.containerName, parentNode.kName\"");
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
	NSString *pathToDocSetBundle = @"/Users/alee/_Developer/Cocoa Projects/AppKiDo/Exploration/com.apple.adc.documentation.OSX.docset";
	_docSetIndex = [[DocSetIndex alloc] initWithDocSetPath:pathToDocSetBundle];
	_windowControllers = [NSMutableArray array];

	// Do startup stuff.
	[self newFetchWindow:nil];
}

@end
