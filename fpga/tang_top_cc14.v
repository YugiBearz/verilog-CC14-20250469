// ============================================================================
// Asignatura: Sistemas Digitales con FPGA (ITLA)
// Estudiante: Urik Camilo Valenzuela Flynn · Matricula: 20250469
// Correo:     20250469@itla.edu.do
// Reto:       CC14 — Cola de notas de cuatro posiciones (FIFO sincrona)
// Modulo:     tang_top_cc14.v (Modulo de integracion fisica en FPGA)
// ============================================================================

`timescale 1ns / 1ps

/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNUSEDPARAM */
module tang_top_cc14 (
    input  wire       sys_clk,    // 50 MHz (Pin E2)
    input  wire       btn_rst_n,  // Reset activo bajo (G5)
    input  wire       btn_en,     // Enable activo alto (F5)
    input  wire       sw_push,    // Push cmd[0] (H8)
    input  wire       sw_pop,     // Pop cmd[1] (H7)
    input  wire [3:0] sw_note,    // data[3:0] (C11, B11, D11, G11)
    output wire [3:0] led_note,   // y[3:0] (A11, E11, K11, L5)
    output wire [2:0] led_count,  // y[6:4] (E10, L11, A10)
    output wire       led_push_ok,// y[7]
    output wire       led_pop_ok  // y[8]
);

    // Inversion de pulsador activo en bajo
    wire rst_raw = ~btn_rst_n;

    // Sincronizadores contra metaestabilidad (2FF)
    wire rst_s, en_s, push_s, pop_s;
    wire [3:0] note_s;

    sync2ff #(.WIDTH(1)) u_sr (.clk(sys_clk), .din(rst_raw),  .dout(rst_s));
    sync2ff #(.WIDTH(1)) u_se (.clk(sys_clk), .din(btn_en),   .dout(en_s));
    sync2ff #(.WIDTH(1)) u_sp (.clk(sys_clk), .din(sw_push),  .dout(push_s));
    sync2ff #(.WIDTH(1)) u_so (.clk(sys_clk), .din(sw_pop),   .dout(pop_s));
    sync2ff #(.WIDTH(4)) u_sn (.clk(sys_clk), .din(sw_note),  .dout(note_s));

    // Instancia del nucleo oficial CC14
    wire [15:0] core_y;
    top_module #(.K(3)) u_core (
        .clk (sys_clk),
        .rst (rst_s),
        .en  (en_s),
        .cmd ({6'b0, pop_s, push_s}),
        .data({4'b0, note_s}),
        .y   (core_y)
    );

    // Mapeo hacia los LEDs
    assign led_note    = core_y[3:0];
    assign led_count   = core_y[6:4];
    assign led_push_ok = core_y[7];
    assign led_pop_ok  = core_y[8];

endmodule
/* verilator lint_on UNUSEDPARAM */
/* verilator lint_on UNUSEDSIGNAL */
