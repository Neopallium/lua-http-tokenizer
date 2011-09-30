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

typedef uint32_t httpoff_t;
typedef uint32_t httplen_t;

typedef struct http_token http_token;
struct http_token {
	int         id;
	httpoff_t   off;
	httplen_t   len;
}

typedef struct http_tokenizer http_tokenizer;

]]

object "http_tokenizer" {
	include"http_tokenizer.h",
	-- register epoll & http_tokenizer datastures with FFI.
	ffi_cdef(http_parser_type),
	ffi_cdef(http_tokenizer_type),
  constructor {
		var_in{ "bool", "is_request", is_optional = true },
		c_source[[
	${this} = http_tokenizer_new(${is_request});
]],
  },
  destructor {
		c_source[[
	http_tokenizer_free(${this});
]],
  },

  method "reset" {
		c_method_call "void" "http_tokenizer_reset" {},
  },

  method "execute" {
		c_method_call "size_t" "http_tokenizer_execute" { "const char *", "data", "size_t", "#data" },
  },

--[[
  method "get_tokens" {
  },
--]]

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

