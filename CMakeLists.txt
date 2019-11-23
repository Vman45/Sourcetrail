cmake_minimum_required(VERSION 3.1)

set(BUILD_CXX_LANGUAGE_PACKAGE OFF CACHE BOOL "Add C and C++ support to the Sourcetrail indexer.")
set(BUILD_JAVA_LANGUAGE_PACKAGE OFF CACHE BOOL "Add Java support to the Sourcetrail indexer.")
set(BUILD_PYTHON_LANGUAGE_PACKAGE OFF CACHE BOOL "Add Python support to the Sourcetrail indexer.")

#set (CMAKE_VERBOSE_MAKEFILE ON)

include(cmake/add_files.cmake)
include(cmake/create_source_groups.cmake)
include(cmake/version.cmake)
include(cmake/version_setup.cmake)
include(cmake/licenses.cmake)

# prohibit in-source-builds
if (${CMAKE_BINARY_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
	message(STATUS "In-source-builds are not allowed")
	message(STATUS "Clean your source directory (e.g. delete the CMakeCache.txt file)")
	message(FATAL_ERROR "Please create a separate build directory and call CMake again")
endif()

# speed up recompiling on unix with ccache
find_program(CCACHE_PROGRAM ccache)
if (CCACHE_PROGRAM)
	message(STATUS "ccache found")

	# Support Unix Makefiles and Ninja
	set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()


# Variables --------------------------------------------------------------------

set(PROJECT_NAME Sourcetrail)

set(APP_PROJECT_NAME "${PROJECT_NAME}")
set(APP_INDEXER_NAME "${PROJECT_NAME}_indexer")
set(LIB_UTILITY_PROJECT_NAME "${PROJECT_NAME}_lib_utility")
set(LIB_GUI_PROJECT_NAME "${PROJECT_NAME}_lib_gui")
set(LIB_CXX_PROJECT_NAME "${PROJECT_NAME}_lib_cxx")
set(LIB_JAVA_PROJECT_NAME "${PROJECT_NAME}_lib_java")
set(LIB_PYTHON_PROJECT_NAME "${PROJECT_NAME}_lib_python")
set(LIB_PROJECT_NAME "${PROJECT_NAME}_lib")
set(TEST_PROJECT_NAME "${PROJECT_NAME}_test")

if (WIN32)
	set(PLATFORM_INCLUDE "includesWindows.h")
elseif (APPLE)
	set(PLATFORM_INCLUDE "includesMac.h")
else ()
	set(PLATFORM_INCLUDE "includesLinux.h")
endif ()


# Project ----------------------------------------------------------------------

project(${PROJECT_NAME})

# set Standard build type to Release
set(CMAKE_BUILD_TYPE_INIT "Release")

#RPATH
if(UNIX AND NOT APPLE)
	set(CMAKE_SKIP_BUILD_RPATH FALSE)
	set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
	set(CMAKE_INSTALL_RPATH "$ORIGIN/lib/:$$ORIGIN/lib/")
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_C_STANDARD 99)


# Settings ---------------------------------------------------------------------

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unknown-warning-option -fcolor-diagnostics -fvisibility-inlines-hidden")
endif()

# For debugging the release build on linux
#if (UNIX AND "${CMAKE_BUILD_TYPE}" STREQUAL "Release")
	#add_definitions(-fno-omit-frame-pointer)
#endif ()


# Clang ------------------------------------------------------------------------

if (BUILD_CXX_LANGUAGE_PACKAGE)

	find_package(Clang REQUIRED)

	if (LLVM_FOUND)
		message(STATUS "Found LLVM ${LLVM_VERSION}")
	endif()

endif()


# Boost ------------------------------------------------------------------------

set(Boost_USE_MULTITHREAD ON)
set(Boost_USE_STATIC_LIBS ON CACHE BOOL "Set to ON to force the use of the static libraries.")
set(Boost_USE_STATIC_RUNTIME OFF)

find_package(Boost 1.68 COMPONENTS system program_options filesystem date_time REQUIRED)


# Qt ---------------------------------------------------------------------------

find_package(Qt5 COMPONENTS Widgets PrintSupport Network Svg REQUIRED)

if (WIN32)
	find_package(Qt5 COMPONENTS WinExtras REQUIRED)
endif()

if(Qt5Widgets_FOUND)
	message(STATUS "Found Qt ${Qt5Widgets_VERSION_STRING}")

	# FIX: Qt was built with -reduce-relocations
	if (Qt5_POSITION_INDEPENDENT_CODE)
		SET(CMAKE_POSITION_INDEPENDENT_CODE ON)
	endif()
endif()


# Setup ---------------------------------------------------------------------------

if (WIN32)
	get_filename_component(QT_BINARY_DIR "${QT_MOC_EXECUTABLE}" PATH)
	set(QT_PLUGINS_DIR "${QT_BINARY_DIR}/../plugins")

	function(COPY_QT_BINARIES IS_DEBUG IS_APP)
		set(SUFFIX "")
		if (IS_DEBUG)
			set(SUFFIX "d")
		endif()

		set(CONFIGURATION "Release")
		if (IS_DEBUG)
			set(CONFIGURATION "Debug")
		endif()

		if(CMAKE_CL_64)
			set(BITS "64")
		else()
			set(BITS "32")
		endif()

		set(TARGET "test")
		if (IS_APP)
			set(TARGET "app")

			file(GLOB MY_PUBLIC_HEADERS
				"${CMAKE_SOURCE_DIR}/setup/dynamic_libraries/win${BITS}/app/${CONFIGURATION}/*"
			)
			file(COPY ${MY_PUBLIC_HEADERS} DESTINATION "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/")

		endif()

		configure_file("${QT_BINARY_DIR}/Qt5Core${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/Qt5Core${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_BINARY_DIR}/Qt5Gui${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/Qt5Gui${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_BINARY_DIR}/Qt5Network${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/Qt5Network${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_BINARY_DIR}/Qt5Svg${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/Qt5Svg${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_BINARY_DIR}/Qt5Widgets${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/Qt5Widgets${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_BINARY_DIR}/Qt5WinExtras${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/Qt5WinExtras${SUFFIX}.dll" COPYONLY)

		configure_file("${QT_PLUGINS_DIR}/platforms/qwindows${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/platforms/qwindows${SUFFIX}.dll" COPYONLY)

		configure_file("${QT_PLUGINS_DIR}/styles/qwindowsvistastyle${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/styles/qwindowsvistastyle${SUFFIX}.dll" COPYONLY)

		configure_file("${QT_PLUGINS_DIR}/imageformats/qgif${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/imageformats/qgif${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_PLUGINS_DIR}/imageformats/qicns${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/imageformats/qicns${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_PLUGINS_DIR}/imageformats/qico${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/imageformats/qico${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_PLUGINS_DIR}/imageformats/qjpeg${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/imageformats/qjpeg${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_PLUGINS_DIR}/imageformats/qsvg${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/imageformats/qsvg${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_PLUGINS_DIR}/imageformats/qtga${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/imageformats/qtga${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_PLUGINS_DIR}/imageformats/qtiff${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/imageformats/qtiff${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_PLUGINS_DIR}/imageformats/qwbmp${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/imageformats/qwbmp${SUFFIX}.dll" COPYONLY)
		configure_file("${QT_PLUGINS_DIR}/imageformats/qwebp${SUFFIX}.dll" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/${TARGET}/imageformats/qwebp${SUFFIX}.dll" COPYONLY)
	endfunction(COPY_QT_BINARIES)

	COPY_QT_BINARIES(True True)
	COPY_QT_BINARIES(True False)
	COPY_QT_BINARIES(False True)
	COPY_QT_BINARIES(False False)

	configure_file("${CMAKE_SOURCE_DIR}/setup/icon/windows/sourcetrail.ico" "${CMAKE_BINARY_DIR}/${CONFIGURATION}/sourcetrail.ico" COPYONLY)

endif()


add_subdirectory(src/app)
add_subdirectory(src/external)
add_subdirectory(src/indexer)
add_subdirectory(src/lib)
add_subdirectory(src/lib_cxx)
add_subdirectory(src/lib_gui)
add_subdirectory(src/lib_java)
add_subdirectory(src/lib_python)
add_subdirectory(src/lib_utility)
add_subdirectory(src/test)


# Lib Python ---------------------------------------------------------------------

if (BUILD_PYTHON_LANGUAGE_PACKAGE)

	add_library(${LIB_PYTHON_PROJECT_NAME} ${LIB_PYTHON_FILES})

	create_source_groups(${LIB_PYTHON_FILES})

	set_property(
		TARGET ${LIB_PYTHON_PROJECT_NAME}
		PROPERTY INCLUDE_DIRECTORIES
			"${LIB_PYTHON_INCLUDE_PATHS}"
			"${LIB_UTILITY_INCLUDE_PATHS}"
			"${LIB_INCLUDE_PATHS}"
			"${CMAKE_BINARY_DIR}/src/lib"
	)

	#link_directories(${Boost_LIBRARY_DIRS})

	add_custom_command(
		TARGET ${LIB_PYTHON_PROJECT_NAME}
		PRE_BUILD
		COMMAND call "\"${PROJECT_SOURCE_DIR}/script/download_python_indexer.sh\""
		COMMENT "download python indexer"
	)

else()

	message(STATUS "Building the Python indexer will be skipped. You can enable building this target by setting 'BUILD_PYTHON_LANGUAGE_PACKAGE' to 'ON'.")

endif()


