//
//  Parser.m
//  CocoaCue
//
//  Created by Dylan McArthur on 9/5/17.
//  Copyright © 2017 Dylan McArthur. All rights reserved.
//

#import "Parser.h"
#import "cue.h"

@implementation Parser
{
	CueParser *parser;
}

- (instancetype)initWithString:(NSString *)str
{
	self = [super init];
	if (self) {
		const char *buff = [str UTF8String];
		size_t len = strlen(buff);
		
		parser = cue_parser_from_utf8(buff, len);
	}
	return self;
}

- (instancetype)initWithCString:(char *)buff len:(size_t)len
{
	self = [super init];
	if (self) {
		parser = cue_parser_from_utf8(buff, len);
	}
	return self;
}

- (void)dealloc
{
	cue_parser_free(parser);
}

- (void)printOutline
{
	cue_node_print_description(cue_parser_get_root(parser), 1);
}

@end
