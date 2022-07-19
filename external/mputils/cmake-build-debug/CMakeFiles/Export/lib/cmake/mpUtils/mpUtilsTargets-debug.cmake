#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "mpUtils::mpUtils" for configuration "Debug"
set_property(TARGET mpUtils::mpUtils APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(mpUtils::mpUtils PROPERTIES
  IMPORTED_LOCATION_DEBUG "${_IMPORT_PREFIX}/lib/libmpUtilsd.so.0.14.1"
  IMPORTED_SONAME_DEBUG "libmpUtilsd.so.0"
  )

list(APPEND _IMPORT_CHECK_TARGETS mpUtils::mpUtils )
list(APPEND _IMPORT_CHECK_FILES_FOR_mpUtils::mpUtils "${_IMPORT_PREFIX}/lib/libmpUtilsd.so.0.14.1" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
