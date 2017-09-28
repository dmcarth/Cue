//
//  Parser.h
//  CocoaCue
//
//  Created by Dylan McArthur on 9/5/17.
//  Copyright © 2017 Dylan McArthur. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Parser : NSObject

- (instancetype)initWithString:(NSString *)str;

- (instancetype)initWithCString:(char *)buff len:(size_t)len;

- (void)printOutline;

@end
