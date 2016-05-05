//
//  MOBAttributeItem.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/26/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBAttributeItem.h"

@implementation MOBAttributeItem

#pragma mark - MOBItem methods

- (NSArray *)childItems
{
	return nil;
}

- (NSString *)displayedTitle
{
	return [NSString stringWithFormat:@"%@ : %@", self.propertyName, self.propertyValue];
}

@end
