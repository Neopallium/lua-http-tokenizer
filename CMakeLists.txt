#
# Lua HTTP tokenizer module
#
cmake_minimum_required(VERSION 2.8)

project(lua-http-tokenizer C)

set(BUILD_SHARED_LIBS TRUE)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set(INSTALL_CMOD share/lua/cmod CACHE PATH "Directory to install Lua binary modules (configure lua via LUA_CPATH)")
set(LUA_NATIVE_OBJECTS_PATH ../LuaNativeObjects CACHE PATH
				"Directory to LuaNativeObjects bindings generator.")
set(USE_PRE_GENERATED_BINDINGS TRUE CACHE BOOL
				"Set this to FALSE to re-generate bindings using LuaNativeObjects")

set(COMMON_CFLAGS "${CFLAGS}")
set(COMMON_LDFLAGS)
set(COMMON_LIBS)

## LuaNativeObjects
include(LuaNativeObjects)

## Lua 5.1.x
include(FindLua51)
if(NOT ${LUA51_FOUND})
	message(FATAL_ERROR "The FindLua51 module could not find lua :-(")
endif()

## setup git submodules

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/http-parser/http_parser.c")
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git/")
        execute_process(WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        COMMAND git submodule init)
        execute_process(WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        COMMAND git submodule update)
    else()
        execute_process(WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        COMMAND git clone "git://github.com/joyent/http-parser.git")
    endif()
endif()

include_directories(${CMAKE_CURRENT_SOURCE_DIR}
                    ${CMAKE_CURRENT_BINARY_DIR}
                    ${CMAKE_CURRENT_SOURCE_DIR}/http-parser
                    ${CMAKE_CURRENT_SOURCE_DIR}/src
                    ${LUA_INCLUDE_DIR})

## LuaEpoll
set(LUA_HTTP_TOKENIZER_SRC
	http_tokenizer.nobj.lua
)

if(${USE_PRE_GENERATED_BINDINGS})
	set(LUA_HTTP_TOKENIZER_SRC src/pre_generated-http_tokenizer.nobj.c)
else()
	# Generate Lua bindings.
	GenLuaNativeObjects(LUA_HTTP_TOKENIZER_SRC)
endif()

add_library(lua-http_tokenizer MODULE ${LUA_HTTP_TOKENIZER_SRC}
				src/http_tokenizer.c http-parser/http_parser.c)
target_link_libraries(lua-http_tokenizer ${COMMON_LIBS})
set_target_properties(lua-http_tokenizer PROPERTIES PREFIX "")
set_target_properties(lua-http_tokenizer PROPERTIES COMPILE_FLAGS "${COMMON_CFLAGS}")
set_target_properties(lua-http_tokenizer PROPERTIES OUTPUT_NAME http_tokenizer)

install(TARGETS lua-http_tokenizer
        DESTINATION "${INSTALL_CMOD}")

## Setup test stuff
#include(CTest)
#add_test(test ${LUA} ${CMAKE_CURRENT_SOURCE_DIR}/test.lua ${CMAKE_CURRENT_SOURCE_DIR}/ ${CMAKE_CURRENT_BINARY_DIR}/)
#add_test(benchmark ${LUA} ${CMAKE_CURRENT_SOURCE_DIR}/benchmark.lua ${CMAKE_CURRENT_SOURCE_DIR}/ ${CMAKE_CURRENT_BINARY_DIR}/)
#set_tests_properties(test
#                     PROPERTIES
#                     FAIL_REGULAR_EXPRESSION
#                     "not ok")
