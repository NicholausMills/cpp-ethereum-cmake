# Find Solidity
#
# Find the solidity includes and library
#
# This module defines
#  SOLIDITY_LIBRARIES, the libraries needed to use solidity.
#  TODO: SOLIDITY_INCLUDE_DIRS

set(l solidity)

# if the project is a subset of main cpp-ethereum project
# use same pattern for variables as Boost uses
if ((DEFINED solidity_VERSION) OR (DEFINED ethereum_VERSION))

	string(TOUPPER ${l} L)
	set ("SOLIDITY_LIBRARIES" ${l})

else()

	string(TOUPPER ${l} L)
	find_library(SOLIDITY_LIBRARY
		NAMES ${l}
		PATHS ${CMAKE_LIBRARY_PATH}
		PATH_SUFFIXES "lib${l}" "${l}" "lib${l}/Release" "lib${l}/Debug"
		NO_DEFAULT_PATH
	)

	set(SOLIDITY_LIBRARIES ${SOLIDITY_LIBRARY})

	if (DEFINED MSVC)
		find_library(SOLIDITY_LIBRARY_DEBUG
			NAMES ${l}
			PATHS ${CMAKE_LIBRARY_PATH}
			PATH_SUFFIXES "lib${l}/Debug" 
			NO_DEFAULT_PATH
		)

		set(SOLIDITY_LIBRARIES optimized ${SOLIDITY_LIBRARY} debug ${SOLIDITY_LIBRARY_DEBUG})

	endif()

endif()
