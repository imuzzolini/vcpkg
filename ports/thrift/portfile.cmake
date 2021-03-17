# We currently insist on static only because:
# - Thrift doesn't yet support building as a DLL on Windows,
# - x64-linux only builds static anyway.
# From https://github.com/apache/thrift/blob/master/CHANGES.md
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

# VI-grade additions for:
#  - VI-GraphSim application based on Unity
#  - VI-SimController application based on Python

# VI-grade addition to install .NET runtime
function(build_thrift_dotnet_runtime)
    cmake_parse_arguments(build_thrift_dotnet_runtime "" "CONFIGURATION;WORKING_DIRECTORY;LOGNAME" "" ${ARGN})

    file(TO_NATIVE_PATH "${build_thrift_dotnet_runtime_WORKING_DIRECTORY}/net/msbuild.txt" MSBUILD_INPUT)
    file(TO_NATIVE_PATH "${build_thrift_dotnet_runtime_WORKING_DIRECTORY}/net/out" MSBUILD_OUTDIR)
    file(TO_NATIVE_PATH "${build_thrift_dotnet_runtime_WORKING_DIRECTORY}/net/obj" MSBUILD_OBJDIR)
    file(TO_NATIVE_PATH "${SOURCE_PATH}/lib/csharp/src/Thrift.csproj" MSBUILD_PROJECT)

    file(WRITE "${MSBUILD_INPUT}" "${MSBUILD_PROJECT} ")
    file(APPEND "${MSBUILD_INPUT}" "/t:Build ")
    file(APPEND "${MSBUILD_INPUT}" "/p:Configuration=${build_thrift_dotnet_runtime_CONFIGURATION} ")
    file(APPEND "${MSBUILD_INPUT}" "/p:Platform=AnyCPU ")
    file(APPEND "${MSBUILD_INPUT}" "/p:OutDir=${MSBUILD_OUTDIR}\\ ")
    file(APPEND "${MSBUILD_INPUT}" "/p:IntermediateOutputPath=${MSBUILD_OBJDIR}\\ ")

    vcpkg_execute_required_process(
        COMMAND msbuild @${MSBUILD_INPUT}
        WORKING_DIRECTORY ${build_thrift_dotnet_runtime_WORKING_DIRECTORY}
        LOGNAME ${build_thrift_dotnet_runtime_LOGNAME}
    )

    file(INSTALL ${MSBUILD_OUTDIR}/Thrift.dll DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}/dotnet/${build_thrift_dotnet_runtime_CONFIGURATION})
    file(INSTALL ${MSBUILD_OUTDIR}/Thrift.pdb DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}/dotnet/${build_thrift_dotnet_runtime_CONFIGURATION})
endfunction()

# VI-grade addition to install Python runtime
vcpkg_find_acquire_program(PYTHON2)
get_filename_component(PYTHON2_DIR "${PYTHON2}" DIRECTORY)
vcpkg_add_to_path(${PYTHON2_DIR})

vcpkg_find_acquire_program(FLEX)
vcpkg_find_acquire_program(BISON)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO apache/thrift
    REF cecee50308fc7e6f77f55b3fd906c1c6c471fa2f #0.13.0
    SHA512 4097fd7951a4d47f2fadc520a54fd1b91b10769d65e899c6bab490dd7ac459e12bb2aa335df8fdfc61a32095033bfac928a54660abb1ee54ca14a144216c3339
    HEAD_REF master
    PATCHES
      "correct-paths.patch"
)

if (VCPKG_TARGET_IS_OSX)
    message(WARNING "${PORT} requires bison version greater than 2.5,\n\
please use command \`brew install bison\` to install bison")
endif()

# note we specify values for WITH_STATIC_LIB and WITH_SHARED_LIB because even though
# they're marked as deprecated, Thrift incorrectly hard-codes a value for BUILD_SHARED_LIBS.
vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    NO_CHARSET_FLAG
    OPTIONS
        -DWITH_SHARED_LIB=off
        -DWITH_STATIC_LIB=on
        -DWITH_STDTHREADS=ON
        -DBUILD_TESTING=off
        -DBUILD_JAVA=off
        -DBUILD_C_GLIB=off
        -DBUILD_PYTHON=on
        -DBUILD_CPP=on
        -DBUILD_HASKELL=off
        -DBUILD_TUTORIALS=off
        -DFLEX_EXECUTABLE=${FLEX}
        -DCMAKE_DISABLE_FIND_PACKAGE_Qt5=TRUE
        -DBISON_EXECUTABLE=${BISON}
        -DPYTHON_EXECUTABLE=${PYTHON2}
)

vcpkg_install_cmake()

vcpkg_copy_pdbs()

# Move CMake config files to the right place
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/thrift)

file(GLOB COMPILER "${CURRENT_PACKAGES_DIR}/bin/thrift" "${CURRENT_PACKAGES_DIR}/bin/thrift.exe")
if(COMPILER)
    file(COPY ${COMPILER} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/thrift)
    file(REMOVE ${COMPILER})
    vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/thrift)
endif()

file(GLOB COMPILERD "${CURRENT_PACKAGES_DIR}/debug/bin/thrift" "${CURRENT_PACKAGES_DIR}/debug/bin/thrift.exe")
if(COMPILERD)
    file(REMOVE ${COMPILERD})
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

if ("${VCPKG_LIBRARY_LINKAGE}" STREQUAL "static")
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/bin)
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin)
endif()

# VI-grade addition to install .NET runtime
if(VCPKG_TARGET_IS_WINDOWS)
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        build_thrift_dotnet_runtime(
            CONFIGURATION Release
            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
            LOGNAME build-${TARGET_TRIPLET}-rel
        )
    endif()

    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        build_thrift_dotnet_runtime(
            CONFIGURATION Debug
            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
            LOGNAME build-${TARGET_TRIPLET}-dbg
        )
    endif()
endif()

# VI-grade addition to install Python runtime
file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/share/${PORT}/python)
file(RENAME ${SOURCE_PATH}/lib/py/src ${CURRENT_PACKAGES_DIR}/share/${PORT}/python/thrift)

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)