#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "glsp::glsp" for configuration "Release"
set_property(TARGET glsp::glsp APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(glsp::glsp PROPERTIES
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libglsp.so"
  IMPORTED_SONAME_RELEASE "libglsp.so"
  )

list(APPEND _IMPORT_CHECK_TARGETS glsp::glsp )
list(APPEND _IMPORT_CHECK_FILES_FOR_glsp::glsp "${_IMPORT_PREFIX}/lib/libglsp.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)