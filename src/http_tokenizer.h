/***************************************************************************
 * Copyright (C) 2007-2010 by Robert G. Jakabosky <bobby@neoawareness.com> *
 *                                                                         *
 ***************************************************************************/
#ifndef __HTTP_TOKENIZER_H__
#define __HTTP_TOKENIZER_H__

#include <stddef.h>
#include <stdint.h>

#define HT_LIB_API extern
#define HT_INLINE static inline

#define HTTP_TOKENIZER_MAX_TOKENS		4096

#define HTTP_TOKEN_MESSAGE_BEGIN      0
#define HTTP_TOKEN_URL                1
#define HTTP_TOKEN_HEADER_FIELD       2
#define HTTP_TOKEN_HEADER_VALUE       3
#define HTTP_TOKEN_HEADERS_COMPLETE   4
#define HTTP_TOKEN_BODY               5
#define HTTP_TOKEN_MESSAGE_COMPLETE   6

typedef uint32_t httpoff_t;
typedef uint32_t httplen_t;

#define HTTP_TOKENIZER_MAX_CHUNK_LENGTH (2 ^ (sizeof(httplen_t) * 8))

typedef struct http_token http_token;
struct http_token {
	uint32_t    id;   /**< token id. */
	httpoff_t   off;  /**< token offset. */
	httplen_t   len;  /**< token length. */
};

typedef struct http_tokenizer http_tokenizer;

/**
 * Create HTTP Response tokenizer.
 *
 * @return tokenizer pointer to new http_tokenizer.
 * @public @memberof http_tokenizer
 */
HT_LIB_API http_tokenizer *http_tokenizer_new_response();

/**
 * Create HTTP Request tokenizer.
 *
 * @return tokenizer pointer to new http_tokenizer.
 * @public @memberof http_tokenizer
 */
HT_LIB_API http_tokenizer *http_tokenizer_new_request();

/**
 * Free instance of http_tokenizer.
 *
 * @param tokenizer pointer to http_tokenizer instance to free
 * @public @memberof http_tokenizer
 */
HT_LIB_API void http_tokenizer_free(http_tokenizer *tokenizer);

/**
 * Reset HTTP tokenizer
 *
 * @param tokenizer pointer to http_tokenizer structure to be cleaned-up.
 * @public @memberof http_tokenizer
 */
HT_LIB_API void http_tokenizer_reset(http_tokenizer* tokenizer);

HT_LIB_API uint32_t http_tokenizer_execute(http_tokenizer* tokenizer, const char *data, uint32_t len);

HT_LIB_API const http_token *http_tokenizer_get_tokens(http_tokenizer* tokenizer);

HT_LIB_API uint32_t http_tokenizer_count_tokens(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_should_keep_alive(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_is_upgrade(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_method(http_tokenizer* tokenizer);

HT_LIB_API const char *http_tokenizer_method_str(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_version(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_status_code(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_is_error(http_tokenizer* tokenizer);

HT_LIB_API int http_tokenizer_error(http_tokenizer* tokenizer);

HT_LIB_API const char *http_tokenizer_error_name(http_tokenizer* tokenizer);

HT_LIB_API const char *http_tokenizer_error_description(http_tokenizer* tokenizer);

#endif /* __HTTP_TOKENIZER_H__ */
