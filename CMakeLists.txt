cmake_minimum_required(VERSION 3.5)

# Set extension name here
set(TARGET_NAME ifc)

set(EXTENSION_NAME ${TARGET_NAME}_extension)
set(LOADABLE_EXTENSION_NAME ${TARGET_NAME}_loadable_extension)

project(${TARGET_NAME})
include_directories(src/include)

# FIXME: wut?
include_directories(./stepcode/build/schemas/sdai_IFC4)
link_libraries(./stepcode/build/lib/libsdai_IFC4.dylib)

set(EXTENSION_SOURCES src/quack_extension.cpp)

set(EXTENSION_SOURCES src/quack_extension.cpp)

build_static_extension(${TARGET_NAME} ${EXTENSION_SOURCES})
build_loadable_extension(${TARGET_NAME} " " ${EXTENSION_SOURCES})

install(
  TARGETS ${EXTENSION_NAME}
  EXPORT "${DUCKDB_EXPORT_SET}"
  LIBRARY DESTINATION "${INSTALL_LIB_DIR}"
  ARCHIVE DESTINATION "${INSTALL_LIB_DIR}")
