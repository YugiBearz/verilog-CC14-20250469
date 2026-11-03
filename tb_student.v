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

    // Variables para bucles y modelo de oro en G6
    integer i;
    reg [3:0] prng_note;
    reg [1:0] prng_op;
    reg [3:0] golden_mem [0:3];
    reg [1:0] golden_wr_ptr;
    reg [1:0] golden_rd_ptr;
    reg [2:0] golden_count;
    reg [3:0] golden_last_note;
    reg       golden_push_ok;
    reg       golden_pop_ok;

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

    // ------------------------------------------------------------------------
    // Secuencia de Pruebas (G1 a G6)
    // ------------------------------------------------------------------------
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

        $display("====================================================================");
        $display("Iniciando Verificacion Automatizada tb_student (K=%0d)...", K_VAL);
        $display("====================================================================");

        // Reset inicial
        step_cycle(1'b1, 1'b1, 8'h00, 8'h00);
        check_outputs(4'd0, 3'd0, 1'b0, 1'b0, "Reset Inicial");

        // --------------------------------------------------------------------
        // Ejemplo verificable del mandato:
        // Push 5, push 9, pop: ultima nota=5 y ocupacion=1.
        // Despues pop devuelve 9 y ocupacion=0; pop adicional no cambia ultima nota.
        // --------------------------------------------------------------------
        $display("--- Verificando Ejemplo del Mandato Oficial ---");
        // Push 5 (usando bits altos de data diferentes para probar ignorado)
        step_cycle(1'b0, 1'b1, 8'h01, 8'hA5);
        check_outputs(4'd0, 3'd1, 1'b1, 1'b0, "Ejemplo: Push 5");

        // Push 9
        step_cycle(1'b0, 1'b1, 8'h01, 8'h39);
        check_outputs(4'd0, 3'd2, 1'b1, 1'b0, "Ejemplo: Push 9");

        // Pop (debe salir 5, count=1)
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00);
        check_outputs(4'd5, 3'd1, 1'b0, 1'b1, "Ejemplo: Pop -> 5, count=1");

        // Pop (debe salir 9, count=0)
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00);
        check_outputs(4'd9, 3'd0, 1'b0, 1'b1, "Ejemplo: Pop -> 9, count=0");

        // Pop adicional en vacio (rechazado, last_note retiene 9)
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00);
        check_outputs(4'd9, 3'd0, 1'b0, 1'b0, "Ejemplo: Pop adicional en vacio");

        // --------------------------------------------------------------------
        // GRUPO G1: Reset con FIFO llena y ultima nota distinta de cero
        // --------------------------------------------------------------------
        $display("--- Grupo G1: Reset con FIFO llena y ultima nota != 0 ---");
        // Llenar la FIFO con 4 notas: 1, 2, 3, 4
        step_cycle(1'b0, 1'b1, 8'h01, 8'h01);
        check_outputs(4'd9, 3'd1, 1'b1, 1'b0, "G1: Push 1");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h02);
        check_outputs(4'd9, 3'd2, 1'b1, 1'b0, "G1: Push 2");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h03);
        check_outputs(4'd9, 3'd3, 1'b1, 1'b0, "G1: Push 3");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h04);
        check_outputs(4'd9, 3'd4, 1'b1, 1'b0, "G1: Push 4 (FIFO LLENA)");

        // Aplicar Reset activo con FIFO llena y comandos presentes
        step_cycle(1'b1, 1'b1, 8'h03, 8'h0F);
        check_outputs(4'd0, 3'd0, 1'b0, 1'b0, "G1: Reset con FIFO llena y last_note!=0");

        // --------------------------------------------------------------------
        // GRUPO G2: Orden FIFO de varias notas y vuelta de punteros (Wrap-around)
        // --------------------------------------------------------------------
        $display("--- Grupo G2: Orden FIFO y vuelta de punteros circulares ---");
        // Insertar notas 10, 11, 12
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0A); check_outputs(4'd0, 3'd1, 1'b1, 1'b0, "G2: Push A");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0B); check_outputs(4'd0, 3'd2, 1'b1, 1'b0, "G2: Push B");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0C); check_outputs(4'd0, 3'd3, 1'b1, 1'b0, "G2: Push C");
        // Extraer dos notas: deben ser A y B
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd10, 3'd2, 1'b0, 1'b1, "G2: Pop A");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd11, 3'd1, 1'b0, 1'b1, "G2: Pop B");
        // Insertar tres notas mas para forzar wrap-around en wr_ptr: 13, 14, 15
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0D); check_outputs(4'd11, 3'd2, 1'b1, 1'b0, "G2: Push D");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0E); check_outputs(4'd11, 3'd3, 1'b1, 1'b0, "G2: Push E (Wrap wr)");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0F); check_outputs(4'd11, 3'd4, 1'b1, 1'b0, "G2: Push F (Lleno)");
        // Extraer las cuatro notas en orden estricto FIFO: C, D, E, F (fuerza wrap-around en rd_ptr)
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd12, 3'd3, 1'b0, 1'b1, "G2: Pop C");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd13, 3'd2, 1'b0, 1'b1, "G2: Pop D");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd14, 3'd1, 1'b0, 1'b1, "G2: Pop E (Wrap rd)");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd15, 3'd0, 1'b0, 1'b1, "G2: Pop F (Vacio)");

        // --------------------------------------------------------------------
        // GRUPO G3: Vacio, lleno, push rechazado y pop rechazado
        // --------------------------------------------------------------------
        $display("--- Grupo G3: Rechazos en vacio y en lleno ---");
        // En vacio: Pop rechazado
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00);
        check_outputs(4'd15, 3'd0, 1'b0, 1'b0, "G3: Pop rechazado en vacio");

        // Llenar cola: 4 notas
        step_cycle(1'b0, 1'b1, 8'h01, 8'h01); check_outputs(4'd15, 3'd1, 1'b1, 1'b0, "G3: Push 1");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h02); check_outputs(4'd15, 3'd2, 1'b1, 1'b0, "G3: Push 2");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h03); check_outputs(4'd15, 3'd3, 1'b1, 1'b0, "G3: Push 3");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h04); check_outputs(4'd15, 3'd4, 1'b1, 1'b0, "G3: Push 4 (Lleno)");

        // Intentar PUSH en lleno (debe ser rechazado: push_ok=0, count=4)
        step_cycle(1'b0, 1'b1, 8'h01, 8'h09);
        check_outputs(4'd15, 3'd4, 1'b0, 1'b0, "G3: Push rechazado en lleno");

        // Vaciar la cola para dejarla limpia
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd1, 3'd3, 1'b0, 1'b1, "G3: Vaciar 1");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd2, 3'd2, 1'b0, 1'b1, "G3: Vaciar 2");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd3, 3'd1, 1'b0, 1'b1, "G3: Vaciar 3");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd4, 3'd0, 1'b0, 1'b1, "G3: Vaciar 4");

        // --------------------------------------------------------------------
        // GRUPO G4: Push + Pop simultaneos (Vacio, media ocupacion y lleno)
        // --------------------------------------------------------------------
        $display("--- Grupo G4: Transferencias simultaneas (Push+Pop) ---");
        // 1. En vacio: solo se acepta push; pop rechazado; no hay bypass; count=1
        step_cycle(1'b0, 1'b1, 8'h03, 8'h07);
        check_outputs(4'd4, 3'd1, 1'b1, 1'b0, "G4: Push+Pop en vacio (Solo push)");

        // 2. En ocupacion media (count=1): ambos se aceptan, sale la nota 7, entra nota 8, count se queda en 1
        step_cycle(1'b0, 1'b1, 8'h03, 8'h08);
        check_outputs(4'd7, 3'd1, 1'b1, 1'b1, "G4: Push+Pop en media (count=1)");

        // Llenar hasta count=4: metemos 9, 10, 11
        step_cycle(1'b0, 1'b1, 8'h01, 8'h09); check_outputs(4'd7, 3'd2, 1'b1, 1'b0, "G4: Llenando (count=2)");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0A); check_outputs(4'd7, 3'd3, 1'b1, 1'b0, "G4: Llenando (count=3)");
        step_cycle(1'b0, 1'b1, 8'h01, 8'h0B); check_outputs(4'd7, 3'd4, 1'b1, 1'b0, "G4: Llenando (count=4)");

        // 3. En lleno (count=4): Push+Pop simultaneos: sale la nota mas antigua (8), entra nota 12, count se queda en 4
        step_cycle(1'b0, 1'b1, 8'h03, 8'h0C);
        check_outputs(4'd8, 3'd4, 1'b1, 1'b1, "G4: Push+Pop en lleno (count=4)");

        // --------------------------------------------------------------------
        // GRUPO G5: Pausa con en=0 y borrado estricto de aceptaciones
        // --------------------------------------------------------------------
        $display("--- Grupo G5: Pausa (en=0) y borrado de aceptaciones ---");
        // En el ciclo anterior hubo push_ok=1 y pop_ok=1.
        // Ahora ponemos en=0 con comandos presentes: las aceptaciones DEBEN irse a 0 inmediatamente
        step_cycle(1'b0, 1'b0, 8'h03, 8'h0D);
        check_outputs(4'd8, 3'd4, 1'b0, 1'b0, "G5: Pausa con en=0 (aceptaciones a cero)");

        // Mantener en=0 otro ciclo
        step_cycle(1'b0, 1'b0, 8'h01, 8'h0E);
        check_outputs(4'd8, 3'd4, 1'b0, 1'b0, "G5: Pausa segundo ciclo");

        // Reactivar en=1 y comprobar que los datos siguen intactos:
        // Extraemos las 4 notas pendientes: deben ser 9, 10, 11, 12
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd9,  3'd3, 1'b0, 1'b1, "G5: Reanudar Pop 9");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd10, 3'd2, 1'b0, 1'b1, "G5: Reanudar Pop 10");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd11, 3'd1, 1'b0, 1'b1, "G5: Reanudar Pop 11");
        step_cycle(1'b0, 1'b1, 8'h02, 8'h00); check_outputs(4'd12, 3'd0, 1'b0, 1'b1, "G5: Reanudar Pop 12");

        // --------------------------------------------------------------------
        // GRUPO G6: 900 ciclos pseudoaleatorios reproducibles con modelo de oro
        // --------------------------------------------------------------------
        $display("--- Grupo G6: 900 Ciclos Pseudoaleatorios Reproducibles ---");
        golden_wr_ptr    = 0;
        golden_rd_ptr    = 0;
        golden_count     = 0;
        golden_last_note = 12; // Retiene el 12 del grupo anterior
        golden_push_ok   = 0;
        golden_pop_ok    = 0;

        for (i = 0; i < 900; i = i + 1) begin
            // Generador pseudoaleatorio de comandos y notas
            prng_note = $urandom_range(0, 15);
            prng_op   = $urandom_range(0, 3); // 0=none, 1=pop, 2=push, 3=both
            
            // Ocasionalmente inyectar reset o pausas de enable
            if (i == 100 || i == 350 || i == 700) begin
                // Pulso de Reset
                step_cycle(1'b1, 1'b1, 8'h00, 8'h00);
                golden_wr_ptr    = 0;
                golden_rd_ptr    = 0;
                golden_count     = 0;
                golden_last_note = 0;
                golden_push_ok   = 0;
                golden_pop_ok    = 0;
            end else if (i % 25 == 0) begin
                // Pausa con en = 0
                step_cycle(1'b0, 1'b0, {6'h0, prng_op}, {4'hF, prng_note});
                golden_push_ok = 0;
                golden_pop_ok  = 0;
            end else begin
                // Operacion normal con en = 1
                // Calcular comportamiento esperado en el modelo de oro
                golden_push_ok = 0;
                golden_pop_ok  = 0;
                case (prng_op)
                    2'b00: begin /* nada */ end
                    2'b01: begin // solo pop (cmd[1]=1)
                        if (golden_count > 0) begin
                            golden_last_note = golden_mem[golden_rd_ptr];
                            golden_rd_ptr    = golden_rd_ptr + 1'b1;
                            golden_count     = golden_count - 1'b1;
                            golden_pop_ok    = 1;
                        end
                    end
                    2'b10: begin // solo push (cmd[0]=1)
                        if (golden_count < 4) begin
                            golden_mem[golden_wr_ptr] = prng_note;
                            golden_wr_ptr             = golden_wr_ptr + 1'b1;
                            golden_count              = golden_count + 1'b1;
                            golden_push_ok            = 1;
                        end
                    end
                    2'b11: begin // ambos
                        if (golden_count == 0) begin
                            golden_mem[golden_wr_ptr] = prng_note;
                            golden_wr_ptr             = golden_wr_ptr + 1'b1;
                            golden_count              = 1;
                            golden_push_ok            = 1;
                            golden_pop_ok             = 0;
                        end else begin
                            golden_last_note          = golden_mem[golden_rd_ptr];
                            golden_rd_ptr             = golden_rd_ptr + 1'b1;
                            golden_mem[golden_wr_ptr] = prng_note;
                            golden_wr_ptr             = golden_wr_ptr + 1'b1;
                            golden_push_ok            = 1;
                            golden_pop_ok             = 1;
                        end
                    end
                endcase

                // Mapear comandos a cmd: cmd[0]=push (bit 1 de prng_op), cmd[1]=pop (bit 0 de prng_op)
                step_cycle(1'b0, 1'b1, {6'h2A, prng_op[0], prng_op[1]}, {4'hC, prng_note});
            end

            check_outputs(golden_last_note, golden_count, golden_push_ok, golden_pop_ok, "G6: Aleatorio");
        end

        // --------------------------------------------------------------------
        // Reporte Final
        // --------------------------------------------------------------------
        $display("====================================================================");
        $display("RESUMEN DE PRUEBAS AUTOMATIZADAS (K=%0d):", K_VAL);
        $display("Total de verificaciones ciclo a ciclo: %0d", total_tests);
        $display("Pruebas PASADAS : %0d", pass_tests);
        $display("Pruebas FALLADAS: %0d", fail_tests);
        if (fail_tests == 0) begin
            $display("RESULTADO FINAL : >>> 100%% PASS (0 ERRORES) <<<");
        end else begin
            $display("RESULTADO FINAL : >>> HUBO FALLOS EN LA SIMULACION <<<");
        end
        $display("====================================================================");
        $finish;
    end

endmodule
