macro(build_prx elf)
	message(Building PRX)
	add_custom_command(
		TARGET ${elf}
		POST_BUILD COMMAND
		${PRXGEN} ${elf} ${elf}.prx
	)
endmacro()
