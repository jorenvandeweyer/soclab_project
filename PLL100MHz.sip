set_global_assignment -entity "PLL100MHz" -library "lib_PLL100MHz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "PLL100MHz" -library "lib_PLL100MHz" -name IP_TOOL_VERSION "16.1"
set_global_assignment -entity "PLL100MHz" -library "lib_PLL100MHz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_PLL100MHz" -name SPD_FILE [file join $::quartus(sip_path) "PLL100MHz.spd"]

set_global_assignment -library "lib_PLL100MHz" -name MISC_FILE [file join $::quartus(sip_path) "PLL100MHz_sim/PLL100MHz.vo"]
