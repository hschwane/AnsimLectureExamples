# for use with configure_package_config_file

####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was mpUtilsConfig.cmake.in                            ########

get_filename_component(PACKAGE_PREFIX_DIR "../../../.." ABSOLUTE)

macro(set_and_check _var _file)
  set(${_var} "${_file}")
  if(NOT EXISTS "${_file}")
    message(FATAL_ERROR "File or directory ${_file} referenced by variable ${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT ${_NAME}_${comp}_FOUND)
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

####################################################################################
get_filename_component(mpUtils_CMAKE_DIR "." ABSOLUTE)

# set a version variable
set(mpUtils_VERSION 0.14.1)

# set mpUtils_CMAKE_SCRIPTS_PATH so users can make use of useful cmake scripts,
# by appending this to the module path. Be careful, if this file is in the
# build tree and was not installed, set the path to the source tree.
# If it is in an installation directory, set the relative path to the modules.
if( "/home/hendrik/CLionProjects/mpUtils/cmake-build-debug" STREQUAL ${mpUtils_CMAKE_DIR})
    set_and_check(mpUtils_CMAKE_SCRIPTS_PATH "/home/hendrik/CLionProjects/mpUtils/cmake")
else()
    set_and_check(mpUtils_CMAKE_SCRIPTS_PATH "${mpUtils_CMAKE_DIR}/modules")
endif()

# set vars to show which features are availible
set(mpUtils_CUDA_AVAILIBLE OFF)
if(mpUtils_CUDA_AVAILIBLE)
    set(mpUtils_CUDA_ARCH_FLAGS "")
endif()
set(mpUtils_GLM_AVAILIBLE ON)
set(mpUtils_OPENGL_AVAILIBLE ON)
set(mpUtils_PPUTILS_AVAILIBLE OFF)

# find required dependencies
include(CMakeFindDependencyMacro)
find_dependency(Threads)

# find optional dependencies
if(mpUtils_GLM_AVAILIBLE)
    find_dependency(glm QUIET)
endif()
if(mpUtils_OPENGL_AVAILIBLE)
    set(OpenGL_GL_PREFERENCE "GLVND")
    find_dependency(OpenGL QUIET)
    find_dependency(GLEW QUIET)
    find_dependency(glfw3 QUIET)
endif()

# include the targets
if(NOT (TARGET mpUtils::mpUtils AND TARGET mpUtils::mpCudaSettings))
    include("${mpUtils_CMAKE_DIR}/mpUtilsTargets.cmake")
endif()

# check if everything was found
check_required_components(mpUtils)
