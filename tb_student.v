// ============================================================================
// Asignatura: Sistemas Digitales con FPGA (ITLA)
// Estudiante: Urik Camilo Valenzuela Flynn · Matricula: 20250469
// Correo:     20250469@itla.edu.do
// Reto:       CC14 — Cola de notas de cuatro posiciones (FIFO sincrona)
// Modulo:     tb_student.v (Banco de pruebas exhaustivo automatizado)
// ============================================================================

`timescale 1ns / 1ps

module tb_student;

    // Parametros de simulacion
    parameter integer K_VAL = 3;
    localparam CLK_PERIOD   = 10; // 100 MHz (periodo = 10 ns)

    // Entradas al DUT (registros en el testbench)
    reg        clk;
    reg        rst;
    reg        en;
    reg  [7:0] cmd;
    reg  [7:0] data;

    // Salida del DUT
    wire [15:0] y;

    // Desglose de campos de salida para verificacion
    wire [3:0] y_last_note = y[3:0];
    wire [2:0] y_count     = y[6:4];
    wire       y_push_ok   = y[7];
    wire       y_pop_ok    = y[8];
    wire [6:0] y_unused    = y[15:9];

    // Variables de control y contabilidad de pruebas
    integer total_tests = 0;
    integer pass_tests  = 0;
    integer fail_tests  = 0;
    integer cycle_count = 0;

    // Instancia del Dispositivo Bajo Prueba (DUT)
    top_module #(.K(K_VAL)) dut (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .cmd (cmd),
        .data(data),
        .y   (y)
    );

    // ------------------------------------------------------------------------
    // Generador de Reloj
    // ------------------------------------------------------------------------
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        en  = 0;
        cmd = 8'h00;
        data = 8'h00;
        #20;
    end

endmodule
