//
//  MOBItem.h
//  DocSetsTake2
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
	Use MOBItem for root object, thus does not correspond to a cell in the browser view.  managedObject is that object.  childItems is one for each property that is an attribute, to-one, or to-many.  We don't display fetched properties, at least not currently.  TODO: Would this be hard?
 */
@interface MOBItem : NSObject

@property (copy, readonly) NSString *displayedTitle;

/*! Meaning depends on which class, see subclass docs. */
@property (strong) NSManagedObject *managedObject;

/*! Meaning depends on which class.  Leaf nodes in the hierarchy return nil. */
@property (copy, readonly) NSArray<MOBItem *> *childItems;

@end
