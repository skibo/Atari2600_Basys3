`timescale 1ns / 1ps
//
// Copyright (c) 2025 Thomas Skibo.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.
//

// atari2600hw encapsulates everything except the CPU

module atari2600hw #(parameter CLKDIV = 14)
    (
     input [12:0]     addr,             // CPU Interface
     input [7:0]      data_in,
     output reg [7:0] data_out,
     input            we,
     output reg       rdy,
     output           nmi,
     output           irq,

     output reg [3:0] vga_r,            // VGA video
     output reg [3:0] vga_g,
     output reg [3:0] vga_b,
     output reg       vga_hsync,
     output reg       vga_vsync,

     input            start,
     input            select,
     input            expert_l,
     input            expert_r,
     input            selcolor,

     input [3:0]      joy_l,            // R L D U
     input            joy_l_trig,
     input            padd_l_a,
     input            padd_l_b,

     input [3:0]      joy_r,
     input            joy_r_trig,
     input            padd_r_a,
     input            padd_r_b,

     input            clk,
     input            reset
     );

    // Unused in Atari 2600:
    assign   nmi = 0;
    assign   irq = 0;

    ////////////////////////////////////////////////////////////////
    // Create a 3.58 Mhz "slow clock3" (actually it's a pulse).  This
    // will run the TIA and be divided by 3 to pace the CPU and RIOT Timer
    // at close to original speed.
    ///////////////////////////////////////////////////////////////
    reg [6:0]   clkdiv;
    reg         slow_clock3;

    always @(posedge clk)
        if (reset || clkdiv == 7'd0)
            clkdiv <= CLKDIV - 1;
        else
            clkdiv <= clkdiv - 1'b1;

    wire        slow_clock3_p = clkdiv == 7'd1;
    always @(posedge clk)
        if (reset)
            slow_clock3 <= 1'b0;
        else
            slow_clock3 <= slow_clock3_p;

    reg [1:0]   div3_cnt;
    always @(posedge clk)
        if (reset)
            div3_cnt <= 2'b00;
        else if (slow_clock3 && div3_cnt[1])
            div3_cnt <= 2'b00;
        else if (slow_clock3)
            div3_cnt <= div3_cnt + 1'b1;

    // Create 1.19 Mhz "slow_clock1" (actually it's a pulse).  This
    // paces the CPU and RIOT.
    wire        slow_clock1_p = slow_clock3_p && div3_cnt[1];
    reg         slow_clock1;
    always @(posedge clk)
        if (reset)
            slow_clock1 <= 0;
        else
            slow_clock1 <= slow_clock1_p;

    // Generate 6502 RDY signal.  This paces the CPU at 1.19 Mhz.
    wire        tia_rdy;
    always @(posedge clk)
        if (reset)
            rdy <= 0;
        else
            rdy <= slow_clock1_p && tia_rdy;

    /////////////////////////////////////
    // Catridge
    /////////////////////////////////////
    wire [7:0]  cart_data;
    wire        cart_strobe = rdy && addr[12];

    ataricart cart0(.data_out(cart_data),
                    .addr(addr[11:0]),
                    .strobe(cart_strobe),
                    .clk(clk),
                    .reset(reset)
                 );

    /////////////////////////////////////
    // TIA
    /////////////////////////////////////
    wire [7:0]  tia_read_data;
    wire        tia_wr_strobe = rdy && we && !addr[12] && !addr[7];
    wire [3:0]  tia_color;
    wire [2:0]  tia_luma;
    wire        tia_hsync;
    wire        tia_vsync;

    atari2600tia
        tia0(.data_out(tia_read_data),
             .data_in(data_in),
             .addr(addr[5:0]),
             .we(tia_wr_strobe),
             .rdy(tia_rdy),

             .color(tia_color),
             .luma(tia_luma),
             .hsync(tia_hsync),
             .vsync(tia_vsync),

             .inpts({joy_r_trig, joy_l_trig, padd_r_a, padd_r_b,
                     padd_l_a, padd_l_b}),

             .slow_clock1(slow_clock1),
             .slow_clock3(slow_clock3),
             .clk(clk),
             .reset(reset)
          );

    /////////////////////////////////////
    // RIOT (includes RAM)
    /////////////////////////////////////
    wire [7:0]  riot_read_data;
    wire        riot_strobe = rdy && !addr[12] && addr[7];
    wire        riot_wr_strobe = riot_strobe && we;

    riot6532
        riot0(.data_out(riot_read_data),
              .data_in(data_in),
              .addr(addr[6:0]),
              .rs_(addr[9]),
              .strobe(riot_strobe),
              .we(riot_wr_strobe),

              .portb_in({expert_r, expert_l, 2'b11, selcolor, 1'b1,
                         select, start}),
              .portb_out(),
              .porta_in({joy_l, joy_r}),
              .porta_out(),

              .slow_clock(slow_clock1),
              .clk(clk),
              .reset(reset)
           );

    /////////////////////////////////////
    // Read data mux (to CPU)
    /////////////////////////////////////
    always @(*)
        if (addr[12])
            data_out = cart_data;
        else if (addr[7])
            data_out = riot_read_data;
        else
            data_out = tia_read_data;

    /////////////////////////////////////
    // Video mock-up
    /////////////////////////////////////
    reg [11:0]  colortab[127 : 0];

    initial $readmemh("colortab.mem", colortab);

    always @(posedge clk)
        {vga_r, vga_g, vga_b} <= colortab[{tia_color, tia_luma}];

    always @(posedge clk) begin
        vga_hsync <= ~tia_hsync;
        vga_vsync <= ~tia_vsync;
    end

endmodule // atarihw
