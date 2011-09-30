#include <assert.h>
#include <stdlib.h>

#include "http_tokenizer.h"

#include "http-parser/http_parser.h"

/**
 * HTTP tokenizer object.
 *
 * @ingroup Objects
 */
struct http_tokenizer {
	http_parser parser;   /**< embedded http_parser. */
	http_token  *tokens;  /**< array of parsed tokens. */
	uint32_t    count;    /**< number of parsed tokens. */
	uint32_t    len;      /**< length of tokens array. */
};

#define INIT_TOKENS 32
#define GROW_TOKENS 128

static int http_tokenizer_grow(http_tokenizer* tokenizer) {
	uint32_t    old_len = tokenizer->len;
	uint32_t    len = old_len + GROW_TOKENS;
	http_token  *tokens;

	if(len > HTTP_TOKENIZER_MAX_TOKENS) return -1;

	tokens = (http_token *)realloc(tokenizer->tokens, sizeof(http_token) * len);
	if(tokens == NULL) return -1;
	tokenizer->tokens = tokens;
	tokenizer->len = len;
	return 0;
}

#define HTTP_TOKENIZER_GROW_CHECK(tokenizer) do { \
	if((tokenizer)->count >= (tokenizer)->len) { \
		if(http_tokenizer_grow(tokenizer) != 0) { \
			return -1; \
		} \
	} \
} while(0)

/* push token with no data. */
static int http_push_token(http_parser* parser, int token_id) {
	http_tokenizer* tokenizer = (http_tokenizer*)parser;
	uint32_t idx = tokenizer->count++;
	http_token *token;

	HTTP_TOKENIZER_GROW_CHECK(tokenizer);

	token = tokenizer->tokens + idx;
	token->id = token_id;
	token->off = 0;
	token->len = 0;

	return 0;
}

/* push token with data. */
static int http_push_data_token(http_parser* parser, int token_id, const char *data, size_t len) {
	http_tokenizer* tokenizer = (http_tokenizer*)parser;
	const char *data_start = (const char *)parser->data;
	uint32_t idx = tokenizer->count++;
	http_token *token;

	HTTP_TOKENIZER_GROW_CHECK(tokenizer);

	token = tokenizer->tokens + idx;
	token->id = token_id;
	token->off = (data - data_start);
	token->len = len;

	return 0;
}

static int http_tokenizer_message_begin_cb(http_parser* parser) {
	return http_push_token(parser, HTTP_TOKEN_MESSAGE_BEGIN);
}

static int http_tokenizer_url_cb(http_parser* parser, const char* data, size_t len) {
	if(len == 0) return 0;
	return http_push_data_token(parser, HTTP_TOKEN_URL, data, len);
}

static int http_tokenizer_header_field_cb(http_parser* parser, const char* data, size_t len) {
	if(len == 0) return 0;
	return http_push_data_token(parser, HTTP_TOKEN_HEADER_FIELD, data, len);
}

static int http_tokenizer_header_value_cb(http_parser* parser, const char* data, size_t len) {
	if(len == 0) return 0;
	return http_push_data_token(parser, HTTP_TOKEN_HEADER_VALUE, data, len);
}

static int http_tokenizer_headers_complete_cb(http_parser* parser) {
	return http_push_token(parser, HTTP_TOKEN_HEADERS_COMPLETE);
}

static int http_tokenizer_body_cb(http_parser* parser, const char* data, size_t len) {
	if(len == 0) return 0;
	return http_push_data_token(parser, HTTP_TOKEN_BODY, data, len);
}

static int http_tokenizer_message_complete_cb(http_parser* parser) {
	return http_push_token(parser, HTTP_TOKEN_MESSAGE_COMPLETE);
}

static void http_tokenizer_reset_internal(http_tokenizer* tokenizer) {
	http_parser* parser = &(tokenizer->parser);

	tokenizer->count = 0;
	http_parser_init(parser, parser->type);
	parser->data = NULL;
}

http_tokenizer *http_tokenizer_new(int is_request) {
	http_tokenizer* tokenizer;
	http_parser* parser;
	uint32_t len = INIT_TOKENS;

	tokenizer = (http_tokenizer *)malloc(sizeof(http_tokenizer));
	tokenizer->tokens = (http_token *)calloc(len, sizeof(http_token));
	tokenizer->len = len;
	tokenizer->count = 0;
	/* init. http parser. */
	parser = &(tokenizer->parser);
	if(is_request) {
		parser->type = HTTP_REQUEST;
	} else {
		parser->type = HTTP_RESPONSE;
	}
	http_tokenizer_reset_internal(tokenizer);

	return tokenizer;
}

void http_tokenizer_reset(http_tokenizer* tokenizer) {
	http_tokenizer_reset_internal(tokenizer);
}

void http_tokenizer_free(http_tokenizer* tokenizer) {
	free(tokenizer->tokens);
	tokenizer->tokens = NULL;
	free(tokenizer);
}

uint32_t http_tokenizer_execute(http_tokenizer* tokenizer, const char *data, uint32_t len) {
	http_parser*  parser = &(tokenizer->parser);

	static const http_parser_settings settings = {
		.on_message_begin    = http_tokenizer_message_begin_cb,
		.on_url              = http_tokenizer_url_cb,
		.on_header_field     = http_tokenizer_header_field_cb,
		.on_header_value     = http_tokenizer_header_value_cb,
		.on_headers_complete = http_tokenizer_headers_complete_cb,
		.on_body             = http_tokenizer_body_cb,
		.on_message_complete = http_tokenizer_message_complete_cb
	};

	/* clear old tokens. */
	tokenizer->count = 0;
	/* save start of data pointer for offset calculation. */
	parser->data = (void *)data;

	/* parse data into tokens. */
	return http_parser_execute(parser, &settings, data, len);
}

const http_token *http_tokenizer_get_tokens(http_tokenizer* tokenizer) {
	return tokenizer->tokens;
}

uint32_t http_tokenizer_count_tokens(http_tokenizer* tokenizer) {
	return tokenizer->count;
}

int http_tokenizer_should_keep_alive(http_tokenizer* tokenizer) {
	return http_should_keep_alive(&tokenizer->parser);
}

int http_tokenizer_is_upgrade(http_tokenizer* tokenizer) {
	return tokenizer->parser.upgrade;
}

int http_tokenizer_method(http_tokenizer* tokenizer) {
	return tokenizer->parser.method;
}

const char *http_tokenizer_method_str(http_tokenizer* tokenizer) {
	return http_method_str(tokenizer->parser.method);
}

int http_tokenizer_version(http_tokenizer* tokenizer) {
	return ((tokenizer->parser.http_major) << 16) + (tokenizer->parser.http_minor);
}

int http_tokenizer_status_code(http_tokenizer* tokenizer) {
	return tokenizer->parser.status_code;
}

int http_tokenizer_error(http_tokenizer* tokenizer) {
	return tokenizer->parser.http_errno;
}

const char *http_tokenizer_error_name(http_tokenizer* tokenizer) {
	return http_errno_name(tokenizer->parser.http_errno);
}

const char *http_tokenizer_error_description(http_tokenizer* tokenizer) {
	return http_errno_description(tokenizer->parser.http_errno);
}

