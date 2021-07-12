set_property PACKAGE_PIN U27 [get_ports clk_100]
set_property IOSTANDARD LVCMOS25 [get_ports clk_100]
set_property PACKAGE_PIN F21 [get_ports pcie_rst]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_rst]
set_property PULLUP true [get_ports pcie_rst]


set_property PACKAGE_PIN L8 [get_ports {pcie_refclk_clk_p[0]}]
set_property PACKAGE_PIN Y2 [get_ports {pcie_txp[7]}]
set_property PACKAGE_PIN V2 [get_ports {pcie_txp[6]}]
set_property PACKAGE_PIN U4 [get_ports {pcie_txp[5]}]
set_property PACKAGE_PIN T2 [get_ports {pcie_txp[4]}]
set_property PACKAGE_PIN P2 [get_ports {pcie_txp[3]}]
set_property PACKAGE_PIN N4 [get_ports {pcie_txp[2]}]
set_property PACKAGE_PIN M2 [get_ports {pcie_txp[1]}]
set_property PACKAGE_PIN L4 [get_ports {pcie_txp[0]}]

set_false_path -from [get_cells -hierarchical -filter { NAME =~  "*offset*" }]
set_false_path -from [get_pins -hierarchical -filter { NAME =~  "*slv_reg*" }]


set_false_path -from [get_ports pcie_rst]

set_property CONFIG_MODE BPI16 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
