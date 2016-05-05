//
//  MOBObjectItem.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBObjectItem.h"
#import "MOBAttributeItem.h"
#import "MOBToManyRelationshipItem.h"

@implementation MOBObjectItem

@synthesize childItems = _childItems;

#pragma mark - MOBItem methods

- (id)propertyValue
{
	return (self.propertyName
			? [self.managedObject valueForKey:self.propertyName]
			: self.managedObject);
}

- (NSArray *)childItems
{
	// Lazy loading.
	if (_childItems == nil) {
		_childItems = [self.class _arrayWithPropertyItemsForManagedObject:self.propertyValue];
	}
	return _childItems;
}

#pragma mark - Private methods

+ (NSArray *)_arrayWithPropertyItemsForManagedObject:(NSManagedObject *)obj
{
	NSMutableArray *items = [NSMutableArray array];
	NSEntityDescription *entity = obj.entity;
	NSDictionary *props = entity.propertiesByName;
	NSArray *sortedPropNames = [props.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	for (NSString *propName in sortedPropNames) {
		MOBItem *childItem = [self.class _itemForProperty:props[propName] ofObject:obj];
		if (childItem) {
			[items addObject:childItem];
		}
	}

	return items;
}

+ (MOBItem *)_itemForProperty:(NSPropertyDescription *)property ofObject:(NSManagedObject *)obj
{
	if ([property isKindOfClass:[NSAttributeDescription class]]) {
		MOBAttributeItem *item = [[MOBAttributeItem alloc] init];
		item.managedObject = obj;
		item.propertyName = property.name;
		return item;
	} else if ([property isKindOfClass:[NSRelationshipDescription class]]) {
		if (((NSRelationshipDescription *)property).toMany) {
			MOBToManyRelationshipItem *item = [[MOBToManyRelationshipItem alloc] init];
			item.managedObject = obj;
			item.propertyName = property.name;
			return item;
		} else {
			MOBObjectItem *item = [[MOBObjectItem alloc] init];
			item.managedObject = obj;
			item.propertyName = property.name;
			return item;
		}
	}
	return nil;
}

@end
