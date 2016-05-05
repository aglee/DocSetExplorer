//
//  MOBObjectItem.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBItem.h"

/*!
 * Represents a value that is a managed object.  If propertyName is nil, this is
 * the root object being browsed.  Otherwise, this is the value of the to-one
 * relationship specified by propertyName.
 */
@interface MOBObjectItem : MOBItem
@end
