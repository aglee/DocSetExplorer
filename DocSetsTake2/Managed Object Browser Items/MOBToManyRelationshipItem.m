//
//  MOBToManyRelationshipItem.m
//  DocSetsTake2
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBToManyRelationshipItem.h"
#import "MOBIndexedItem.h"

@interface MOBToManyRelationshipItem ()
@property (copy) NSArray *relatedObjectItems;
@end

@implementation MOBToManyRelationshipItem

#pragma mark - Getters and setters

- (NSArray *)childItems
{
	if (self.relatedObjectItems == nil) {
		NSMutableArray *items = [NSMutableArray array];
		NSSet *relatedObjects = [self.managedObject valueForKey:self.propertyName];
		NSInteger objectIndex = 0;

		for (NSManagedObject *obj in relatedObjects) {
			MOBIndexedItem *item = [[MOBIndexedItem alloc] init];
			item.managedObject = obj;
			item.propertyName = self.propertyName;
			item.objectIndex = objectIndex;
			[items addObject:item];

			objectIndex++;
		}

		self.relatedObjectItems = items;
	}
	return self.relatedObjectItems;
}

- (NSString *)displayedTitle
{
	return [NSString stringWithFormat:@"%@ (%@)", self.propertyName, @(self.childItems.count)];
}

@end
