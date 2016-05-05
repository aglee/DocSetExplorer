//
//  MOBIndexedObjectItem.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBObjectItem.h"

/*!
 * Represents one of the "many" object values in a to-many relationship.  Note
 * Note that the value of this property is a set, so the order of objects is not
 * guaranteed.
 *
 * objectIndex is used to construct the displayedTitle.
 */
@interface MOBIndexedObjectItem : MOBObjectItem
@property (assign) NSInteger objectIndex;
@end
