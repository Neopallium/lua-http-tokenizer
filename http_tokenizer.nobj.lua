
-- make generated variable nicer.
set_variable_format "%s"

c_module "tokenizer" {

-- enable FFI bindings support.
--luajit_ffi = true,

export_definitions {
"HTTP_TOKEN_MESSAGE_BEGIN",
"HTTP_TOKEN_URL",
"HTTP_TOKEN_HEADER_FIELD",
"HTTP_TOKEN_HEADER_VALUE",
"HTTP_TOKEN_HEADERS_COMPLETE",
"HTTP_TOKEN_BODY",
"HTTP_TOKEN_MESSAGE_COMPLETE",
},

subfiles {
"src/http_tokenizer.nobj.lua",
},

c_function "new" {
	var_in{ "bool", "is_request", is_optional = true },
	var_out{ "!http_tokenizer *", "this" },
	c_source[[
	${this} = http_tokenizer_new(${is_request});
]],
},
}

