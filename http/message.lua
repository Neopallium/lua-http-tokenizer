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

local setmetatable = setmetatable
local tonumber = tonumber
local assert = assert
local tconcat = table.concat

local http_tokenizer = require"http_tokenizer"

local parser_mt = {}
parser_mt.__index = parser_mt

function parser_mt:is_upgrade()
	return self.tokenizer:is_upgrade()
end

function parser_mt:should_keep_alive()
	return self.tokenizer:should_keep_alive()
end

function parser_mt:method()
	return self.tokenizer:method_str()
end

function parser_mt:version()
	local version = self.tokenizer:version()
	return (version / 65536), (version % 65536)
end

function parser_mt:status_code()
	return self.tokenizer:status_code()
end

function parser_mt:is_error()
	return self.tokenizer:is_error()
end

function parser_mt:error()
	return self.tokenizer:error(), self.tokenizer:error_name(), self.tokenizer:error_description()
end

function parser_mt:execute(data)
	return self.tokenizer:execute(self.handlers, data)
end

function parser_mt:execute_buffer(buf)
	return self.tokenizer:execute_buffer(self.handlers, buf)
end

function parser_mt:reset()
	self.tokenizer:reset()
	return self:on_reset()
end

function parser_mt:on_init()
end

function parser_mt:on_message_begin()
	print('default: on_message_begin')
end

function parser_mt:on_headers_complete()
	print('default: on_headers_complete')
end

function parser_mt:on_body()
	print('default: on_body')
end

function parser_mt:on_message_complete()
	print('default: on_message_complete')
end

local function create_parser(tokenizer)
	local self = {
		tokenizer = tokenizer,
	}

	local len = 0
	local headers
	local req
	local url

	local field
	local value
	local handlers = {
		[http_tokenizer.HTTP_TOKEN_MESSAGE_BEGIN] = function()
			req = self:on_message_begin()
			headers = req.headers
			len = 0
			field = nil
			value = nil
		end,
		[http_tokenizer.HTTP_TOKEN_URL] = function(data)
			req.method = self:method()
			if url then
				if data then
					url = url .. data
				end
			else
				url = data
			end
		end,
		[http_tokenizer.HTTP_TOKEN_HEADER_FIELD] = function(data)
			if value then
				headers[field] = value
				field = nil
				value = nil
			end
			if field then
				field = field .. data
			else
				field = data
			end
		end,
		[http_tokenizer.HTTP_TOKEN_HEADER_VALUE] = function(data)
			if value then
				value = value .. data
			else
				value = data
			end
		end,
		[http_tokenizer.HTTP_TOKEN_HEADERS_COMPLETE] = function(data)
			if value then
				headers[field] = value
				field = nil
				value = nil
			end
			req.url = url
			self:on_headers_complete()
		end,
		[http_tokenizer.HTTP_TOKEN_BODY] = function(data)
			return self:on_body(data)
		end,
		[http_tokenizer.HTTP_TOKEN_MESSAGE_COMPLETE] = function()
			url = nil
			headers = nil
			req = nil
			field = nil
			-- Send on_body(nil) message to comply with LTN12
			self:on_body()
			return self:on_message_complete()
		end,
	}
	local body_id = http_tokenizer.HTTP_TOKEN_BODY
	self.handlers = function(id, data)
		return handlers[id](data)
	end
	return setmetatable(self, parser_mt)
end

module(...)

function request()
	return create_parser(http_tokenizer.request())
end

function response()
	return create_parser(http_tokenizer.response())
end

