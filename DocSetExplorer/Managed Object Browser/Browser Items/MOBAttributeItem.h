//
//  MOBAttributeItem.h
//  DocSetExplorer
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBItem.h"

/*!
 * Represents and attribute of a managed object.  Returns nil for childItems,
 * indicating it is a leaf node in the NSBrowser.
 */
@interface MOBAttributeItem : MOBItem
@end
