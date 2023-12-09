# Find Eth
#
# Find the ethereum includes and library
#
# This module defines
#  ETH_XXX_LIBRARIES, the libraries needed to use ethereum.
#  ETH_FOUND, If false, do not try to use ethereum.
#  TODO: ETH_INCLUDE_DIRS

set(LIBS ethereum;evm;ethcore;lll;p2p;evmasm;devcrypto;evmcore;devcore;ethash-cl;ethash;scrypt;natspec;jsengine;jsconsole;evmjit;evmjit-cpp;solidity;secp256k1;testutils)

set(ETH_INCLUDE_DIRS ${ETH_INCLUDE_DIR})

# if the project is a subset of main cpp-ethereum project
# use same pattern for variables as Boost uses
if (DEFINED ethereum_VERSION)

	foreach (l ${LIBS}) 
		string(TOUPPER ${l} L)
		set ("Eth_${L}_LIBRARIES" ${l})
	endforeach()

else()

	foreach (l ${LIBS})
		string(TOUPPER ${l} L)

		find_library(Eth_${L}_LIBRARY
			NAMES ${l}
			PATHS ${CMAKE_LIBRARY_PATH}
			# TODO: fix the search paths when using Xcode
			PATH_SUFFIXES "lib${l}" "${l}" "lib${l}/Release" "lib${l}/Debug" 
			# libevmjit is nested...
			"evmjit/libevmjit" "evmjit/libevmjit/Release" "evmjit/libevmjit/Debug"
			"evmjit/libevmjit-cpp" "evmjit/libevmjit-cpp/Release" "evmjit/libevmjit-cpp/Debug"
			NO_DEFAULT_PATH
		)

		set(Eth_${L}_LIBRARIES ${Eth_${L}_LIBRARY})

		if (DEFINED MSVC)
			find_library(Eth_${L}_LIBRARY_DEBUG
				NAMES ${l}
				PATHS ${CMAKE_LIBRARY_PATH}
				PATH_SUFFIXES "lib${l}/Debug" 
				# libevmjit is nested...
				"evmjit/libevmjit/Debug"
				"evmjit/libevmjit-cpp/Debug"
				NO_DEFAULT_PATH
			)

			set(Eth_${L}_LIBRARIES optimized ${Eth_${L}_LIBRARY} debug ${Eth_${L}_LIBRARY_DEBUG})

		endif()
	endforeach()

endif()

