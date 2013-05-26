#!/usr/bin/env lua
local socket = require"socket"
local time = socket.gettime
local clock = os.clock
local quiet = false
local disable_gc = true
local type = type
local tconcat = table.concat

if arg[1] == '-gc' then
    disable_gc = false
    table.remove(arg,1)
else
    print"GC is disabled so we can track memory usage better"
    print""
end

local N=tonumber(arg[1]) or 10000

local function printf(fmt, ...)
    local res
    if not quiet then
        fmt = fmt or ''
        res = print(string.format(fmt, ...))
        io.stdout:flush()
    end
    return res
end

local function full_gc()
    -- make sure all free-able memory is freed
    collectgarbage"collect"
    collectgarbage"collect"
    collectgarbage"collect"
end

local function bench(name, N, func, ...)
    local start1,start2
    printf('run bench: %s', name)
    start1 = clock()
    start2 = time()
    func(N, ...)
    local diff1 = (clock() - start1)
    local diff2 = (time() - start2)
    printf("total time: %10.6f (%10.6f) seconds", diff1, diff2)
    return diff1, diff2
end

local lhp = require 'http.parser'

local function parse_path_query_fragment(uri)
    local path, query, fragment, off
    -- parse path
    path, off = uri:match('([^?]*)()')
    -- parse query
    if uri:sub(off, off) == '?' then
        query, off = uri:match('([^#]*)()', off + 1)
    end
    -- parse fragment
    if uri:sub(off, off) == '#' then
        fragment = uri:sub(off + 1)
        off = #uri
    end
    return path or '/', query, fragment
end

local expects = {}
local requests = {}

-- NOTE: All requests must be version HTTP/1.1 since we re-use the same HTTP parser for all requests.
requests.ab = {
    "GET /foo/t.html?qstring#frag HTTP/1.1\r\nHost: localhost:8000\r\nUser-Agent: ApacheBench/2.3\r\nContent-Length: 5\r\nAccept: */*\r\n\r\nbody\n",
}

expects.ab = {
    method = "GET",
    url = "/foo/t.html?qstring#frag",
    path = "/foo/t.html",
    query_string = "qstring",
    fragment = "frag",
    headers = {
        Host = "localhost:8000",
        ["User-Agent"] = "ApacheBench/2.3",
        Accept = "*/*",
    },
    body = "body\n",
}

requests.no_buff_body = {
    "GET / HTTP/1.1\r\n",
    "Host: foo:80\r\n",
    "Content-Length: 12\r\n",
    "\r\n",
-- CONCAT not compiled on LuaJIT 2.0
    --"chunk1", "chunk2",
    "chunk1chunk2",
}

expects.no_buff_body = {
    method = "GET",
    body = "chunk1chunk2"
}

requests.httperf = {
    "GET / HTTP/1.1\r\nHost: localhost\r\nUser-Agent: httperf/0.9.0\r\n\r\n"
}

expects.httperf = {
    method = "GET",
    url = "/",
    path = "/",
    headers = {
        Host = "localhost",
        ["User-Agent"] = "httperf/0.9.0",
    },
}

requests.firefox = {
    "GET / HTTP/1.1\r\nHost: two.local:8000\r\nUser-Agent: Mozilla/5.0 (X11; U;Linux i686; en-US; rv:1.9.0.15)Gecko/2009102815 Ubuntu/9.04 (jaunty)Firefox/3.0.15\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language:en-gb,en;q=0.5\r\nAccept-Encoding: gzip,deflate\r\nAccept-Charset:ISO-8859-1,utf-8;q=0.7,*;q=0.7\r\nKeep-Alive: 300\r\nConnection:keep-alive\r\n\r\n"
}

expects.firefox = {
    method = "GET",
    url = "/",
    path = "/",
    headers = {
        ["User-Agent"] = "Mozilla/5.0 (X11; U;Linux i686; en-US; rv:1.9.0.15)Gecko/2009102815 Ubuntu/9.04 (jaunty)Firefox/3.0.15",
        Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-gb,en;q=0.5",
        ["Accept-Encoding"] = "gzip,deflate",
        ["Accept-Charset"] = "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
        ["Keep-Alive"] = "300",
        Connection = "keep-alive",
    }
}

