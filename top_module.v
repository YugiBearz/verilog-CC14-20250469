// ============================================================================
// Asignatura: Sistemas Digitales con FPGA (ITLA)
// Estudiante: Urik Camilo Valenzuela Flynn · Matricula: 20250469
// Correo:     20250469@itla.edu.do
// Reto:       CC14 — Cola de notas de cuatro posiciones (FIFO sincrona)
// Modulo:     top_module.v
// ============================================================================

`timescale 1ns / 1ps

module top_module #(
    parameter integer K = 3
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    input  wire [7:0]  cmd,
    input  wire [7:0]  data,
    output wire [15:0] y
);

    // ------------------------------------------------------------------------
    // Senales de entrada decodificadas
    // ------------------------------------------------------------------------
    wire push_cmd = cmd[0];
    wire pop_cmd  = cmd[1];
    wire [3:0] in_note = data[3:0]; // Los 4 bits altos data[7:4] se ignoran

endmodule
