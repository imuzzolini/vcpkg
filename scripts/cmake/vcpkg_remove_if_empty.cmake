## # vcpkg_remove_if_empty
##
## Remove directories if they do not contain any file
##
## ## Usage
## ```cmake
## vcpkg_remove_if_empty([FOLDERS <folder1> ...])
## ```
##
## ## Notes
## This command should always be called by portfiles after they have finished rearranging the binary output.
##
## ## Parameters
## ### FOLDERS
## Path of folders that will be searched recursively for any file.
##
function(vcpkg_remove_if_empty)
    cmake_parse_arguments(_vrie "" "" "FOLDERS" ${ARGN})

    foreach(FOLDER ${_vrie_FOLDERS})
        file(GLOB_RECURSE FILES LIST_DIRECTORIES FALSE ${FOLDER}/*.*)
        list(LENGTH FILES FILES_COUNT)
        if(${FILES_COUNT} EQUAL 0)
            file(REMOVE_RECURSE ${FOLDER})
        endif()
    endforeach()
endfunction()