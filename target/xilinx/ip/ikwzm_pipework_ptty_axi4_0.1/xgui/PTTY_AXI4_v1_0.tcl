# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "CSR_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CSR_DATA_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CSR_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RXD_BUF_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RXD_BYTES" -parent ${Page_0}
  ipgui::add_param $IPINST -name "TXD_BUF_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "TXD_BYTES" -parent ${Page_0}


}

proc update_PARAM_VALUE.CSR_ADDR_WIDTH { PARAM_VALUE.CSR_ADDR_WIDTH } {
	# Procedure called to update CSR_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CSR_ADDR_WIDTH { PARAM_VALUE.CSR_ADDR_WIDTH } {
	# Procedure called to validate CSR_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.CSR_DATA_WIDTH { PARAM_VALUE.CSR_DATA_WIDTH } {
	# Procedure called to update CSR_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CSR_DATA_WIDTH { PARAM_VALUE.CSR_DATA_WIDTH } {
	# Procedure called to validate CSR_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.CSR_ID_WIDTH { PARAM_VALUE.CSR_ID_WIDTH } {
	# Procedure called to update CSR_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CSR_ID_WIDTH { PARAM_VALUE.CSR_ID_WIDTH } {
	# Procedure called to validate CSR_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.RXD_BUF_DEPTH { PARAM_VALUE.RXD_BUF_DEPTH } {
	# Procedure called to update RXD_BUF_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RXD_BUF_DEPTH { PARAM_VALUE.RXD_BUF_DEPTH } {
	# Procedure called to validate RXD_BUF_DEPTH
	return true
}

proc update_PARAM_VALUE.RXD_BYTES { PARAM_VALUE.RXD_BYTES } {
	# Procedure called to update RXD_BYTES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RXD_BYTES { PARAM_VALUE.RXD_BYTES } {
	# Procedure called to validate RXD_BYTES
	return true
}

proc update_PARAM_VALUE.TXD_BUF_DEPTH { PARAM_VALUE.TXD_BUF_DEPTH } {
	# Procedure called to update TXD_BUF_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TXD_BUF_DEPTH { PARAM_VALUE.TXD_BUF_DEPTH } {
	# Procedure called to validate TXD_BUF_DEPTH
	return true
}

proc update_PARAM_VALUE.TXD_BYTES { PARAM_VALUE.TXD_BYTES } {
	# Procedure called to update TXD_BYTES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TXD_BYTES { PARAM_VALUE.TXD_BYTES } {
	# Procedure called to validate TXD_BYTES
	return true
}


proc update_MODELPARAM_VALUE.TXD_BUF_DEPTH { MODELPARAM_VALUE.TXD_BUF_DEPTH PARAM_VALUE.TXD_BUF_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TXD_BUF_DEPTH}] ${MODELPARAM_VALUE.TXD_BUF_DEPTH}
}

proc update_MODELPARAM_VALUE.RXD_BUF_DEPTH { MODELPARAM_VALUE.RXD_BUF_DEPTH PARAM_VALUE.RXD_BUF_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RXD_BUF_DEPTH}] ${MODELPARAM_VALUE.RXD_BUF_DEPTH}
}

proc update_MODELPARAM_VALUE.CSR_ADDR_WIDTH { MODELPARAM_VALUE.CSR_ADDR_WIDTH PARAM_VALUE.CSR_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CSR_ADDR_WIDTH}] ${MODELPARAM_VALUE.CSR_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.CSR_DATA_WIDTH { MODELPARAM_VALUE.CSR_DATA_WIDTH PARAM_VALUE.CSR_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CSR_DATA_WIDTH}] ${MODELPARAM_VALUE.CSR_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.CSR_ID_WIDTH { MODELPARAM_VALUE.CSR_ID_WIDTH PARAM_VALUE.CSR_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CSR_ID_WIDTH}] ${MODELPARAM_VALUE.CSR_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.RXD_BYTES { MODELPARAM_VALUE.RXD_BYTES PARAM_VALUE.RXD_BYTES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RXD_BYTES}] ${MODELPARAM_VALUE.RXD_BYTES}
}

proc update_MODELPARAM_VALUE.TXD_BYTES { MODELPARAM_VALUE.TXD_BYTES PARAM_VALUE.TXD_BYTES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TXD_BYTES}] ${MODELPARAM_VALUE.TXD_BYTES}
}

