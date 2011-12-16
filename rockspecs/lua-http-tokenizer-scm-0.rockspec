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
	type = 'builtin',
	modules = {
		http_tokenizer = {
			sources = {
				"http-parser/http_parser.c",
				"src/http_tokenizer.c",
				"src/pre_generated-http_tokenizer.nobj.c",
			},
		},
	},
	install = {
		lua = {
			['http_tokenizer.parser']  = "http/parser.lua",
		}
	}
}
