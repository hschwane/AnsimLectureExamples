# -------------------------------------------------------------
# general setup
# -------------------------------------------------------------
cmake_minimum_required(VERSION 3.8...3.19)


if(${CMAKE_VERSION} VERSION_LESS 3.12)
    cmake_policy(VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION})
endif()

# Require out-of-source builds
file(TO_CMAKE_PATH "${PROJECT_BINARY_DIR}/CMakeLists.txt" LOC_PATH)
if(EXISTS "${LOC_PATH}")
    message(FATAL_ERROR "You cannot build in a source directory (or any directory with a CMakeLists.txt file). Please make a build subdirectory. Feel free to remove CMakeCache.txt and CMakeFiles.")
endif()

# Appends the mpUtils cmake path to MAKE_MODULE_PATH variable.
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/external/mputils/cmake ${CMAKE_MODULE_PATH})

# default build configuration
include(setDefaultTypeRelease)

# -------------------------------------------------------------
# set up project
# -------------------------------------------------------------

project(AnsimLectureExamples LANGUAGES CXX C)

# -------------------------------------------------------------
# dependencies
# -------------------------------------------------------------
add_subdirectory(external/mputils)
# openGL, glm, usw are included with mpUtils
find_package(Threads REQUIRED)
find_package(OpenMP)

# -------------------------------------------------------------
# add all example sin subfolders
# -------------------------------------------------------------
add_subdirectory(Example1_CPU)
add_subdirectory(Example2_CUDA)
add_subdirectory(Example3_CUDA_SharedMemory)