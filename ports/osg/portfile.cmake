include(vcpkg_common_functions)

set(OSG_VERSION "3.6.4")

# TODO: create functions to clean empty folders

function(move_executables)
    cmake_parse_arguments(move "" "FROM;TO" "" ${ARGN})

    file(MAKE_DIRECTORY ${move_TO})
    file(GLOB ITEMS_TO_MOVE ${move_FROM}/*.exe)
    foreach(ITEM ${ITEMS_TO_MOVE})
        get_filename_component(BASENAME ${ITEM} NAME_WLE)
        get_filename_component(FOLDER ${ITEM} DIRECTORY)
        set(PDB ${FOLDER}/${BASENAME}.pdb)
        file(COPY ${ITEM} DESTINATION ${move_TO})
        if(PDB AND EXISTS ${PDB})
            file(COPY ${PDB} DESTINATION ${move_TO})
        endif()
        file(REMOVE_RECURSE ${ITEM})
        if(PDB AND EXISTS ${PDB})
            file(REMOVE_RECURSE ${PDB})
        endif()
    endforeach()
endfunction()

vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO openscenegraph/OpenSceneGraph
    REF OpenSceneGraph-${OSG_VERSION}
    SHA512 7cb34fc279ba62a7d7177d3f065f845c28255688bd29026ffb305346e1bb2e515a22144df233e8a7246ed392044ee3e8b74e51bf655282d33ab27dcaf12f4b19
    HEAD_REF master
    PATCHES
        collada.patch
)

file(REMOVE ${SOURCE_PATH}/CMakeModules/FindSDL2.cmake)
vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DOSG_USE_UTF8_FILENAME=ON
)

vcpkg_install_cmake()

if(VCPKG_TARGET_IS_WINDOWS)
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        move_executables(
            FROM ${CURRENT_PACKAGES_DIR}/bin
            TO ${CURRENT_PACKAGES_DIR}/tools/osg
        )
        file(RENAME ${CURRENT_PACKAGES_DIR}/bin/osgPlugins-${OSG_VERSION} ${CURRENT_PACKAGES_DIR}/tools/osg/osgPlugins-${OSG_VERSION})
        if(EXISTS ${CURRENT_PACKAGES_DIR}/debug/include)
            file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
        endif()
    endif()
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        move_executables(
            FROM ${CURRENT_PACKAGES_DIR}/debug/bin
            TO ${CURRENT_PACKAGES_DIR}/debug/tools/osg
        )
        file(RENAME ${CURRENT_PACKAGES_DIR}/debug/bin/osgPlugins-${OSG_VERSION} ${CURRENT_PACKAGES_DIR}/debug/tools/osg/osgPlugins-${OSG_VERSION})
        if(VCPKG_BUILD_TYPE STREQUAL "debug")
            file(RENAME ${CURRENT_PACKAGES_DIR}/debug/include ${CURRENT_PACKAGES_DIR}/include)
        endif()
    endif()
endif()

# Handle copyright
file(COPY ${SOURCE_PATH}/LICENSE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/osg)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/osg/LICENSE.txt ${CURRENT_PACKAGES_DIR}/share/osg/copyright)
