cmake_minimum_required(VERSION 3.21)
project(ShellAppIcons LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Quick Qml Gui)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_qml_module(shellappicons
    URI Shell.AppIcons
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Shell/AppIcons"
    SOURCES iconraster.h iconraster.cpp iconcolorization.h iconcolorization.cpp iconcache.h iconcache.cpp
)
target_link_libraries(shellappicons PRIVATE Qt6::Quick Qt6::Gui)
set_target_properties(shellappicons shellappiconsplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
install(TARGETS shellappicons shellappiconsplugin LIBRARY DESTINATION qml/Shell/AppIcons)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/Shell/AppIcons/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/Shell/AppIcons/shellappicons.qmltypes"
    DESTINATION qml/Shell/AppIcons)

include(CTest)
if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Test)
    add_executable(test-app-icons tests/icons.cpp)
    target_include_directories(test-app-icons PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    target_link_libraries(test-app-icons PRIVATE shellappicons Qt6::Quick Qt6::Test)
    add_test(NAME app-icons COMMAND test-app-icons)
    set_tests_properties(app-icons PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
endif()
