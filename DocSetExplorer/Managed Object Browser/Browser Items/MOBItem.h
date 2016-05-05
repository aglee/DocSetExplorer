//
//  MOBItem.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * Abstract class used by MOBBrowserViewController for the "item" objects in its
 * NSBrowser.  An MOBItem represents the property propertyName of the object
 * managedObject.
 *
 * If propertyName is nil, the MOBItem represents managedObject itself.  You can
 * can think of nil as equivalent to the property name "self".  The root object
 * of the NSBrowser has a nil propertyName.
 *
 * If the item is an MOBAttributeItem, it returns nil for childItems, indicating
 * it is a leaf node in the NSBrowser.
 *
 * displayedTitle is what the NSBrowser displays in the cell for this item.
 */
@interface MOBItem : NSObject

@property (strong) NSManagedObject *managedObject;
@property (copy) NSString *propertyName;
@property (strong, readonly) id propertyValue;
/*! Subclasses must override. */
@property (copy, readonly) NSArray<MOBItem *> *childItems;
@property (copy, readonly) NSString *displayedTitle;

@end
