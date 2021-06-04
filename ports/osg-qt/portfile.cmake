vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO openscenegraph/osgQt
    REF 2cb70673a4e83a618290e7ee66d52402a94ec3f6
    SHA512 29aeb5b31e70d5b12e69de7970b36ab7d1541c984873384a46c6468394e8562688c46ef39179820990817c94f283c7836c2c6ff207eefe385086d850ba3f8306
    HEAD_REF master
    PATCHES
        OsgMacroUtils.patch
        fix-static-install.patch
        CMakeLists.patch
)

if(VCPKG_TARGET_IS_OSX)
    string(APPEND VCPKG_CXX_FLAGS " -stdlib=libc++")
    string(APPEND VCPKG_C_FLAGS "") # both must be set
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(OPTIONS -DDYNAMIC_OPENSCENEGRAPH=ON)
else()
    set(OPTIONS -DDYNAMIC_OPENSCENEGRAPH=OFF)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS ${OPTIONS}
            -DBUILD_OSG_EXAMPLES=OFF
            -DOSG_BUILD_APPLICATION_BUNDLES=OFF
)

# The following is needed to let Qt tools (e.g. moc) load the shared libraries on which they depend
if(VCPKG_TARGET_IS_WINDOWS)
    set(ENV{PATH} "${CURRENT_INSTALLED_DIR}/bin${VCPKG_HOST_PATH_SEPARATOR}$ENV{PATH}")
elseif(VCPKG_TARGET_IS_LINUX)
    set(ENV{LD_LIBRARY_PATH} "${CURRENT_INSTALLED_DIR}/lib${VCPKG_HOST_PATH_SEPARATOR}$ENV{LD_LIBRARY_PATH}")
elseif(VCPKG_TARGET_IS_OSX)
    set(ENV{DYLD_LIBRARY_PATH} "${CURRENT_INSTALLED_DIR}/lib${VCPKG_HOST_PATH_SEPARATOR}$ENV{DYLD_LIBRARY_PATH}")
endif()

vcpkg_install_cmake()

if(VCPKG_TARGET_IS_LINUX)
    file(RENAME ${CURRENT_PACKAGES_DIR}/lib64 ${CURRENT_PACKAGES_DIR}/lib)
    file(RENAME ${CURRENT_PACKAGES_DIR}/debug/lib64 ${CURRENT_PACKAGES_DIR}/debug/lib)
endif()

#Debug
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# Handle License
file(COPY ${SOURCE_PATH}/LICENSE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(RENAME ${CURRENT_PACKAGES_DIR}/share/${PORT}/LICENSE.txt ${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright)
