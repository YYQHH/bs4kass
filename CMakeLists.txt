cmake_minimum_required(VERSION 3.14)
project(bs4kass C)

file(GLOB CORE_FILES ${PROJECT_SOURCE_DIR}/*.c)
add_executable(bs4kass ${CORE_FILES})

set(CMAKE_C_STANDARD 99)
set_property(TARGET bs4kass PROPERTY C_STANDARD 99)

add_definitions(-DXML_STATIC)

if(MSVC)
  add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif()

option(BS4KASS_USE_SYSTEM_LIBS "Use system-installed FFmpeg and Expat instead of building them from source" OFF)

set(_bs4kass_dep_includes)
set(_bs4kass_dep_libs)

if(BS4KASS_USE_SYSTEM_LIBS)
  set(_ffmpeg_root_hint "" CACHE PATH "Root directory of the FFmpeg installation")

  set(_ffmpeg_roots)
  if(_ffmpeg_root_hint)
    list(APPEND _ffmpeg_roots ${_ffmpeg_root_hint})
  endif()
  if(DEFINED ENV{FFMPEG_ROOT})
    list(APPEND _ffmpeg_roots $ENV{FFMPEG_ROOT})
  endif()
  list(APPEND _ffmpeg_roots
    ${PROJECT_SOURCE_DIR}/vendor
    ${PROJECT_SOURCE_DIR}/vendor/lib-msvc-x64
  )

  find_path(FFMPEG_INCLUDE_DIR
    NAMES libavformat/avformat.h
    HINTS ${_ffmpeg_roots}
    PATH_SUFFIXES include
  )

  if(NOT FFMPEG_INCLUDE_DIR)
    message(FATAL_ERROR "Could not find FFmpeg headers (libavformat/avformat.h). Set _ffmpeg_root_hint or FFMPEG_ROOT.")
  endif()

  foreach(_lib avformat avcodec avutil)
    string(TOUPPER ${_lib} _lib_upper)
    find_library(${_lib_upper}_LIBRARY
      NAMES ${_lib} lib${_lib}
      HINTS ${_ffmpeg_roots}
      PATH_SUFFIXES lib lib64
    )
    if(NOT ${_lib_upper}_LIBRARY)
      message(FATAL_ERROR "Could not find FFmpeg library ${_lib}. Set _ffmpeg_root_hint or FFMPEG_ROOT.")
    endif()
    list(APPEND _bs4kass_dep_libs ${${_lib_upper}_LIBRARY})
  endforeach()

  find_package(EXPAT REQUIRED)
  list(APPEND _bs4kass_dep_includes ${FFMPEG_INCLUDE_DIR} ${EXPAT_INCLUDE_DIRS})
  list(APPEND _bs4kass_dep_libs ${EXPAT_LIBRARIES})
else()
  include(cmake/BuildFFmpeg.cmake)

  include(FetchContent)
  set(EXPAT_BUILD_DOCS OFF CACHE BOOL "" FORCE)
  set(EXPAT_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
  set(EXPAT_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  set(EXPAT_SHARED_LIBS OFF CACHE BOOL "" FORCE)
  FetchContent_Declare(
    bs4kass_expat
    URL https://github.com/libexpat/libexpat/releases/download/R_2_6_2/expat-2.6.2.tar.xz
    URL_HASH SHA256=ee14b4c5d8908b1bec37ad937607eab183d4d9806a08adee472c3c3121d27364
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    SOURCE_SUBDIR expat
  )
  FetchContent_GetProperties(bs4kass_expat)
  if(NOT bs4kass_expat_POPULATED)
    FetchContent_Populate(bs4kass_expat)
    add_subdirectory(${bs4kass_expat_SOURCE_DIR}/${bs4kass_expat_SUBDIR} ${bs4kass_expat_BINARY_DIR})
  endif()

  if(TARGET expat::expat)
    set(_bs4kass_expat_target expat::expat)
  elseif(TARGET expat)
    add_library(expat::expat ALIAS expat)
    set(_bs4kass_expat_target expat::expat)
  else()
    message(FATAL_ERROR "Could not locate an Expat target after populating FetchContent")
  endif()

  list(APPEND _bs4kass_dep_includes ${BS4KASS_FFMPEG_INCLUDE_DIR})
  list(APPEND _bs4kass_dep_libs bs4kass::avformat bs4kass::avcodec bs4kass::avutil ${_bs4kass_expat_target})
endif()

target_include_directories(bs4kass PRIVATE ${_bs4kass_dep_includes})

set(_platform_libs)
if(WIN32)
  list(APPEND _platform_libs bcrypt)
endif()

target_link_libraries(bs4kass PRIVATE ${_bs4kass_dep_libs} ${_platform_libs})

if(BS4KASS_USE_SYSTEM_LIBS)
  mark_as_advanced(FFMPEG_INCLUDE_DIR AVCODEC_LIBRARY AVFORMAT_LIBRARY AVUTIL_LIBRARY)
endif()
