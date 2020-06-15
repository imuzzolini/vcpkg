include(vcpkg_common_functions)

set(FL_VERSION_MAJOR 1)
set(FL_VERSION_MINOR 3)
set(FL_VERSION_BUILD 5)
set(FL_VERSION ${FL_VERSION_MAJOR}.${FL_VERSION_MINOR}.${FL_VERSION_BUILD} )

vcpkg_download_distfile(ARCHIVE
    URLS "https://fltk.org/pub/fltk/${FL_VERSION}/fltk-${FL_VERSION}-source.tar.gz"
    FILENAME "fltk-${FL_VERSION}.tar.gz"
    SHA512 db7ea7c5f3489195a48216037b9371a50f1119ae7692d66f71b6711e5ccf78814670581bae015e408dee15c4bba921728309372c1cffc90113cdc092e8540821
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    PATCHES
        findlibsfix.patch
        add-link-libraries.patch
)

math(EXPR FL_ABI_VERSION "${FL_VERSION_MAJOR}*10000 + ${FL_VERSION_MINOR}*100 + ${FL_VERSION_BUILD}")

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(BUILD_SHARED ON)
else()
    set(BUILD_SHARED OFF)
endif()

if (VCPKG_TARGET_ARCHITECTURE MATCHES "arm" OR VCPKG_TARGET_ARCHITECTURE MATCHES "arm64")
    set(OPTION_USE_GL "-DOPTION_USE_GL=OFF")
else()
    set(OPTION_USE_GL "-DOPTION_USE_GL=ON")
endif()

if (VCPKG_TARGET_IS_LINUX)
    set(OPTION_X11 "-DOPTION_USE_XINERAMA=ON -DOPTION_USE_XFT=ON -DOPTION_USE_XDBE=ON -DOPTION_USE_XCURSOR=ON -DOPTION_USE_XRENDER=ON -DOPTION_USE_XFIXES=ON")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DOPTION_ABI_VERSION=${FL_ABI_VERSION}
        -DOPTION_BUILD_EXAMPLES=OFF
        -DOPTION_LARGE_FILE=ON
        -DOPTION_USE_THREADS=ON
        -DOPTION_USE_SYSTEM_ZLIB=ON
        -DOPTION_USE_SYSTEM_LIBPNG=ON
        -DOPTION_USE_SYSTEM_LIBJPEG=ON
        -DOPTION_BUILD_SHARED_LIBS=${BUILD_SHARED}
        ${OPTION_USE_GL}
        ${OPTION_X11}
)

vcpkg_install_cmake()

if (VCPKG_TARGET_IS_LINUX)
    vcpkg_fixup_cmake_targets(CONFIG_PATH share/${PORT} TARGET_PATH share/${PORT})
    file(COPY ${CURRENT_PACKAGES_DIR}/bin/fluid DESTINATION ${CURRENT_PACKAGES_DIR}/tools/fltk)
    file(REMOVE ${CURRENT_PACKAGES_DIR}/bin/fluid)
    file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/bin/fluid)
elseif (VCPKG_TARGET_IS_OSX)
    file(COPY ${CURRENT_PACKAGES_DIR}/bin/fluid.app DESTINATION ${CURRENT_PACKAGES_DIR}/tools/fltk)
    file(REMOVE ${CURRENT_PACKAGES_DIR}/bin/fluid.app)
    file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/bin/fluid.app)
else() 
    vcpkg_fixup_cmake_targets(CONFIG_PATH CMake)
    file(COPY ${CURRENT_PACKAGES_DIR}/bin/fluid.exe DESTINATION ${CURRENT_PACKAGES_DIR}/tools/fltk)
    file(REMOVE ${CURRENT_PACKAGES_DIR}/bin/fluid.exe)
    file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/bin/fluid.exe)
endif()

file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/debug/include
    ${CURRENT_PACKAGES_DIR}/debug/share
)

vcpkg_copy_pdbs()

vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/fltk)

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    file(REMOVE_RECURSE
        ${CURRENT_PACKAGES_DIR}/debug/bin
        ${CURRENT_PACKAGES_DIR}/bin
    )
else()
    if(VCPKG_TARGET_IS_WINDOWS)
        file(GLOB STATIC_LIBS "${CURRENT_PACKAGES_DIR}/lib/*.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/*.lib")
        list(FILTER STATIC_LIBS EXCLUDE REGEX "_SHAREDd?\\.lib\$")
        file(REMOVE ${STATIC_LIBS})
    else()
        file(GLOB STATIC_LIBS "${CURRENT_PACKAGES_DIR}/lib/*.a" "${CURRENT_PACKAGES_DIR}/debug/lib/*.a")
        file(REMOVE ${STATIC_LIBS})
    endif()
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    foreach(FILE Fl_Export.H fl_utf8.h)
        file(READ ${CURRENT_PACKAGES_DIR}/include/FL/${FILE} FLTK_HEADER)
        if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
            string(REPLACE "defined(FL_DLL)" "0" FLTK_HEADER "${FLTK_HEADER}")
        else()
            string(REPLACE "defined(FL_DLL)" "1" FLTK_HEADER "${FLTK_HEADER}")
        endif()
        file(WRITE ${CURRENT_PACKAGES_DIR}/include/FL/${FILE} "${FLTK_HEADER}")
    endforeach()
endif()

vcpkg_remove_if_empty(
    FOLDERS
        ${CURRENT_PACKAGES_DIR}/bin 
        ${CURRENT_PACKAGES_DIR}/debug/bin
)

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
