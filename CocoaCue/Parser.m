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
	CueDocument *doc;
}

- (instancetype)initWithString:(NSString *)str
{
	self = [super init];
	if (self) {
		const char *buff = [str UTF8String];
		size_t len = strlen(buff);
		
		doc = cue_document_from_utf8(buff, len);
	}
	return self;
}

- (instancetype)initWithCString:(char *)buff len:(size_t)len
{
	self = [super init];
	if (self) {
		doc = cue_document_from_utf8(buff, len);
	}
	return self;
}

- (void)dealloc
{
	cue_document_free(doc);
}

- (void)printOutline
{
	s_node_print_description(cue_document_get_root(doc), 1);
}

@end
