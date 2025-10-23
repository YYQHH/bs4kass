include(ExternalProject)

set(BS4KASS_FFMPEG_TAG "n6.1.1" CACHE STRING "FFmpeg git tag or commit to build when downloading the sources")
set(BS4KASS_FFMPEG_SOURCE "" CACHE PATH "Optional existing FFmpeg source directory to build instead of downloading")

set(_bs4kass_ffmpeg_prefix "${CMAKE_BINARY_DIR}/ffmpeg")
set(_bs4kass_ffmpeg_install "${_bs4kass_ffmpeg_prefix}/install")
set(_bs4kass_ffmpeg_source "${_bs4kass_ffmpeg_prefix}/src")

if(BS4KASS_FFMPEG_SOURCE)
  if(NOT IS_DIRECTORY "${BS4KASS_FFMPEG_SOURCE}")
    message(FATAL_ERROR "BS4KASS_FFMPEG_SOURCE does not point to a directory: ${BS4KASS_FFMPEG_SOURCE}")
  endif()
  set(_bs4kass_ffmpeg_source "${BS4KASS_FFMPEG_SOURCE}")
  set(_bs4kass_ffmpeg_download_args DOWNLOAD_COMMAND "")
else()
  set(_bs4kass_ffmpeg_download_args
    GIT_REPOSITORY https://github.com/FFmpeg/FFmpeg.git
    GIT_TAG ${BS4KASS_FFMPEG_TAG}
    GIT_SHALLOW TRUE
    UPDATE_COMMAND ""
  )
endif()

if(WIN32)
  find_program(BS4KASS_BASH_EXECUTABLE bash HINTS ENV PATH DOC "Path to bash executable used to configure FFmpeg")
  if(NOT BS4KASS_BASH_EXECUTABLE)
    message(FATAL_ERROR "bash was not found in PATH. Install Git for Windows or MSYS2 and ensure bash is available to build FFmpeg automatically.")
  endif()
  set(_bs4kass_ffmpeg_shell ${BS4KASS_BASH_EXECUTABLE})
else()
  find_program(_bs4kass_ffmpeg_shell sh)
  if(NOT _bs4kass_ffmpeg_shell)
    set(_bs4kass_ffmpeg_shell /bin/sh)
  endif()
endif()

if(MSVC)
  find_program(BS4KASS_NMAKE_EXECUTABLE nmake HINTS ENV PATH DOC "Path to nmake executable used to build FFmpeg")
  if(NOT BS4KASS_NMAKE_EXECUTABLE)
    message(FATAL_ERROR "nmake was not found. Run CMake from a Developer Command Prompt so FFmpeg can be built with MSVC.")
  endif()
  set(_bs4kass_ffmpeg_make ${BS4KASS_NMAKE_EXECUTABLE})
  set(_bs4kass_ffmpeg_toolchain --toolchain=msvc)
  set(_bs4kass_ffmpeg_lib_suffix .lib)
  set(_bs4kass_ffmpeg_lib_prefix "")
  set(_bs4kass_ffmpeg_build_command ${_bs4kass_ffmpeg_make})
  set(_bs4kass_ffmpeg_install_command ${_bs4kass_ffmpeg_make} install)
else()
  find_program(BS4KASS_MAKE_EXECUTABLE make HINTS ENV PATH DOC "GNU make executable used to build FFmpeg")
  if(NOT BS4KASS_MAKE_EXECUTABLE)
    message(FATAL_ERROR "GNU make was not found. Install make so FFmpeg can be built automatically.")
  endif()
  set(_bs4kass_ffmpeg_make ${BS4KASS_MAKE_EXECUTABLE})
  set(_bs4kass_ffmpeg_toolchain "")
  set(_bs4kass_ffmpeg_lib_suffix .a)
  set(_bs4kass_ffmpeg_lib_prefix lib)
  set(_bs4kass_ffmpeg_build_command ${_bs4kass_ffmpeg_make} -j)
  set(_bs4kass_ffmpeg_install_command ${_bs4kass_ffmpeg_make} install)
endif()

set(_bs4kass_ffmpeg_configure_args
  --prefix=${_bs4kass_ffmpeg_install}
  --disable-programs
  --disable-doc
  --disable-debug
  --enable-static
  --disable-shared
  --enable-protocol=file
  --enable-demuxer=mpegts
  ${_bs4kass_ffmpeg_toolchain}
)
list(JOIN _bs4kass_ffmpeg_configure_args " " _bs4kass_ffmpeg_configure_args_str)

set(_bs4kass_ffmpeg_configure_command
  ${_bs4kass_ffmpeg_shell} -c "./configure ${_bs4kass_ffmpeg_configure_args_str}"
)

ExternalProject_Add(bs4kass_ffmpeg
  PREFIX ${_bs4kass_ffmpeg_prefix}
  SOURCE_DIR ${_bs4kass_ffmpeg_source}
  ${_bs4kass_ffmpeg_download_args}
  CONFIGURE_COMMAND ${_bs4kass_ffmpeg_configure_command}
  BUILD_COMMAND ${_bs4kass_ffmpeg_build_command}
  INSTALL_COMMAND ${_bs4kass_ffmpeg_install_command}
  BUILD_IN_SOURCE 1
  LOG_DOWNLOAD 1
  LOG_CONFIGURE 1
  LOG_BUILD 1
  BUILD_BYPRODUCTS
    ${_bs4kass_ffmpeg_install}/lib/${_bs4kass_ffmpeg_lib_prefix}avformat${_bs4kass_ffmpeg_lib_suffix}
    ${_bs4kass_ffmpeg_install}/lib/${_bs4kass_ffmpeg_lib_prefix}avcodec${_bs4kass_ffmpeg_lib_suffix}
    ${_bs4kass_ffmpeg_install}/lib/${_bs4kass_ffmpeg_lib_prefix}avutil${_bs4kass_ffmpeg_lib_suffix}
)

set(BS4KASS_FFMPEG_INCLUDE_DIR "${_bs4kass_ffmpeg_install}/include")
file(MAKE_DIRECTORY "${BS4KASS_FFMPEG_INCLUDE_DIR}")

foreach(_lib avformat avcodec avutil)
  set(_target_name "bs4kass::${_lib}")
  if(NOT TARGET ${_target_name})
    add_library(${_target_name} STATIC IMPORTED GLOBAL)
    if(_bs4kass_ffmpeg_lib_prefix STREQUAL "")
      set(_lib_location "${_bs4kass_ffmpeg_install}/lib/${_lib}${_bs4kass_ffmpeg_lib_suffix}")
    else()
      set(_lib_location "${_bs4kass_ffmpeg_install}/lib/${_bs4kass_ffmpeg_lib_prefix}${_lib}${_bs4kass_ffmpeg_lib_suffix}")
    endif()
    set_target_properties(${_target_name} PROPERTIES
      IMPORTED_LOCATION "${_lib_location}"
      INTERFACE_INCLUDE_DIRECTORIES "${BS4KASS_FFMPEG_INCLUDE_DIR}"
    )
    add_dependencies(${_target_name} bs4kass_ffmpeg)
  endif()
endforeach()

unset(_target_name)
unset(_lib_location)
