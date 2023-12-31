function(eth_apply*TARGET#REQUIRED)	
	if (CPUID_FOUND)
		target_include_directories(${TARGET} SYSTEM PUBLIC ${CPUID_INCLUDE_DIRS})
		target_link_libraries(${TARGET} ${CPUID_LIBRARIES})
	elseif (NOT ${REQUIRED} STREQUAL "OPTIONAL")
		message(FATAL_ERROR "CPUID library not found")
	endif()
endfunction()
 