//
//  MOBIndexedItem.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBPropertyItem.h"

/*!
	managedObject is one of the "many" object values in a to-many relationship.  Used by ToMany in its childItems.  Note that to-many returns a set, so order of objects is not guaranteed same on every call.  Though very likely to be given that this app is read-only.
 */
@interface MOBIndexedItem : MOBPropertyItem
@property (assign) NSInteger objectIndex;
@end
