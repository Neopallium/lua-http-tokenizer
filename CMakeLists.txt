cmake_minimum_required(VERSION 2.8)

project(lua-http-tokenizer C)

set(BUILD_SHARED_LIBS TRUE)

set(INSTALL_CMOD share/lua/cmod CACHE PATH "Directory to install Lua binary modules (configure lua via LUA_CPATH)")

## Lua 5.1.x
include(FindLua51)
if(!${LUA51_FOUND})
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
                    ${CMAKE_CURRENT_SOURCE_DIR}/http-tokenizer
                    ${LUA_INCLUDE_DIR})

add_library(tokenizer MODULE lhttp_tokenizer.c src/http_tokenizer.c http-parser/http_parser.c)
target_link_libraries(tokenizer ${LUA_LIBRARIES})
set_target_properties(tokenizer PROPERTIES PREFIX "")
set_target_properties(tokenizer PROPERTIES COMPILE_FLAGS "${CFLAGS}")
set_target_properties(tokenizer PROPERTIES OUTPUT_NAME tokenizer)

install(TARGETS tokenizer
        DESTINATION "${INSTALL_CMOD}/http")


## Setup test stuff
#include(CTest)
#add_test(test ${LUA} ${CMAKE_CURRENT_SOURCE_DIR}/test.lua ${CMAKE_CURRENT_SOURCE_DIR}/ ${CMAKE_CURRENT_BINARY_DIR}/)
#add_test(benchmark ${LUA} ${CMAKE_CURRENT_SOURCE_DIR}/benchmark.lua ${CMAKE_CURRENT_SOURCE_DIR}/ ${CMAKE_CURRENT_BINARY_DIR}/)
#set_tests_properties(test
#                     PROPERTIES
#                     FAIL_REGULAR_EXPRESSION
#                     "not ok")
