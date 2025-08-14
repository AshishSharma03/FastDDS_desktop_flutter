cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# ========= Fast-DDS paths =========
set(FAST_DDS_DIR "C:/Program Files/eProsima/fastdds 3.2.2")
set(FAST_DDS_INCLUDE "${FAST_DDS_DIR}/include")
set(FAST_DDS_LIB "${FAST_DDS_DIR}/lib/x64Win64VS2019")

set(FASTDDS_DEP_DIR "C:/Program Files/eProsima/Fast-CDR-2.3.0")
set(FASTDDS_DEP_INCLUDE "${FASTDDS_DEP_DIR}/include")
set(FASTDDS_DEP_LIB "${FASTDDS_DEP_DIR}/lib")

set(OPENSSL_DIR "C:/Program Files/OpenSSL-Win64")
set(OPENSSL_INCLUDE "${OPENSSL_DIR}/include")
set(OPENSSL_LIB "${OPENSSL_DIR}/lib")

include_directories(
        ${FAST_DDS_INCLUDE}
        ${FASTDDS_DEP_INCLUDE}
        ${OPENSSL_INCLUDE}
        ${CMAKE_SOURCE_DIR}/windows/fastdds
)

link_directories(
        ${FAST_DDS_LIB}
        ${FASTDDS_DEP_LIB}
        ${OPENSSL_LIB}
)

# ========= DDS Sources =========
set(DDS_COMMON_SRCS
        ${CMAKE_SOURCE_DIR}/runner/fastdds/HelloWorld.hpp
        ${CMAKE_SOURCE_DIR}/runner/fastdds/HelloWorldCdrAux.hpp
        ${CMAKE_SOURCE_DIR}/runner/fastdds/HelloWorldCdrAux.ipp
        ${CMAKE_SOURCE_DIR}/runner/fastdds/HelloWorldPubSubTypes.cxx
        ${CMAKE_SOURCE_DIR}/runner/fastdds/HelloWorldPubSubTypes.hpp
        ${CMAKE_SOURCE_DIR}/runner/fastdds/HelloWorldTypeObjectSupport.cxx
        ${CMAKE_SOURCE_DIR}/runner/fastdds/HelloWorldTypeObjectSupport.hpp
)

add_library(helloworld_dds STATIC
        ${CMAKE_SOURCE_DIR}/runner/fastdds/HelloWorldPublisher.cpp
        ${CMAKE_SOURCE_DIR}/runner/fastdds/HelloWorldSubscriber.cpp
        ${DDS_COMMON_SRCS}
)

target_link_libraries(helloworld_dds
        libfastdds-3.2
        libfastcdr-2.3
        libssl
        libcrypto
        foonathan_memory-0.7.3
        Shlwapi
)

# ========= Flutter Runner =========
add_executable(${BINARY_NAME} WIN32
        "flutter_window.cpp"
        "main.cpp"
        "utils.cpp"
        "win32_window.cpp"
        "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
        "Runner.rc"
        "runner.exe.manifest"
)

apply_standard_settings(${BINARY_NAME})

target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# ========= Link DDS library to Flutter runner =========
target_link_libraries(${BINARY_NAME} PRIVATE helloworld_dds)

# ========= Ensure Flutter assets are built =========
add_dependencies(${BINARY_NAME} flutter_assemble)
