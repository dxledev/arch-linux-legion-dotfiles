cmake_minimum_required(VERSION 3.21)
project(ShellMarkup LANGUAGES CXX)
find_package(Qt6 REQUIRED COMPONENTS Qml Gui)
qt_standard_project_setup(REQUIRES 6.5)
qt_add_qml_module(shellmarkup
    URI Shell.Integration
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Shell/Integration"
    SOURCES notification-markup.h notification-markup.cpp ward-markup.h ward-markup.cpp
)
target_link_libraries(shellmarkup PRIVATE Qt6::Gui)
set_target_properties(shellmarkup shellmarkupplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
install(TARGETS shellmarkup shellmarkupplugin LIBRARY DESTINATION qml/Shell/Integration)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/Shell/Integration/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/Shell/Integration/shellmarkup.qmltypes"
    DESTINATION qml/Shell/Integration)
