#!/usr/bin/env lua

-- Make it easier to test
local src_dir, build_dir = ...
if ( src_dir ) then
    package.path  = src_dir .. "?.lua;" .. package.path
    package.cpath = build_dir .. "?.so;" .. package.cpath
end

local http_tokenizer = require 'http_tokenizer'

local pipeline = [[
GET / HTTP/1.1
Host: localhost
User-Agent: httperf/0.9.0
Connection: keep-alive

GET /header.jpg HTTP/1.1
Host: localhost
User-Agent: httperf/0.9.0
Connection: keep-alive

]]
pipeline = pipeline:gsub('\n', '\r\n')

local parser = http_tokenizer.request()
assert(parser:execute(pipeline) == #pipeline)
assert(parser:execute('') == 0)

assert(parser:should_keep_alive() == true)
assert(parser:method_str() == "GET")

