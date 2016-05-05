//
//  MOBIndexedObjectItem.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBIndexedObjectItem.h"

@implementation MOBIndexedObjectItem

#pragma mark - MOBItem methods

- (id)propertyValue
{
	return ((NSSet *)[self.managedObject valueForKey:self.propertyName]).allObjects[self.objectIndex];
}

- (NSString *)displayedTitle
{
	return [NSString stringWithFormat:@"%@[%zd]", self.propertyName, self.objectIndex];
}

@end
