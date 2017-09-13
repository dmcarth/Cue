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
	cue_document *doc;
}

- (instancetype)initWithString:(NSString *)str
{
	self = [super init];
	if (self) {
		uint16_t *buff = malloc(str.length * sizeof(uint16_t));
		
		[str getCharacters:buff];
		
		doc = cue_document_from_utf16(buff, str.length);
		
		free(buff);
	}
	return self;
}

- (void)dealloc
{
	cue_document_free(doc);
}

- (void)printOutline
{
	s_node_print_description(doc->root);
}

@end
