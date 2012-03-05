-- Copyright (c) 2011 by Robert G. Jakabosky <bobby@sharedrealm.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local http_tokenizer_type = [[

typedef struct http_parser http_parser;
struct http_parser {
  /** PRIVATE **/
  unsigned char type : 2;
  unsigned char flags : 6; /* F_* values from 'flags' enum; semi-public */
  unsigned char state;
  unsigned char header_state;
  unsigned char index;

  uint32_t nread;
  int64_t content_length;

  /** READ-ONLY **/
  unsigned short http_major;
  unsigned short http_minor;
  unsigned short status_code; /* responses only */
  unsigned char method;    /* requests only */
  unsigned char http_errno : 7;

  /* 1 = Upgrade header was present and the parser has exited because of that.
   * 0 = No upgrade header present.
   * Should be checked when http_parser_execute() returns in addition to
   * error checking.
   */
  unsigned char upgrade : 1;

  /** PUBLIC **/
  void *data; /* A pointer to get hook to the "connection" or "socket" object */
};

typedef uint32_t httpoff_t;
typedef uint32_t httplen_t;

typedef struct http_token http_token;
struct http_token {
	uint16_t    id;
	httpoff_t   off;
	httplen_t   len;
}

typedef struct http_tokenizer http_tokenizer;
struct http_tokenizer {
	http_parser parser;   /**< embedded http_parser. */
	http_token  *tokens;  /**< array of parsed tokens. */
	uint32_t    count;    /**< number of parsed tokens. */
	uint32_t    len;      /**< length of tokens array. */
};

const http_token *http_tokenizer_get_tokens(http_tokenizer* tokenizer);

uint32_t http_tokenizer_count_tokens(http_tokenizer* tokenizer);

]]

object "http_tokenizer" {
	include"http_tokenizer.h",
	-- register epoll & http_tokenizer datastures with FFI.
	ffi_cdef(http_tokenizer_type),
  destructor {
		c_method_call "void" "http_tokenizer_free" {},
  },

  method "reset" {
		c_method_call "void" "http_tokenizer_reset" {},
  },

  method "execute" {
		c_method_call "uint32_t" "http_tokenizer_execute" { "const char *", "data", "uint32_t", "#data" },
  },

  method "parse" {
		var_in{"<any>", "cbs"},
		var_in{"const char *", "data"},
		c_source[[
	const http_token *tokens = http_tokenizer_get_tokens(${this});
	uint32_t count = http_tokenizer_count_tokens(${this});
	uint32_t n;
	luaL_checktype(L, ${cbs::idx}, LUA_TFUNCTION);
	for(n = 0; n < count; n++, tokens++) {
		lua_pushvalue(L, ${cbs::idx});
		lua_pushinteger(L, tokens->id);
		if(tokens->len > 0) {
			lua_pushlstring(L, ${data} + tokens->off, tokens->len);
			lua_call(L, 2, 0);
		} else {
			lua_call(L, 1, 0);
		}
	}
]],
		ffi_source[[
	local count = tonumber(${this}.count)
	-- call function with each event <id, cbs> pairs.
	for n=0,(count-1) do
		local len = ${this}.tokens[n].len
		if len > 0 then
			local start = ${this}.tokens[n].off+1
			${cbs}(${this}.tokens[n].id, ${data}:sub(start, start + len - 1))
		else
			${cbs}(${this}.tokens[n].id)
		end
	end
]],
  },

  method "should_keep_alive" {
		c_method_call "bool" "http_tokenizer_should_keep_alive" {},
  },

  method "is_upgrade" {
		c_method_call "bool" "http_tokenizer_is_upgrade" {},
  },

  method "method" {
		c_method_call "int" "http_tokenizer_method" {},
  },

  method "method_str" {
		c_method_call "const char *" "http_tokenizer_method_str" {},
  },

  method "version" {
		c_method_call "int" "http_tokenizer_version" {},
  },

  method "status_code" {
		c_method_call "int" "http_tokenizer_status_code" {},
  },

  method "error" {
		c_method_call "int" "http_tokenizer_error" {},
  },

  method "error_name" {
		c_method_call "const char *" "http_tokenizer_error_name" {},
  },

  method "error_description" {
		c_method_call "const char *" "http_tokenizer_error_description" {},
  },
}

