cmake_minimum_required(VERSION 3.20)
project(qianshi_showdesktop LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml DBus)

add_library(qianshi_showdesktop SHARED
    showdesktop.cpp
    plugin.cpp
)

target_link_libraries(qianshi_showdesktop PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::DBus
)

set_target_properties(qianshi_showdesktop PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)
