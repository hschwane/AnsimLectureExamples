# enable cuda
enable_language(CUDA)

# -------------------------------------------------------------
# create target
# -------------------------------------------------------------
add_executable(Example2_CUDA
        main.cu
        ../particleRenderer/ParticleRenderer.cpp
        ../external/SimplexNoise/SimplexNoise.cpp)


# -------------------------------------------------------------
# set target properties
# -------------------------------------------------------------
set_target_properties(Example2_CUDA PROPERTIES
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED YES
        CUDA_STANDARD 17
        CUDA_STANDARD_REQUIRED YES
        )

target_include_directories(Example2_CUDA PRIVATE ../external/SimplexNoise/)


target_compile_definitions(Example2_CUDA PRIVATE PROJECT_SHADER_PATH="${CMAKE_SOURCE_DIR}/shader/")
target_compile_definitions(Example2_CUDA PRIVATE PROJECT_RESOURCE_PATH="${CMAKE_SOURCE_DIR}/resources/")

target_compile_definitions(Example2_CUDA PRIVATE _SILENCE_EXPERIMENTAL_FILESYSTEM_DEPRECATION_WARNING)

# -------------------------------------------------------------
# link dependencies (this will also link the dependencies of dependencies and set required compiler flags)
# -------------------------------------------------------------
if(UNIX)
    target_link_libraries(Example2_CUDA PRIVATE stdc++fs)
endif()

target_link_libraries(Example2_CUDA PRIVATE Threads::Threads mpUtils::mpUtils)

if(OpenMP_FOUND)
    target_link_libraries(Example2_CUDA PRIVATE OpenMP::OpenMP_CXX)
endif()