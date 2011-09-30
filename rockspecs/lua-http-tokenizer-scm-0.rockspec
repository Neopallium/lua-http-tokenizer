#!/usr/bin/env lua

package = 'lua-http-tokenizer'
version = 'scm-0'
source = {
    url = 'git://github.com/Neopallium/lua-http-tokenizer.git'
}
description = {
    summary  = "A HTTP protocol tokenizer",
    detailed = [[
This tokenizer parses the HTTP protocol into a list of tokens.
]],
    homepage = 'http://github.com/Neopallium/lua-http-tokenizer',
    license  = 'MIT', --as with Ryan's
}
dependencies = {
    'lua >= 5.1'
}
build = {
    type = 'cmake',
    variables = {
        INSTALL_CMOD      = "$(LIBDIR)",
        CMAKE_BUILD_TYPE  = "$(CMAKE_BUILD_TYPE)",
        ["CFLAGS:STRING"] = "$(CFLAGS)",
    },
}
