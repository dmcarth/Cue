
#include "cue.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include <time.h>

#define CUE_OPTION_BENCH 1 << 0
#define CUE_OPTION_AST 1 << 1

typedef struct {
	uint32_t type;
} PError;

typedef struct {
	const char **file_paths;
	size_t num_file_paths;
	int bench_iterations;
	int options;
} CLIRequest;

CLIRequest *cli_request_new(const char *file_paths[],
							size_t num_file_paths,
							int bench_iterations,
							int options)
{
	CLIRequest *req = malloc(sizeof(CLIRequest));
	
	req->file_paths = file_paths;
	req->num_file_paths = num_file_paths;
	req->bench_iterations = bench_iterations;
	req->options = options;
	
	return req;
}

void cli_request_free(CLIRequest *req)
{
	free(req->file_paths);
	
	free(req);
}

typedef struct {
	char *buff;
	size_t len;
	size_t cap;
} String;

String *string_new(size_t cap)
{
	String *str = malloc(sizeof(String));
	
	str->buff = malloc(sizeof(char) * cap);
	str->len = 0;
	str->cap = cap;
	
	return str;
}

void string_free(String *str)
{
	free(str->buff);
	
	free(str);
}

void benchmark_parsing_string(String *str,
							  const char *file_name,
							  int iterations)
{
	clock_t clocks = 0;
	
	for (int i = 0; i < iterations; ++i) {
		clock_t t1 = clock();
		
		NodeAllocator *alloc = stack_allocator_new();
		CueDocument *doc = cue_document_from_utf8(alloc, str->buff, str->len);
		cue_document_free(doc);
		stack_allocator_free(alloc);
		
		clock_t t2 = clock();
		
		double time = (double)(t2 - t1) / (double)CLOCKS_PER_SEC;
		
		printf("%fs\n", time);
		
		clocks += t2 - t1;
	}
	
	double ticks = ((double)clocks / (double)iterations);
	double time = ticks / (double)CLOCKS_PER_SEC;
	
	printf("Averaged %f seconds parsing %s over %i iterations.\n", time,
		   file_name, iterations);
}

String *string_from_file_path(const char *file_path)
{
	FILE *file = fopen(file_path, "rb");
	
	if (!file) {
		perror("Error");
		return NULL;
	}
	
	fseek(file, 0, SEEK_END);
	long file_size = ftell(file);
	rewind(file);
	
	String *str = string_new(file_size);
	int c;
	while ((c = fgetc(file)) != EOF)
		str->buff[str->len++] = c;
	
	fclose(file);
	
	return str;
}

CLIRequest *parse_cli_request(const char *args[],
							  int num_args)
{
	int options = 0;
	const char **file_paths = malloc(sizeof(char*) * num_args);
	int num_file_paths = 0;
	int bench_iterations = 0;
	
	for (int i = 1; i < num_args; ++i) {
		if (strcmp(args[i], "--bench") == 0) {
			bench_iterations = atoi(args[++i]);
			if (!bench_iterations)
				bench_iterations = 20;
		} else if (strcmp(args[i], "--ast") == 0) {
			options |= CUE_OPTION_AST;
		} else {
			file_paths[num_file_paths++] = args[i];
		}
	}
	
	if (!num_file_paths)
		return NULL;
	
	CLIRequest *req = cli_request_new(file_paths, num_file_paths,
									  bench_iterations, options);
	
	return req;
}

void handle_request(CLIRequest *req)
{
	for (size_t i = 0; i < req->num_file_paths; ++i) {
		const char *file_path = req->file_paths[i];
		
		String *str = string_from_file_path(file_path);
		if (!str)
			break;
		
		if (req->bench_iterations) {
			benchmark_parsing_string(str, file_path, req->bench_iterations);
		}
		
		NodeAllocator *alloc = stack_allocator_new();
		CueDocument *doc = cue_document_from_utf8(alloc, str->buff, str->len);
		
		if (req->options & CUE_OPTION_AST) {
			ASTNode *root = cue_document_get_root(doc);
			ast_node_print_description(root, 1);
		}
		
		cue_document_free(doc);
		stack_allocator_free(alloc);
		
		string_free(str);
	}
}

int main(int argc,
		 const char * argv[])
{
	CLIRequest *req = parse_cli_request(argv, argc);
	
	if (!req) {
		printf("Error parsing arguments. :(\n");
		exit(1);
	}
	
	handle_request(req);
	
	cli_request_free(req);
	
	return 0;
}
