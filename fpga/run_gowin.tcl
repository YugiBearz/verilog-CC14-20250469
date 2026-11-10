# ==============================================================================
# Script de Automatizacion Gowin EDA — Sistemas Digitales con FPGA (ITLA)
# Estudiante: Urik Camilo Valenzuela Flynn · Matricula: 20250469
# Reto CC14: Cola de notas de cuatro posiciones (FIFO sincrona)
# Tarjeta:    Sipeed Tang Primer 25K (GW5A-LV25MG121NC1/I0)
# ==============================================================================

set_device -name GW5A-25A GW5A-LV25MG121NC1/I0

# 1. Archivos fuente RTL
add_file -type verilog "../top_module.v"
add_file -type verilog "sync2ff.v"
add_file -type verilog "tang_top_cc14.v"

# 2. Restricciones fisicas y temporales
add_file -type cst "top.cst"
add_file -type sdc "top.sdc"

# 3. Configuracion de modulo superior y optimizacion
set_option -top_module tang_top_cc14
set_option -output_base_name tang_top_cc14
set_option -verilog_std v2001
set_option -use_cpu_as_gpio 1
set_option -use_sspi_as_gpio 1

# 4. Flujo de sintesis y ruteo
run syn
run pnr
