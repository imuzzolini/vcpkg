include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO openscenegraph/osgQt
    REF Qt4
    SHA512 426a4ba88f680978d24817248b99c68cafa4517144e6e3d2480612870c4a224bb955539cacb438274d4ee1c93c36d94f8437d142070b2ecde2b81517bf357e71
    HEAD_REF master
	PATCHES
        OsgMacroUtils.patch
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
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

#Debug
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# Handle License
file(COPY ${SOURCE_PATH}/LICENSE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/osg-qt)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/osg-qt/LICENSE.txt ${CURRENT_PACKAGES_DIR}/share/osg-qt/copyright)