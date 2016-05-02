//
//  MOBAttributeItem.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBPropertyItem.h"

/*!
	managedObject is the owning object of which we are a property.
	
	childItems returns nil, indicating we are a leaf node.
 */
@interface MOBAttributeItem : MOBPropertyItem
@end
