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
)

vcpkg_install_cmake()

file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/CMAKE
    ${CURRENT_PACKAGES_DIR}/debug/CMAKE
    ${CURRENT_PACKAGES_DIR}/debug/include
)

if(VCPKG_TARGET_IS_WINDOWS)
    set(EXE_SUFFIX ".exe")
endif()

file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/tools)
file(RENAME ${CURRENT_PACKAGES_DIR}/bin/fluid${EXE_SUFFIX} ${CURRENT_PACKAGES_DIR}/tools/fluid${EXE_SUFFIX})
file(RENAME ${CURRENT_PACKAGES_DIR}/bin/fltk-config ${CURRENT_PACKAGES_DIR}/tools/fltk-config)
file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/bin/fluid${EXE_SUFFIX})
file(REMOVE ${CURRENT_PACKAGES_DIR}/debug/bin/fltk-config)

vcpkg_copy_pdbs()

vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/fltk)

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    file(REMOVE_RECURSE
        ${CURRENT_PACKAGES_DIR}/debug/bin
        ${CURRENT_PACKAGES_DIR}/bin
    )
else()
    if(VCPKG_TARGET_IS_WINDOWS)
        file(GLOB SHARED_LIBS "${CURRENT_PACKAGES_DIR}/lib/*_SHARED.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/*_SHAREDd.lib")
        file(GLOB STATIC_LIBS "${CURRENT_PACKAGES_DIR}/lib/*.lib" "${CURRENT_PACKAGES_DIR}/debug/lib/*.lib")
        list(FILTER STATIC_LIBS EXCLUDE REGEX "_SHAREDd?\\.lib\$")
        file(REMOVE ${STATIC_LIBS})
        foreach(SHARED_LIB ${SHARED_LIBS})
            string(REGEX REPLACE "_SHARED(d?)\\.lib\$" "\\1.lib" NEWNAME ${SHARED_LIB})
            file(RENAME ${SHARED_LIB} ${NEWNAME})
        endforeach()
    else()
        file(GLOB SHARED_LIBS "${CURRENT_PACKAGES_DIR}/lib/*_SHARED.so*" "${CURRENT_PACKAGES_DIR}/debug/lib/*_SHARED.so*")
        file(GLOB STATIC_LIBS "${CURRENT_PACKAGES_DIR}/lib/*.a" "${CURRENT_PACKAGES_DIR}/debug/lib/*.a")
        file(REMOVE ${STATIC_LIBS})
        foreach(SHARED_LIB ${SHARED_LIBS})
            string(REGEX REPLACE "_SHARED" "" NEWNAME ${SHARED_LIB})
            file(RENAME ${SHARED_LIB} ${NEWNAME})
        endforeach()
    endif()
endif()

foreach(FILE Fl_Export.H fl_utf8.h)
    file(READ ${CURRENT_PACKAGES_DIR}/include/FL/${FILE} FLTK_HEADER)
    if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
        string(REPLACE "defined(FL_DLL)" "0" FLTK_HEADER "${FLTK_HEADER}")
    else()
        string(REPLACE "defined(FL_DLL)" "1" FLTK_HEADER "${FLTK_HEADER}")
    endif()
    file(WRITE ${CURRENT_PACKAGES_DIR}/include/FL/${FILE} "${FLTK_HEADER}")
endforeach()

foreach(FOLDER ITEMS ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)
    file(GLOB_RECURSE FILES LIST_DIRECTORIES FALSE ${FOLDER}/*.*)
    list(LENGTH FILES FILES_COUNT)
    if(${FILES_COUNT} EQUAL 0)
        file(REMOVE_RECURSE ${FOLDER})
    endif()
endforeach()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

file(INSTALL ${SOURCE_PATH}/COPYING DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
