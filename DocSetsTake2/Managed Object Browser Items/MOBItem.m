//
//  MOBItem.m
//  DocSetsTake2
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBItem.h"
#import "MOBAttributeItem.h"
#import "MOBToManyRelationshipItem.h"
#import "MOBToOneRelationshipItem.h"

@interface MOBItem ()
@property (copy) NSArray *propertyItems;
@end

@implementation MOBItem

#pragma mark - Getters and setters

- (NSString *)displayedTitle
{
	return self.managedObject.className;
}

- (NSArray *)childItems
{
	// Lazy loading.
	if (self.propertyItems == nil) {
		self.propertyItems = [self _arrayWithPropertyItems];
	}
	return self.propertyItems;
}

#pragma mark - Private methods

- (NSArray *)_arrayWithPropertyItems
{
	NSMutableArray *items = [NSMutableArray array];
	NSEntityDescription *entity = self.managedObject.entity;
	NSDictionary *props = entity.propertiesByName;
	NSArray *sortedPropNames = [props.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	for (NSString *propName in sortedPropNames) {
		MOBItem *childItem = [self _itemForProperty:props[propName]];
		if (childItem) {
			[items addObject:childItem];
		}
	}

	return items;
}

- (MOBItem *)_itemForProperty:(NSPropertyDescription *)property
{
	if ([property isKindOfClass:[NSAttributeDescription class]]) {
		MOBAttributeItem *item = [[MOBAttributeItem alloc] init];
		item.managedObject = self.managedObject;
		item.propertyName = property.name;
		return item;
	} else if ([property isKindOfClass:[NSRelationshipDescription class]]) {
		if (((NSRelationshipDescription *)property).toMany) {
			MOBToManyRelationshipItem *item = [[MOBToManyRelationshipItem alloc] init];
			item.managedObject = self.managedObject;
			item.propertyName = property.name;
			return item;
		} else {
			MOBToOneRelationshipItem *item = [[MOBToOneRelationshipItem alloc] init];
			item.managedObject = [self.managedObject valueForKey:property.name];
			item.propertyName = property.name;
			return item;
		}
	}
	return nil;
}

@end
