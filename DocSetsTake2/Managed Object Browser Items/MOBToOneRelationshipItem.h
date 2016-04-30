//
//  MOBToOneRelationshipItem.h
//  DocSetsTake2
//
//  Created by Andy Lee on 4/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBPropertyItem.h"

/*!
	managedObject is the to-one object.

	Inherits childItems from MOBItem (derived from properties of managedObject).
 
	Could actually just use MOBPropertyItem -- I'm thinking the no-op subclass adds clarity?  By the same principle, should there be a no-op subclass of MOBItem called MOBRootObjectItem?
 */
@interface MOBToOneRelationshipItem : MOBPropertyItem
@end
