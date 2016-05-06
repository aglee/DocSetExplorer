//
//  DocSetIndex+DocSetExplorer.h
//  DocSetExplorer
//
//  Created by Andy Lee on 5/5/16.
//  Copyright © 2016 Andy Lee. All rights reserved.
//

#import "DocSetIndex.h"

@interface DocSetIndex (DocSetExplorer)

+ (NSArray *)arrayWithStandardInstances;

- (NSURL *)documentationURLForObject:(id)obj;

@end
