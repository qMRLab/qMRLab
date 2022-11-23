# This CMakeLists exists only to support CLion projects.
# It does not actually build the package.

cmake_minimum_required(VERSION 3.13)
project(octave_jsonstuff)

set(CMAKE_CXX_STANDARD 14)

include_directories(src)
include_directories(src/json)
include_directories(/usr/local/include/octave-4.4.1)

add_executable(octave_jsonstuff
        src/json/json-forwards.h
        src/json/json.h
        src/__jsonstuff_jsondecode_oct__.cc
        src/jsoncpp.cpp)
