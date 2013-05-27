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

basetype "http_token *" "nil" "NULL"

object "http_tokenizer" {
	include"http_tokenizer.h",
	-- register http_token structure with FFI.
	ffi_cdef[[

typedef uint32_t httpoff_t;
typedef uint32_t httplen_t;

typedef struct http_token http_token;
struct http_token {
	uint32_t    id;
	httpoff_t   off;
	httplen_t   len;
};

int http_tokenizer_is_error(http_tokenizer* tokenizer);

]],
  destructor {
		c_method_call "void" "http_tokenizer_free" {},
  },

  method "reset" {
		c_method_call "void" "http_tokenizer_reset" {},
  },

  method "execute" {
		var_in{"<any>", "cbs"},
		var_in{"const char *", "data"},
		var_out{"uint32_t", "parsed_len"},
		c_source "pre" [[
	uint32_t n;
]],
		c_source[[
	luaL_checktype(L, ${cbs::idx}, LUA_TFUNCTION);
	do { /* loop to resume tokenization. */
]],
		ffi_source[[
	assert(type(${cbs}) == 'function', "Expected function for 'cbs' parameter.")
	repeat -- loop to resume tokenization
]],
		-- parse buffer into tokens.
		c_method_call { "uint32_t", "(nparsed)" } "http_tokenizer_execute"
			{ "const char *", "data", "uint32_t", "#data" },
		-- get tokens.
		c_method_call { "const http_token *", "(tokens)" } "http_tokenizer_get_tokens" {},
		c_method_call { "uint32_t", "(count)" } "http_tokenizer_count_tokens" {},
		-- process tokens.
		c_source[[
		/* track number of bytes parsed. */
		${parsed_len} += ${nparsed};
		/* process tokens. */
		for(n = 0; n < ${count}; n++, ${tokens}++) {
			lua_pushvalue(L, ${cbs::idx});
			lua_pushinteger(L, ${tokens}->id);
			if(${tokens}->len > 0) {
				lua_pushlstring(L, ${data} + ${tokens}->off, ${tokens}->len);
				lua_call(L, 2, 0);
			} else {
				lua_call(L, 1, 0);
			}
		}
		/* check if buffer is now empty. */
		if(${nparsed} == ${data_len}) {
			break;
		}
		/* check for errors. */
		if(http_tokenizer_is_error(${this})) {
			break;
		}
		/* update buffer pointer & length to remove parsed data. */
		${data} += ${nparsed};
		${data_len} -= ${nparsed};
		/* loop when there is more data to parse. */
	} while(1);
]],
		ffi_source[[
		-- track number of bytes parsed.
		${parsed_len} = ${parsed_len} + ${nparsed}
		-- call function with each event <id, data> pairs.
		for n=0,(${count}-1) do
			local len = ${tokens}[n].len
			if len > 0 then
				local start = ${tokens}[n].off+1
				${cbs}(${tokens}[n].id, ${data}:sub(start, start + len - 1))
			else
				${cbs}(${tokens}[n].id)
			end
		end
		-- check if buffer is now empty.
		if ${nparsed} == ${data_len} then
			break
		end
		-- check for errors.
		if C.http_tokenizer_is_error(${this}) then
			break
		end
		-- update buffer pointer & length to remove parsed data.
		${data} = ${data}:sub(${nparsed}+1)
		${data_len} = ${data_len} + ${nparsed}
		-- loop when there is more data to parse.
	until false
]],
  },

  method "execute_buffer" {
		var_in{"<any>", "cbs"},
		var_in{"Buffer", "buf"},
		var_out{"uint32_t", "parsed_len"},
		c_source "pre" [[
	uint32_t n;
]],
		c_source[[
	luaL_checktype(L, ${cbs::idx}, LUA_TFUNCTION);
	${data_len} = ${buf}_if->get_size(${buf});
	${data} = (const char *)${buf}_if->const_data(${buf});
	do { /* loop to resume tokenization. */
]],
		ffi_source[[
	assert(type(${cbs}) == 'function', "Expected function for 'cbs' parameter.")
	${data_len} = ${buf}_if.get_size(${buf})
	${data} = ${buf}_if.const_data(${buf})
	repeat -- loop to resume tokenization
]],
		-- parse buffer into tokens.
		c_method_call { "uint32_t", "(nparsed)" } "http_tokenizer_execute"
			{ "const char *", "(data)", "uint32_t", "(data_len)" },
		-- get tokens.
		c_method_call { "const http_token *", "(tokens)" } "http_tokenizer_get_tokens" {},
		c_method_call { "uint32_t", "(count)" } "http_tokenizer_count_tokens" {},
		-- process tokens.
		c_source[[
		/* track number of bytes parsed. */
		${parsed_len} += ${nparsed};
		/* process tokens. */
		for(n = 0; n < ${count}; n++, ${tokens}++) {
			lua_pushvalue(L, ${cbs::idx});
			lua_pushinteger(L, ${tokens}->id);
			if(${tokens}->len > 0) {
				lua_pushlstring(L, data + ${tokens}->off, ${tokens}->len);
				lua_call(L, 2, 0);
			} else {
				lua_call(L, 1, 0);
			}
		}
		/* check if buffer is now empty. */
		if(${nparsed} == ${data_len}) {
			break;
		}
		/* check for errors. */
		if(http_tokenizer_is_error(${this})) {
			break;
		}
		/* update buffer pointer & length to remove parsed data. */
		${data} += ${nparsed};
		${data_len} -= ${nparsed};
		/* loop when there is more data to parse. */
	} while(1);
]],
		ffi_source[[
		-- track number of bytes parsed.
		${parsed_len} = ${parsed_len} + ${nparsed}
		-- call function with each event <id, data> pairs.
		for n=0,(${count}-1) do
			local len = ${tokens}[n].len
			if len > 0 then
				local offset = ${tokens}[n].off
				${cbs}(${tokens}[n].id, ffi_string(${data} + offset, len))
			else
				${cbs}(${tokens}[n].id)
			end
		end
		-- check if buffer is now empty.
		if ${nparsed} == ${data_len} then
			break
		end
		-- check for errors.
		if C.http_tokenizer_is_error(${this}) then
			break
		end
		-- update buffer pointer & length to remove parsed data.
		${data} = ${data} + ${nparsed};
		${data_len} = ${data_len} + ${nparsed}
		-- loop when there is more data to parse.
	until false
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

  method "is_error" {
		c_method_call "bool" "http_tokenizer_is_error" {},
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

