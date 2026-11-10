// ============================================================================
// Asignatura: Sistemas Digitales con FPGA (ITLA)
// Estudiante: Urik Camilo Valenzuela Flynn · Matricula: 20250469
// Reto CC14: Cola de notas de cuatro posiciones (FIFO sincrona)
// Tarjeta:    Sipeed Tang Primer 25K (Gowin GW5A-LV25MG121)
// Archivo:    top.sdc (Gowin Timing Constraints)
// ============================================================================

// Reloj del sistema a 50 MHz (Periodo = 20.0 ns)
create_clock -name sys_clk -period 20.000 [get_ports {sys_clk}] -waveform {0.000 10.000}
