//
//  MOBIndexedItem.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBIndexedItem.h"

@implementation MOBIndexedItem

#pragma mark - MOBItem methods

- (NSString *)displayedTitle
{
	return [NSString stringWithFormat:@"%@[%@]", self.propertyName, @(self.objectIndex)];
}

@end
