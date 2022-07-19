# -------------------------------------------------------------
# create target
# -------------------------------------------------------------
add_executable(Example1_CPU
        main.cpp
        ../particleRenderer/ParticleRenderer.cpp
        ../external/SimplexNoise/SimplexNoise.cpp)


# -------------------------------------------------------------
# set target properties
# -------------------------------------------------------------
set_target_properties(Example1_CPU PROPERTIES
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED YES
        )

target_include_directories(Example1_CPU PRIVATE ../external/SimplexNoise/)


target_compile_definitions(Example1_CPU PRIVATE PROJECT_SHADER_PATH="${CMAKE_SOURCE_DIR}/shader/")
target_compile_definitions(Example1_CPU PRIVATE PROJECT_RESOURCE_PATH="${CMAKE_SOURCE_DIR}/resources/")

target_compile_definitions(Example1_CPU PRIVATE _SILENCE_EXPERIMENTAL_FILESYSTEM_DEPRECATION_WARNING)

# -------------------------------------------------------------
# link dependencies (this will also link the dependencies of dependencies and set required compiler flags)
# -------------------------------------------------------------
if(UNIX)
    target_link_libraries(Example1_CPU PRIVATE stdc++fs)
endif()

target_link_libraries(Example1_CPU PRIVATE Threads::Threads mpUtils::mpUtils)

if(OpenMP_FOUND)
    target_link_libraries(Example1_CPU PRIVATE OpenMP::OpenMP_CXX)
endif()