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

    // ------------------------------------------------------------------------
    // Registros internos de almacenamiento y punteros
    // ------------------------------------------------------------------------
    reg [3:0] mem [0:3];     // 4 posiciones de 4 bits para notas musicales
    reg [1:0] wr_ptr;        // Puntero circular de escritura (0..3)
    reg [1:0] rd_ptr;        // Puntero circular de lectura (0..3)
    reg [2:0] count;         // Ocupacion de la cola (0..4)
    reg [3:0] last_note;     // Ultima nota extraida satisfactoriamente

    // Banderas registradas de aceptacion (pulsos de 1 ciclo)
    reg push_ok;
    reg pop_ok;

    // ------------------------------------------------------------------------
    // Logica secuencial sincrona gobernada por clk
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            // 1. Reset sincrono prioritario:
            // Cola vacia, ultima nota = 0, y ambas aceptaciones = 0
            wr_ptr    <= 2'b00;
            rd_ptr    <= 2'b00;
            count     <= 3'b000;
            last_note <= 4'b0000;
            push_ok   <= 1'b0;
            pop_ok    <= 1'b0;
        end else begin
            // Regla estricta del contrato:
            // "Las aceptaciones se borran cada flanco incluso con en=0."
            push_ok <= 1'b0;
            pop_ok  <= 1'b0;

            if (en) begin
                // Decision basada en la ocupacion previa al flanco actual
                case ({push_cmd, pop_cmd})
                    2'b00: begin
                        // Sin comandos: cola y ultima nota se conservan intactas
                    end

                    2'b01: begin
                        // Solo POP solicitado:
                        // Se acepta si la cola no estaba vacia (count > 0)
                        if (count > 3'd0) begin
                            last_note <= mem[rd_ptr];
                            rd_ptr    <= rd_ptr + 1'b1;
                            count     <= count - 1'b1;
                            pop_ok    <= 1'b1;
                        end
                        // Si count == 0: pop rechazado (pop_ok = 0, last_note retiene su valor)
                    end

                    2'b10: begin
                        // Solo PUSH solicitado:
                        // Se acepta si habia espacio (count < 4)
                        if (count < 3'd4) begin
                            mem[wr_ptr] <= in_note;
                            wr_ptr      <= wr_ptr + 1'b1;
                            count       <= count + 1'b1;
                            push_ok     <= 1'b1;
                        end
                        // Si count == 4: push rechazado (push_ok = 0)
                    end

                    default: begin
                        // Transferencias simultaneas en siguiente commit
                    end
                endcase
            end
        end
    end

endmodule
