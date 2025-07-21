`timescale 1ns / 1ps

module LCD_top (
    input clk,
    input rst,
    output [7:0] LCD_DATA,
    output LCD_RS,
    output LCD_RW,
    output LCD_E
);

    LCD_controller #(
        .NUM_COMMANDS(5),
        .NUM_DATA_ALL(32),
        .NUM_DATA_PERLINE(16),
        .DATA_BITS(8),
        .COUNT_MAX(800_000)  // 16 ms con clk 50MHz
    ) lcd_controller (
        .clk(clk),
        .rst(rst),
        .data(LCD_DATA),
        .rs(LCD_RS),
        .rw(LCD_RW),
        .en(LCD_E)
    );

endmodule
