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

local callback_names = {
	"on_message_begin",
	"on_url",
	"on_header",
	"on_headers_complete",
	"on_body",
	"on_message_complete",
}

local null_callbacks = {
on_message_begin = function()
end,
on_url = function(data)
end,
on_header = function(k,v)
end,
on_headers_complete = function()
end,
on_body = function(data)
end,
on_message_complete = function()
end,
}

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

function parser_mt:error()
	return self.tokenizer:error(), self.tokenizer:error_name(), self.tokenizer:error_description()
end

local function parser_execute(self, data, total_parsed)
	local tokenizer = self.tokenizer
	local len = #data
	local nparsed = tokenizer:execute(data)

	-- track tootal number of bytes parsed.
	total_parsed = total_parsed + nparsed

	if nparsed == len then
		-- all data parsed no errors.
		tokenizer:parse(self.handlers, data)
		return total_parsed
	end

	-- check for http-parser error.
	if tokenizer:is_error() then
		-- skip parsing of tokens on error.
		return total_parsed
	end

	-- tokenizer paused parsing parse tokens before continuing.
	tokenizer:parse(self.handlers, data)

	return parser_execute(self, data:sub(nparsed+1), total_parsed)
end

function parser_mt:execute(data)
	return parser_execute(self, data, 0)
end

function parser_mt:reset()
	return self.tokenizer:reset()
end

local function create_parser(tokenizer, cbs)
	local self = {
		tokenizer = tokenizer,
		cbs = cbs,
	}
	-- create null callbacks for missing ones.
	for i=1,#callback_names do
		local name = callback_names[i]
		if not cbs[name] then cbs[name] = null_callbacks[name] end
	end

	local last_id
	local len = 0
	local buf={}

	local field
	local handlers = {
		[http_tokenizer.HTTP_TOKEN_MESSAGE_BEGIN] = cbs.on_message_begin,
		[http_tokenizer.HTTP_TOKEN_URL] = function(data)
			if data then return cbs.on_url(data) end
		end,
		[http_tokenizer.HTTP_TOKEN_HEADER_FIELD] = function(data)
			if field then
				cbs.on_header(field, '')
			end
			field = data
		end,
		[http_tokenizer.HTTP_TOKEN_HEADER_VALUE] = function(data)
			if data then
				cbs.on_header(field, data)
				field = nil
			end
		end,
		[http_tokenizer.HTTP_TOKEN_HEADERS_COMPLETE] = function(data)
			if field then
				cbs.on_header(field, '')
				field = nil
			end
			cbs.on_headers_complete()
		end,
		[http_tokenizer.HTTP_TOKEN_BODY] = cbs.on_body,
		[http_tokenizer.HTTP_TOKEN_MESSAGE_COMPLETE] = function()
			field = nil
			-- Send on_body(nil) message to comply with LTN12
			cbs.on_body()
			return cbs.on_message_complete()
		end,
	reset = function()
		field = nil
	end,
	}
	local body_id = http_tokenizer.HTTP_TOKEN_BODY
	self.handlers = function(id, data)
		-- flush last event.
		if id ~= last_id and last_id then
			if len == 1 then
				handlers[last_id](buf[1])
				buf[1] = nil
			elseif len > 1 then
				local data = tconcat(buf, '', 1, len)
				handlers[last_id](data)
				for i=1,len do buf[i] = nil end
			else
				handlers[last_id]()
			end
			len = 0
			last_id = nil
		end
		if data and id ~= body_id then
			len = len + 1
			buf[len] = data
			last_id = id
		else
			handlers[id](data)
		end
	end
	return setmetatable(self, parser_mt)
end

module(...)

function request(cbs)
	return create_parser(http_tokenizer.request(), cbs)
end

function response(cbs)
	return create_parser(http_tokenizer.response(), cbs)
end

