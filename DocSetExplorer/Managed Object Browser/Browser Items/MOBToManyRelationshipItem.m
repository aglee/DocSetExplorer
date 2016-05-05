//
//  MOBToManyRelationshipItem.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBToManyRelationshipItem.h"
#import "MOBIndexedObjectItem.h"

@implementation MOBToManyRelationshipItem

@synthesize childItems = _childItems;

#pragma mark - Getters and setters

- (NSArray *)childItems
{
	if (_childItems == nil) {
		NSMutableArray *items = [NSMutableArray array];
		NSSet *relatedObjects = self.propertyValue;
		for (NSInteger objectIndex = 0; objectIndex < relatedObjects.count; objectIndex++) {
			MOBIndexedObjectItem *item = [[MOBIndexedObjectItem alloc] init];
			item.managedObject = self.managedObject;
			item.propertyName = self.propertyName;
			item.objectIndex = objectIndex;

			[items addObject:item];
		}
		_childItems = items;
	}
	return _childItems;
}

- (NSString *)displayedTitle
{
	return [NSString stringWithFormat:@"%@ (%zd)", self.propertyName, self.childItems.count];
}

@end
