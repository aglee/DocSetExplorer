//
//  MOBPropertyItem.m
//  DocSetExplorer
//
//  Created by Andy Lee on 4/27/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "MOBPropertyItem.h"

@implementation MOBPropertyItem

#pragma mark - MOBItem methods

- (NSString *)displayedTitle
{
	return self.propertyName;
}

@end
