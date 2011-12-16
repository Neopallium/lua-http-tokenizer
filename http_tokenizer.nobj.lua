
-- make generated variable nicer.
set_variable_format "%s"

c_module "http_tokenizer" {

-- enable FFI bindings support.
luajit_ffi = true,
luajit_ffi_load_cmodule = true,

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

c_function "request" {
	c_call "!http_tokenizer *" "http_tokenizer_new_request" {},
},
c_function "response" {
	c_call "!http_tokenizer *" "http_tokenizer_new_response" {},
},
}

