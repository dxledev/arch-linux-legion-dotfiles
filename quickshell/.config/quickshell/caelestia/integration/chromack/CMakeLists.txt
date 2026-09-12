cmake_minimum_required(VERSION 3.21)
project(ShellChromack LANGUAGES CXX)
find_package(Qt6 REQUIRED COMPONENTS Qml Gui)
qt_standard_project_setup(REQUIRES 6.5)
qt_add_qml_module(shellchromack
    URI Shell.Chromack
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Shell/Chromack"
    SOURCES chromack-model.h chromack-model.cpp ChromackConfig.h ChromackConfig.cpp
)
target_link_libraries(shellchromack PRIVATE Qt6::Gui)
set_target_properties(shellchromack shellchromackplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
install(TARGETS shellchromack shellchromackplugin LIBRARY DESTINATION qml/Shell/Chromack)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/Shell/Chromack/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/Shell/Chromack/shellchromack.qmltypes"
    DESTINATION qml/Shell/Chromack)
include(CTest)
if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Test)
    add_executable(test-chromack tests/model.cpp)
    target_link_libraries(test-chromack PRIVATE shellchromack Qt6::Test Qt6::Gui)
    target_include_directories(test-chromack PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    add_test(NAME chromack COMMAND test-chromack -platform offscreen)
endif()
