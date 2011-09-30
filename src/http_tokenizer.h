/***************************************************************************
 * Copyright (C) 2007-2010 by Robert G. Jakabosky <bobby@neoawareness.com> *
 *                                                                         *
 ***************************************************************************/
#ifndef __HTTP_TOKENIZER_H__
#define __HTTP_TOKENIZER_H__

#include "http-parser/http_parser.h"

#define HT_LIB_API extern
#define HT_INLINE static inline

#define HTTP_TOKEN_MESSAGE_BEGIN      0
#define HTTP_TOKEN_URL                1
#define HTTP_TOKEN_HEADER_FIELD       2
#define HTTP_TOKEN_HEADER_VALUE       3
#define HTTP_TOKEN_HEADERS_COMPLETE   4
#define HTTP_TOKEN_BODY               5
#define HTTP_TOKEN_MESSAGE_COMPLETE   6

typedef uint32_t httpoff_t;
typedef uint32_t httplen_t;

#define HTTP_TOKENIZER_MAX_CHUNK_LENGTH sizeof(httplen_t)

typedef struct http_token http_token;
struct http_token {
	int         id;
	httpoff_t   off;
	httplen_t   len;
}

/**
 *
 * @ingroup Objects
 */
typedef struct http_tokenizer http_tokenizer;
struct http_tokenizer {
	http_parser parser;     /* embedded http_parser. */
	http_token  *tokens;
	uint32_t    count;
	uint32_t    len;
}

/**
 * Initialize HTTP tokenizer.
 *
 * @param tokenizer pointer to http_tokenizer structure to be initialized.
 * @public @memberof http_tokenizer
 */
HT_LIB_API void http_tokenizer_init(http_tokenizer *tokenizer, int );

/**
 * Reset HTTP tokenizer
 *
 * @param tokenizer pointer to http_tokenizer structure to be cleaned-up.
 * @public @memberof http_tokenizer
 */
HT_LIB_API void http_tokenizer_reset(http_tokenizer* tokenizer);

/**
 * Cleanup http_tokenizer structure.
 *
 * @param tokenizer pointer to http_tokenizer structure to be cleaned-up.
 * @public @memberof http_tokenizer
 */
HT_LIB_API void http_tokenizer_cleanup(http_tokenizer *tokenizer);

HT_LIB_API size_t http_tokenizer_execute(http_tokenizer* tokenizer, const char *data, size_t len);

HT_LIB_API int http_tokenizer_should_keep_alive(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_is_upgrade(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_method(http_tokenizer* tokenizer);

HT_LIB_API const char *http_tokenizer_method_str(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_version(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_status_code(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_error(http_tokenizer* tokenizer);

HT_LIB_API const char *http_tokenizer_error_name(http_tokenizer* tokenizer);

HT_LIB_API const char *http_tokenizer_error_description(http_tokenizer* tokenizer);

#endif /* __HTTP_TOKENIZER_H__ */
