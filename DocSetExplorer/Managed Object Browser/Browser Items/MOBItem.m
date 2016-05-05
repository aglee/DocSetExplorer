//
//  MOBItem.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBItem.h"

@implementation MOBItem

#pragma mark - Getters and setters

- (id)propertyValue
{
	return [self.managedObject valueForKey:self.propertyName];
}

- (NSArray *)childItems
{
	abort();
	return nil;
}

- (NSString *)displayedTitle
{
	return self.propertyName;
}

@end
