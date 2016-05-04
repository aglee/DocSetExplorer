//
//  MOBrowserViewController.h
//  DocSetExplorer
//
//  Created by Andy Lee on 5/3/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MOBItem;

@interface MOBrowserViewController : NSViewController <NSBrowserDelegate>

@property (weak) IBOutlet NSBrowser *objectBrowserView;
@property (weak) IBOutlet NSScrollView *detailScrollView;
@property (strong) MOBItem *rootBrowserItem;

- (IBAction)doBrowserAction:(id)sender;

@end
