#
# Lua HTTP tokenizer module
#
cmake_minimum_required(VERSION 2.8)

project(lua-http-tokenizer C)

set(BUILD_SHARED_LIBS TRUE)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set(INSTALL_CMOD ${CMAKE_INSTALL_PREFIX}/lib/lua/5.1 CACHE PATH
				"Directory to install Lua binary modules (configure lua via LUA_CPATH)")
set(LUA_NATIVE_OBJECTS_PATH ../LuaNativeObjects CACHE PATH
				"Directory to LuaNativeObjects bindings generator.")
set(USE_PRE_GENERATED_BINDINGS TRUE CACHE BOOL
				"Set this to FALSE to re-generate bindings using LuaNativeObjects")

set(COMMON_CFLAGS "${CFLAGS}")
set(COMMON_LDFLAGS)
set(COMMON_LIBS)

include(CustomMacros)

## LuaNativeObjects
include(LuaNativeObjects)

## Lua 5.1.x
include(FindLua51)
if(NOT ${LUA51_FOUND})
    message(FATAL_ERROR "The FindLua51 module could not find lua :-(")
endif()
if(WIN32)
	set(COMMON_CFLAGS "${COMMON_CFLAGS} -I${LUA_INCLUDE_DIR}")
	set(COMMON_LDFLAGS "${COMMON_LDFLAGS} ${LUA_LIBRARY}")
endif()
## MAC OSX needs extra linker flags
if(APPLE)
	set(COMMON_LDFLAGS "${COMMON_LDFLAGS} -undefined dynamic_lookup")
endif()

set(WARN_CFLAGS "-Wall -Wextra -Wshadow -W -pedantic -Wno-overlength-strings")
if(CMAKE_COMPILER_IS_GNUCC)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pipe ${WARN_CFLAGS} -std=gnu99 -fgnu89-inline")
	set(CMAKE_C_FLAGS_RELEASE        "${CMAKE_C_FLAGS_RELEASE}     -O3 -march=native -g")
	set(CMAKE_C_FLAGS_DEBUG          "${CMAKE_C_FLAGS_DEBUG}       -O0 -g")
	set(CMAKE_C_FLAGS_PROFILE        "${CMAKE_C_FLAGS_PROFILE}     -O2 -g -DNDEBUG")
	set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_WITHDEBINFO} -O2 -g")
endif(CMAKE_COMPILER_IS_GNUCC)

## setup git submodules

## Always disable HTTP_PARSER_DEBUG. (needed by FFI bindings)
set(COMMON_CFLAGS "${COMMON_CFLAGS} -DHTTP_PARSER_DEBUG=0")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -DHTTP_PARSER_STRICT=0")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DHTTP_PARSER_STRICT=1")
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

## Lua HTTP Tokenizer
set(LUA_HTTP_TOKENIZER_NOBJ_SRC
	http_tokenizer.nobj.lua
)
set(LUA_HTTP_TOKENIZER_SRC
	http-parser/http_parser.c
	http-parser/http_parser.h
	src/http_tokenizer.c
	src/http_tokenizer.h
)

if(${USE_PRE_GENERATED_BINDINGS})
	set(LUA_HTTP_TOKENIZER_NOBJ_SRC src/pre_generated-http_tokenizer.nobj.c)
else()
	# Generate Lua bindings.
	GenLuaNativeObjects(LUA_HTTP_TOKENIZER_NOBJ_SRC)
endif()
set(LUA_HTTP_TOKENIZER_SRC ${LUA_HTTP_TOKENIZER_SRC} ${LUA_HTTP_TOKENIZER_NOBJ_SRC})

add_library(lua-http_tokenizer MODULE ${LUA_HTTP_TOKENIZER_SRC})
target_link_libraries(lua-http_tokenizer ${COMMON_LIBS})
add_target_properties(lua-http_tokenizer COMPILE_FLAGS "${COMMON_CFLAGS}")
add_target_properties(lua-http_tokenizer LINK_FLAGS "${LD_FLAGS} ${COMMON_LDFLAGS}")
set_target_properties(lua-http_tokenizer PROPERTIES PREFIX "")
set_target_properties(lua-http_tokenizer PROPERTIES OUTPUT_NAME http_tokenizer)

install(TARGETS lua-http_tokenizer
        DESTINATION "${INSTALL_CMOD}")

