cmake_minimum_required(VERSION 3.21)
project(ShellClipboard LANGUAGES CXX)

find_package(Qt6 REQUIRED COMPONENTS Concurrent Core Gui Qml)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_qml_module(shellclipboard
    URI Shell.Clipboard
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Shell/Clipboard"
    SOURCES
        clipboardentry.h
        clipboardlistmodel.h clipboardlistmodel.cpp
        clipboardfiltermodel.h clipboardfiltermodel.cpp
        cliphistbackend.h cliphistbackend.cpp
        payloadclassifier.h payloadclassifier.cpp
        favoritesstore.h favoritesstore.cpp
        clipboardcontroller.h clipboardcontroller.cpp
)
target_link_libraries(shellclipboard PRIVATE Qt6::Concurrent Qt6::Core Qt6::Gui)
find_package(ZXing QUIET)
if(ZXing_FOUND)
    target_link_libraries(shellclipboard PRIVATE ZXing::ZXing)
    target_compile_definitions(shellclipboard PRIVATE CLIPBOARD_HAS_ZXING)
endif()
set_target_properties(shellclipboard shellclipboardplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
install(TARGETS shellclipboard shellclipboardplugin LIBRARY DESTINATION qml/Shell/Clipboard)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/Shell/Clipboard/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/Shell/Clipboard/shellclipboard.qmltypes"
    DESTINATION qml/Shell/Clipboard)

include(CTest)
if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Test)
    find_program(QMLTESTRUNNER_EXECUTABLE NAMES qmltestrunner
        HINTS "${Qt6Core_DIR}/../../qt6/bin" "${Qt6Core_DIR}/../../bin" /usr/lib/qt6/bin
        NO_DEFAULT_PATH REQUIRED)
    add_executable(test-clipboard tests/clipboard.cpp)
    if(ZXing_FOUND)
        target_compile_definitions(test-clipboard PRIVATE CLIPBOARD_TEST_HAS_ZXING)
    endif()
    target_link_libraries(test-clipboard PRIVATE shellclipboard Qt6::Core Qt6::Gui Qt6::Test Qt6::Concurrent Qt6::Qml)
    target_include_directories(test-clipboard PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
    add_test(NAME clipboard COMMAND test-clipboard)
    add_test(NAME clipboard-qml-state
        COMMAND ${CMAKE_COMMAND} -E env QT_QPA_PLATFORM=offscreen "QML_IMPORT_PATH=${CMAKE_CURRENT_BINARY_DIR}"
            "${QMLTESTRUNNER_EXECUTABLE}" -input "${CMAKE_CURRENT_SOURCE_DIR}/tests/qml")
endif()
