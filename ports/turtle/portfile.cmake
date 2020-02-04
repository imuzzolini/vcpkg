set(TURTLE_VERSION "1.3.1")

vcpkg_download_distfile(ARCHIVE
    URLS "https://sourceforge.net/projects/turtle/files/turtle/${TURTLE_VERSION}/turtle-${TURTLE_VERSION}.zip/download"
    FILENAME "turtle-${TURTLE_VERSION}.zip"
    SHA512 be70ae25d685032a44a650b9a157bb66d588fb21261fe2db157be8c7e828afebb1edcd6a529bb713b44ece00fc9e131af744c9a136772b3971c7f4ea91971fcc
)

vcpkg_download_distfile(BOOST_LICENSE
    URLS "https://www.boost.org/LICENSE_1_0.txt"
    FILENAME "LICENSE_1_0.txt"
    SHA512 d6078467835dba8932314c1c1e945569a64b065474d7aced27c9a7acc391d52e9f234138ed9f1aa9cd576f25f12f557e0b733c14891d42c16ecdc4a7bd4d60b8
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH
    ARCHIVE ${ARCHIVE}
    NO_REMOVE_ONE_LEVEL
)

file(COPY ${SOURCE_PATH}/include DESTINATION ${CURRENT_PACKAGES_DIR})
file(INSTALL ${BOOST_LICENSE} DESTINATION ${CURRENT_PACKAGES_DIR}/share/turtle RENAME copyright)