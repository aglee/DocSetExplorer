//
//  MOBToManyRelationshipItem.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBToOneRelationshipItem.h"

/*!
	Represents a to-many relationship.
 
	Each child item is an MOBIndexedItem representing one object on the "many" side of the relationship.
 */
@interface MOBToManyRelationshipItem : MOBPropertyItem
@end
