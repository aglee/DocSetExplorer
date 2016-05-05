//
//  MOBrowserViewController.h
//  DocSetExplorer
//
//  Created by Andy Lee on 5/3/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;

/*!
	Allows drilling down into the values in NSManagedObject (namely, self.rootObject.).
	Uses detailWebView to display details of the selected NSBrowser item, for easier
	readability and the ability to select text for copy-pasting.
 */
@interface MOBrowserViewController : NSViewController <NSBrowserDelegate>

@property (weak) IBOutlet NSBrowser *objectBrowserView;
@property (weak) IBOutlet WebView *detailWebView;
@property (strong) NSManagedObject *rootObject;

- (IBAction)doBrowserAction:(id)sender;

@end
