//
//  MOBPropertyItem.h
//  DocSetsTake2
//
//  Created by Andy Lee on 4/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBItem.h"

/*!
	Abstract class, used for all cells in the browser view.
 */
@interface MOBPropertyItem : MOBItem
@property (copy) NSString *propertyName;
@end
