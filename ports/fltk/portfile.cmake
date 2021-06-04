# FLTK has many improperly shared global variables that get duplicated into every DLL
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_fail_port_install(ON_TARGET "UWP")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO fltk/fltk
    REF  46604ef40bde400c0c33fb5790b023629d1bd445 #1.3.6 rc1
    SHA512 692996be22b289a473be9371dbf558a940d7dda72ce655141610d55de5f7e6a331010a8d999fe4e3feaa01fff7797a4403173b3b804329579d08fbc77ba7958e
    HEAD_REF master
    PATCHES
        findlibsfix.patch
        config-path.patch
        include.patch
        fix-system-link.patch
)

# Remove these 2 lines when the next update
file(COPY ${CMAKE_CURRENT_LIST_DIR}/fltk_version.dat DESTINATION ${SOURCE_PATH})
file(REMOVE ${SOURCE_PATH}/VERSION)

if (VCPKG_TARGET_ARCHITECTURE MATCHES "arm" OR VCPKG_TARGET_ARCHITECTURE MATCHES "arm64")
    set(OPTION_USE_GL "-DOPTION_USE_GL=OFF")
else()
    set(OPTION_USE_GL "-DOPTION_USE_GL=ON")
endif()

if (VCPKG_TARGET_IS_LINUX)
    set(OPTION_X11 "-DOPTION_USE_XINERAMA=ON -DOPTION_USE_XFT=ON -DOPTION_USE_XDBE=ON -DOPTION_USE_XCURSOR=ON -DOPTION_USE_XRENDER=ON -DOPTION_USE_XFIXES=ON")
endif()

set(FL_VERSION_MAJOR 1)
set(FL_VERSION_MINOR 3)
set(FL_VERSION_BUILD 6)
set(FL_VERSION ${FL_VERSION_MAJOR}.${FL_VERSION_MINOR}.${FL_VERSION_BUILD} )
math(EXPR FL_ABI_VERSION "${FL_VERSION_MAJOR}*10000 + ${FL_VERSION_MINOR}*100 + ${FL_VERSION_BUILD}")

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DOPTION_ABI_VERSION=${FL_ABI_VERSION}
        -DOPTION_BUILD_EXAMPLES=OFF
        -DFLTK_BUILD_TEST=OFF
        -DOPTION_LARGE_FILE=ON
        -DOPTION_USE_THREADS=ON
        -DOPTION_USE_SYSTEM_ZLIB=ON
        -DOPTION_USE_SYSTEM_LIBPNG=ON
        -DOPTION_USE_SYSTEM_LIBJPEG=ON
        -DOPTION_BUILD_SHARED_LIBS=OFF
        -DFLTK_CONFIG_PATH=share/fltk
        ${OPTION_USE_GL}
        ${OPTION_X11}
)

vcpkg_install_cmake()

vcpkg_fixup_cmake_targets(CONFIG_PATH share/fltk)

vcpkg_copy_pdbs()

if(VCPKG_TARGET_IS_OSX)
    vcpkg_copy_tools(TOOL_NAMES fluid.app fltk-config AUTO_CLEAN)
elseif(VCPKG_TARGET_IS_WINDOWS)
    file(REMOVE ${CURRENT_PACKAGES_DIR}/bin/fltk-config ${CURRENT_PACKAGES_DIR}/debug/bin/fltk-config)
    vcpkg_copy_tools(TOOL_NAMES fluid AUTO_CLEAN)
else()
    vcpkg_copy_tools(TOOL_NAMES fluid fltk-config AUTO_CLEAN)
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    file(REMOVE_RECURSE
        ${CURRENT_PACKAGES_DIR}/debug/bin
        ${CURRENT_PACKAGES_DIR}/bin
    )
endif()
file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/debug/include
    ${CURRENT_PACKAGES_DIR}/debug/share
)

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

file(INSTALL "${SOURCE_PATH}/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
