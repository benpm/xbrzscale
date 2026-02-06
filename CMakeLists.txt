cmake_minimum_required(VERSION 3.14)
project(xbrzscale VERSION 1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# Fetch SDL2
FetchContent_Declare(
    SDL2
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG release-2.30.10
    GIT_SHALLOW TRUE
)

# Fetch SDL2_image
FetchContent_Declare(
    SDL2_image
    GIT_REPOSITORY https://github.com/libsdl-org/SDL_image.git
    GIT_TAG release-2.8.4
    GIT_SHALLOW TRUE
)

# Make SDL2 and SDL2_image available
FetchContent_MakeAvailable(SDL2 SDL2_image)

# Workaround: SDL2_image doesn't install its header in SDL2/ subdirectory
# but our code expects #include <SDL2/SDL_image.h>
FetchContent_GetProperties(SDL2_image SOURCE_DIR SDL2_IMAGE_SOURCE_DIR)
file(MAKE_DIRECTORY ${SDL2_IMAGE_SOURCE_DIR}/include/SDL2)
file(COPY ${SDL2_IMAGE_SOURCE_DIR}/include/SDL_image.h
     DESTINATION ${SDL2_IMAGE_SOURCE_DIR}/include/SDL2)

# xBRZ library
add_library(xbrz STATIC
    xbrz/xbrz.cpp
    xbrz/xbrz.h
    xbrz/xbrz_config.h
    xbrz/xbrz_tools.h
    xbrz/config.h
)
target_compile_definitions(xbrz PRIVATE NDEBUG)
target_include_directories(xbrz PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# Get SDL2 and SDL2_image include directories
get_target_property(SDL2_INCLUDE_DIR SDL2::SDL2 INTERFACE_INCLUDE_DIRECTORIES)
get_target_property(SDL2_IMAGE_INCLUDE_DIR SDL2_image::SDL2_image INTERFACE_INCLUDE_DIRECTORIES)

# libxbrzscale library
add_library(libxbrzscale STATIC
    libxbrzscale.cpp
    libxbrzscale.h
)
target_include_directories(libxbrzscale PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${SDL2_INCLUDE_DIR}/..
    ${SDL2_IMAGE_INCLUDE_DIR}/..
)
target_link_libraries(libxbrzscale PUBLIC
    xbrz
    SDL2::SDL2
)

# Main executable
add_executable(xbrzscale
    xbrzscale.cpp
)
target_include_directories(xbrzscale PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${SDL2_INCLUDE_DIR}/..
    ${SDL2_IMAGE_INCLUDE_DIR}/..
)
target_link_libraries(xbrzscale PRIVATE
    libxbrzscale
    SDL2::SDL2main
    SDL2::SDL2
    SDL2_image::SDL2_image
)

# Copy DLLs to output directory on Windows
if(WIN32)
    add_custom_command(TARGET xbrzscale POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:SDL2::SDL2>
            $<TARGET_FILE_DIR:xbrzscale>
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_FILE:SDL2_image::SDL2_image>
            $<TARGET_FILE_DIR:xbrzscale>
        COMMENT "Copying SDL2 DLLs to output directory"
    )
endif()

# Shared library for Python bindings (xBRZ C API only, no SDL dependencies)
add_library(xbrz_shared SHARED
    xbrz_c_api.cpp
)
target_link_libraries(xbrz_shared PRIVATE xbrz)
target_include_directories(xbrz_shared PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
set_target_properties(xbrz_shared PROPERTIES
    OUTPUT_NAME "xbrz_shared"
    VERSION 1.0
    SOVERSION 1
)

# Installation
install(TARGETS xbrzscale DESTINATION bin)
install(TARGETS xbrz_shared DESTINATION lib)
