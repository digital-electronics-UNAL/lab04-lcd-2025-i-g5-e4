`timescale 1ns / 1ps

module LCD_controller #(
    parameter NUM_COMMANDS = 5,
    parameter NUM_DATA_ALL = 32,
    parameter NUM_DATA_PERLINE = 16,
    parameter DATA_BITS = 8,
    parameter COUNT_MAX = 800_000  // Para generar pulso de 16ms con clk 50MHz
)(
    input clk,
    input rst,
    output reg [DATA_BITS-1:0] data,
    output reg rs,
    output reg rw,
    output reg en
);

    // Comandos de inicialización
    reg [DATA_BITS-1:0] commands[0:NUM_COMMANDS-1];
    initial begin
        commands[0] = 8'h38; // Function set
        commands[1] = 8'h0C; // Display ON
        commands[2] = 8'h01; // Clear display
        commands[3] = 8'h06; // Entry mode set
        commands[4] = 8'h80; // Set DDRAM address to 0
    end

    // Texto dinámico
    reg [8*NUM_DATA_PERLINE-1:0] dynamic_text_line1;
    reg [8*NUM_DATA_PERLINE-1:0] dynamic_text_line2;

    // Contador de reloj para pulso de 16ms
    reg [31:0] count;
    reg clk_16ms;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            clk_16ms <= 0;
        end else begin
            if (count >= COUNT_MAX) begin
                count <= 0;
                clk_16ms <= 1;
            end else begin
                count <= count + 1;
                clk_16ms <= 0;
            end
        end
    end

    // FSM
    reg [7:0] state;
    reg [7:0] cmd_index;
    reg [7:0] data_index;

    // Conteo y color
    reg [9:0] contador;
    reg [1:0] color_state;

    // Contador de 3 segundos (con 16ms por tick, se necesitan ~187.5 ticks)
    reg [7:0] update_ticks;

    // Variables de iteración
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            cmd_index <= 0;
            data_index <= 0;
            contador <= 0;
            color_state <= 0;
            update_ticks <= 0;
        end else if (clk_16ms) begin
            case (state)
                // Inicialización
                0: begin
                    rs <= 0;
                    rw <= 0;
                    en <= 1;
                    data <= commands[cmd_index];
                    state <= 1;
                end
                1: begin
                    en <= 0;
                    cmd_index <= cmd_index + 1;
                    if (cmd_index == NUM_COMMANDS-1) begin
                        data_index <= 0;
                        state <= 2;
                    end else begin
                        state <= 0;
                    end
                end

                // Escritura línea 1 (Conteo)
                2: begin
                    rs <= 0; rw <= 0; en <= 1; data <= 8'h80; state <= 3;
                end
                3: begin
                    en <= 0; state <= 4;
                end
                4: begin
                    if (data_index < NUM_DATA_PERLINE) begin
                        rs <= 1;
                        rw <= 0;
                        en <= 1;
                        data <= dynamic_text_line1[data_index*8 +: 8];
                        state <= 5;
                    end else begin
                        data_index <= 0;
                        state <= 6;
                    end
                end
                5: begin
                    en <= 0;
                    data_index <= data_index + 1;
                    state <= 4;
                end

                // Escritura línea 2 (Color)
                6: begin
                    rs <= 0; rw <= 0; en <= 1; data <= 8'hC0; state <= 7;
                end
                7: begin
                    en <= 0; state <= 8;
                end
                8: begin
                    if (data_index < NUM_DATA_PERLINE) begin
                        rs <= 1;
                        rw <= 0;
                        en <= 1;
                        data <= dynamic_text_line2[data_index*8 +: 8];
                        state <= 9;
                    end else begin
                        data_index <= 0;
                        state <= 10;
                    end
                end
                9: begin
                    en <= 0;
                    data_index <= data_index + 1;
                    state <= 8;
                end

                // Esperar 3 segundos
                10: begin
                    update_ticks <= update_ticks + 1;
                    if (update_ticks >= 188) begin
                        update_ticks <= 0;
                        // Actualizar contador
                        contador <= contador + 1;
                        if (contador >= 999)
                            contador <= 0;

                        // Actualizar color
                        color_state <= color_state + 1;
                        if (color_state >= 2)
                            color_state <= 0;

                        // Actualizar texto dinámico
                        for (i = 0; i < NUM_DATA_PERLINE; i = i + 1)
                            dynamic_text_line1[i*8 +: 8] <= " ";
                        for (i = 0; i < NUM_DATA_PERLINE; i = i + 1)
                            dynamic_text_line2[i*8 +: 8] <= " ";

                        dynamic_text_line1[0 +: 8*8] <= " :oetnoC";
                        dynamic_text_line1[8*8 +: 8] <= (contador / 100) + 8'd48;
                        dynamic_text_line1[9*8 +: 8] <= (contador / 10) + 8'd48;
                        dynamic_text_line1[10*8 +: 8] <= (contador % 10) + 8'd48;

                        dynamic_text_line2[0 +: 8*7] <= " :roloC";

                        case (color_state)
                            0: dynamic_text_line2[8*7 +: 8*5] <= " ojoR";
                            1: dynamic_text_line2[8*7 +: 8*6] <= " edreV";
                            2: dynamic_text_line2[8*7 +: 8*4] <= " luzA";
                        endcase

                        state <= 2; // volver a escribir
                    end
                end
            endcase
        end
    end
endmodule