local names_list = {}
local data_list = {}
for name, data in pairs(requests) do
    names_list[#names_list + 1] = name
    data_list[#data_list + 1] = data
end

local function init_parser(reqs)
    local cur          = nil
    local parser

    local cb           = {}
    function cb.on_message_begin()
        assert(cur == nil)
        cur = { headers = {} }
    end

    function cb.on_url(value)
        cur.url = value
        cur.path, cur.query_string, cur.fragment = parse_path_query_fragment(value)
    end

    function cb.on_body(value)
        if not cur.body then
            cur.body = value
        elseif nil ~= value then
            cur.body = cur.body .. value
        end
    end

    function cb.on_header(field, value)
        cur.headers[field] = value
    end

    function cb.on_headers_complete()
        cur.method = parser:method()
    end

    function cb.on_message_complete()
        assert(nil ~= cur)
        if reqs then table.insert(reqs, cur) end
        cur = nil
    end

    parser = lhp.request(cb)
    return parser
end

local function init_fast_parser(reqs)
    local cur          = nil
    local parser

    local cb           = {}
    function cb.on_message_begin()
        assert(cur == nil)
        cur = { headers = {} }
    end

    function cb.on_url(value)
        cur.url = value
    end

    function cb.on_body(value)
        if not cur.body then
            cur.body = value
        elseif nil ~= value then
            cur.body = cur.body .. value
        end
    end

    function cb.on_header(field, value)
        cur.headers[field] = value
    end

    function cb.on_headers_complete()
        cur.method = parser:method()
    end

    function cb.on_message_complete()
        assert(nil ~= cur)
        if reqs then reqs[#reqs+1] = cur end
        cur = nil
    end

    parser = lhp.request(cb)
    return parser
end

local function null_cb()
end
local null_cbs = {
    on_message_begin = null_cb,
    on_url = null_cb,
    on_header = null_cb,
    on_headers_complete = null_cb,
    on_body = null_cb,
    on_message_complete = null_cb,
}
local function init_null_parser()
    return lhp.request(null_cbs)
end

local function assert_deeply(got, expect, ...)
    if type(expect) ~= "table" then
        error("Expected [" .. context .. "] to be a table")
    end
    for k, v in pairs(expect) do
        if type(expect[k]) == "table" then
            assert_deeply(got[k], expect[k], k, ...)
        elseif got[k] ~= expect[k] then
            local ctx = table.concat({ ... }, '.')
            error("Expected [" .. ctx .. "] to be '" .. tostring(expect[k]) .. "', but got '" .. tostring(got[k]) .. "'")
        end
    end
end

local function good_client(parser, data)
    for i=1,#data do
        local line = data[i]
        local bytes_read = parser:execute(line)
        if bytes_read ~= #line then
          error("only ["..tostring(bytes_read).."] bytes read, expected ["..tostring(#line).."]")
        end
    end
end

local function bad_client(parser, data)
    for i=1,#data do
        local line = data[i]
        local total = 0
        for i=1,#line do
            local bytes_read = parser:execute(line:sub(i,i))
            if 1 ~= bytes_read then
              error("only ["..tostring(bytes_read).."] bytes read, expected ["..tostring(#line).."]")
            end
            total = total + 1
        end
        if total ~= #line then
          error("only ["..tostring(bytes_read).."] bytes read, expected ["..tostring(#line).."]")
        end
   end
end

local function apply_client(N, client, parser, requests)
    for i=1,N do
        for x=1,#requests do
            client(parser, requests[x])
            parser:reset()
        end
    end
end

local function apply_client_memtest(client)
    local start_mem, end_mem
    local N = client.mem_N
    
    local reqs = {}
    local parser = init_parser(reqs)
    full_gc()
    start_mem = (collectgarbage"count" * 1024)
    --print(client.name, 'start memory size: ', start_mem)
    if disable_gc then collectgarbage"stop" end
    apply_client(N, client.cb, parser, data_list)
    end_mem = (collectgarbage"count" * 1024)
    --print(client.name, 'end   memory size: ', end_mem)
    print(client.name, 'N=', N, 'total memory used: ', (end_mem - start_mem))
    print()
   
    -- validate parsed request data.
    local idx = 0
    for name, data in pairs(requests) do
        idx = idx + 1
        local got    = reqs[idx]
        local expect = expects[name]
        assert_deeply(got, expect, name)
    end
 
    reqs = nil
    parser = nil
    collectgarbage"restart"
    full_gc()
end

local function apply_client_speedtest(client)
    local start_mem, end_mem
    local N = client.speed_N
 
    local parser = init_fast_parser()
    full_gc()
    start_mem = (collectgarbage"count" * 1024)
    --print(client.name, 'start memory size: ', start_mem)
    if disable_gc then collectgarbage"stop" end
    local diff1, diff2 = bench(client.name, N, apply_client, client.cb, parser, data_list)
    end_mem = (collectgarbage"count" * 1024)
    local total = N * #data_list
    printf("units/sec: %10.6f (%10.6f) units/sec", total/diff1, total/diff2)
    --print(client.name, 'end   memory size: ', end_mem)
    print(client.name, 'N=', N, 'total memory used: ', (end_mem - start_mem))
    print()
   
    parser = nil
    collectgarbage"restart"
    full_gc()
end

local function per_parser_overhead(N)
    local start_mem, end_mem
    local parsers = {}
 
    -- pre-grow table
    for i=1,N do
        parsers[i] = true -- add place-holder values.
    end
    full_gc()
    start_mem = (collectgarbage"count" * 1024)
    --print('overhead: start memory size: ', start_mem)
    for i=1,N do
        parsers[i] = init_null_parser()
    end
    full_gc()
    end_mem = (collectgarbage"count" * 1024)
    --print('overhead: end   memory size: ', end_mem)
    print('overhead: total memory used: ', (end_mem - start_mem) / N, ' bytes per parser')
   
    parsers = nil
    full_gc()
end

local clients = {
    { name = 'good', cb = good_client, mem_N=1, speed_N=N*10},
    { name = 'bad', cb = bad_client, mem_N=1, speed_N=N},
}

local function run_test(apply)
    for idx,client in ipairs(clients) do
        apply(client)
    end
end

print('memory test')
run_test(apply_client_memtest)

print('speed test')
run_test(apply_client_speedtest)

print('overhead test')
per_parser_overhead(N)


