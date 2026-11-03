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

    // ------------------------------------------------------------------------
    // Tarea de verificacion de salidas (evaluada 1 ns despues de posedge clk)
    // ------------------------------------------------------------------------
    task check_outputs;
        input [3:0] exp_note;
        input [2:0] exp_count;
        input       exp_push_ok;
        input       exp_pop_ok;
        input [255:0] test_name;
        begin
            #1; // Comparacion estricta 1 ns despues del flanco positivo
            total_tests = total_tests + 1;
            if (y_unused !== 7'b0000000) begin
                $display("[ERROR][Ciclo %0d] %0s: y[15:9] no es cero. Obtenido=%b", cycle_count, test_name, y_unused);
                fail_tests = fail_tests + 1;
            end else if (y_last_note !== exp_note || y_count !== exp_count ||
                         y_push_ok !== exp_push_ok || y_pop_ok !== exp_pop_ok) begin
                $display("[ERROR][Ciclo %0d] %0s: FALLO!", cycle_count, test_name);
                $display("       Esperado: note=%0d, count=%0d, push_ok=%0b, pop_ok=%0b", exp_note, exp_count, exp_push_ok, exp_pop_ok);
                $display("       Obtenido: note=%0d, count=%0d, push_ok=%0b, pop_ok=%0b (y=0x%04h)", y_last_note, y_count, y_push_ok, y_pop_ok, y);
                fail_tests = fail_tests + 1;
            end else begin
                pass_tests = pass_tests + 1;
            end
        end
    endtask

    // Tarea para avanzar un ciclo con entradas especificadas
    task step_cycle;
        input       t_rst;
        input       t_en;
        input [7:0] t_cmd;
        input [7:0] t_data;
        begin
            @(negedge clk);
            rst  = t_rst;
            en   = t_en;
            cmd  = t_cmd;
            data = t_data;
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
    endtask

    initial begin
        clk         = 0;
        rst         = 1;
        en          = 1;
        cmd         = 8'h00;
        data        = 8'h00;
        total_tests = 0;
        pass_tests  = 0;
        fail_tests  = 0;
        cycle_count = 0;

        // Reset inicial
        step_cycle(1'b1, 1'b1, 8'h00, 8'h00);
        check_outputs(4'd0, 3'd0, 1'b0, 1'b0, "Reset Inicial");

        // --------------------------------------------------------------------
        // Ejemplo verificable del mandato:
        // Push 5, push 9, pop: ultima nota=5 y ocupacion=1.
        // Despues pop devuelve 9 y ocupacion=0; pop adicional no cambia ultima nota.
        // --------------------------------------------------------------------
        $display("--- Verificando Ejemplo del Mandato Oficial ---");
        step_cycle(1'b0, 1'b1, 8'h01, 8'hA5);
        check_outputs(4'd0, 3'd1, 1'b1, 1'b0, "Ejemplo: Push 5");

        step_cycle(1'b0, 1'b1, 8'h01, 8'h39);
        check_outputs(4'd0, 3'd2, 1'b1, 1'b0, "Ejemplo: Push 9");

        step_cycle(1'b0, 1'b1, 8'h02, 8'h00);
        check_outputs(4'd5, 3'd1, 1'b0, 1'b1, "Ejemplo: Pop -> 5, count=1");

        step_cycle(1'b0, 1'b1, 8'h02, 8'h00);
        check_outputs(4'd9, 3'd0, 1'b0, 1'b1, "Ejemplo: Pop -> 9, count=0");

        step_cycle(1'b0, 1'b1, 8'h02, 8'h00);
        check_outputs(4'd9, 3'd0, 1'b0, 1'b0, "Ejemplo: Pop adicional en vacio");

        // --------------------------------------------------------------------
        // GRUPO G1: Reset con FIFO llena y ultima nota distinta de cero
        // --------------------------------------------------------------------
        $display("--- Grupo G1: Reset con FIFO llena y ultima nota != 0 ---");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h01); check_outputs(4'd9, 3'd1, 1'b1, 1'b0, "G1: Push 1");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h02); check_outputs(4'd9, 3'd2, 1'b1, 1'b0, "G1: Push 2");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h03); check_outputs(4'd9, 3'd3, 1'b1, 1'b0, "G1: Push 3");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h04); check_outputs(4'd9, 3'd4, 1'b1, 1'b0, "G1: Push 4 (FIFO LLENA)");

        step_cycle(1'b1, 1'b1, 8'h03, 8'h0F);
        check_outputs(4'd0, 3'd0, 1'b0, 1'b0, "G1: Reset con FIFO llena y last_note!=0");

        // --------------------------------------------------------------------
        // GRUPO G2: Orden FIFO de varias notas y vuelta de punteros (Wrap-around)
        // --------------------------------------------------------------------
        $display("--- Grupo G2: Orden FIFO y vuelta de punteros circulares ---");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0A); check_outputs(4'd0, 3'd1, 1'b1, 1'b0, "G2: Push A");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0B); check_outputs(4'd0, 3'd2, 1'b1, 1'b0, "G2: Push B");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0C); check_outputs(4'd0, 3'd3, 1'b1, 1'b0, "G2: Push C");

        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd10, 3'd2, 1'b0, 1'b1, "G2: Pop A");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd11, 3'd1, 1'b0, 1'b1, "G2: Pop B");

        step_cycle(1'b0, 1'b1, 8'h01, 8'h0D); check_outputs(4'd11, 3'd2, 1'b1, 1'b0, "G2: Push D");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0E); check_outputs(4'd11, 3'd3, 1'b1, 1'b0, "G2: Push E (Wrap wr)");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0F); check_outputs(4'd11, 3'd4, 1'b1, 1'b0, "G2: Push F (Lleno)");

        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd12, 3'd3, 1'b0, 1'b1, "G2: Pop C");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd13, 3'd2, 1'b0, 1'b1, "G2: Pop D");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd14, 3'd1, 1'b0, 1'b1, "G2: Pop E (Wrap rd)");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd15, 3'd0, 1'b0, 1'b1, "G2: Pop F (Vacio)");

        // --------------------------------------------------------------------
        // GRUPO G3: Vacio, lleno, push rechazado y pop rechazado
        // --------------------------------------------------------------------
        $display("--- Grupo G3: Rechazos en vacio y en lleno ---");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00);
        check_outputs(4'd15, 3'd0, 1'b0, 1'b0, "G3: Pop rechazado en vacio");

        step_cycle(1'b0, 1'b1, 8'h01, 8'h01); check_outputs(4'd15, 3'd1, 1'b1, 1'b0, "G3: Push 1");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h02); check_outputs(4'd15, 3'd2, 1'b1, 1'b0, "G3: Push 2");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h03); check_outputs(4'd15, 3'd3, 1'b1, 1'b0, "G3: Push 3");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h04); check_outputs(4'd15, 3'd4, 1'b1, 1'b0, "G3: Push 4 (Lleno)");

        step_cycle(1'b0, 1'b1, 8'h01, 8'h09);
        check_outputs(4'd15, 3'd4, 1'b0, 1'b0, "G3: Push rechazado en lleno");

        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd1, 3'd3, 1'b0, 1'b1, "G3: Vaciar 1");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd2, 3'd2, 1'b0, 1'b1, "G3: Vaciar 2");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd3, 3'd1, 1'b0, 1'b1, "G3: Vaciar 3");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd4, 3'd0, 1'b0, 1'b1, "G3: Vaciar 4");

        // --------------------------------------------------------------------
        // GRUPO G4: Push + Pop simultaneos (Vacio, media ocupacion y lleno)
        // --------------------------------------------------------------------
        $display("--- Grupo G4: Transferencias simultaneas (Push+Pop) ---");
        step_cycle(1'b0, 1'b1, 8'h03, 8'h07);
        check_outputs(4'd4, 3'd1, 1'b1, 1'b0, "G4: Push+Pop en vacio (Solo push)");

        step_cycle(1'b0, 1'b1, 8'h03, 8'h08);
        check_outputs(4'd7, 3'd1, 1'b1, 1'b1, "G4: Push+Pop en media (count=1)");

        step_cycle(1'b0, 1'b1, 8'h01, 8'h09); check_outputs(4'd7, 3'd2, 1'b1, 1'b0, "G4: Llenando (count=2)");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0A); check_outputs(4'd7, 3'd3, 1'b1, 1'b0, "G4: Llenando (count=3)");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0B); check_outputs(4'd7, 3'd4, 1'b1, 1'b0, "G4: Llenando (count=4)");

        step_cycle(1'b0, 1'b1, 8'h03, 8'h0C);
        check_outputs(4'd8, 3'd4, 1'b1, 1'b1, "G4: Push+Pop en lleno (count=4)");

        // --------------------------------------------------------------------
        // GRUPO G5: Pausa con en=0 y borrado estricto de aceptaciones
        // --------------------------------------------------------------------
        $display("--- Grupo G5: Pausa (en=0) y borrado de aceptaciones ---");
        step_cycle(1'b0, 1'b0, 8'h03, 8'h0D);
        check_outputs(4'd8, 3'd4, 1'b0, 1'b0, "G5: Pausa con en=0 (aceptaciones a cero)");

        step_cycle(1'b0, 1'b0, 8'h01, 8'h0E);
        check_outputs(4'd8, 3'd4, 1'b0, 1'b0, "G5: Pausa segundo ciclo");

        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd9,  3'd3, 1'b0, 1'b1, "G5: Reanudar Pop 9");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd10, 3'd2, 1'b0, 1'b1, "G5: Reanudar Pop 10");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd11, 3'd1, 1'b0, 1'b1, "G5: Reanudar Pop 11");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd12, 3'd0, 1'b0, 1'b1, "G5: Reanudar Pop 12");

        #10;
        $finish;
    end

endmodule
