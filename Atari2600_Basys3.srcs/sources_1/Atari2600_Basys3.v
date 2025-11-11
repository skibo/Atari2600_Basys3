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

module Atari2600_Basys3(
                        input [2:0]  SW,

                        output [3:0] VGA_R,
                        output [3:0] VGA_G,
                        output [3:0] VGA_B,
                        output       VGA_HSYNC,
                        output       VGA_VSYNC,

                        input        PS2_CLK,
                        input        PS2_DATA,

                        input        CLK
        );

    ////////////////////////////// Clock and Reset /////////////////////////
    //
    wire                clkout0;
    wire                clk;
    wire                clkfbout, clkfbin;
    wire                mmcm_locked;
    reg                 reset_p1;
    reg                 reset;

    MMCME2_BASE #(.CLKIN1_PERIOD(10.0),
                  .CLKFBOUT_MULT_F(10.0),
                  .CLKOUT0_DIVIDE_F(20.0))
       mmcm0(.CLKIN1(CLK),
             .CLKFBIN(clkfbin),
             .PWRDWN(1'b0),
             .RST(1'b0),
             .CLKOUT0(clkout0),
             .CLKOUT0B(),
             .CLKOUT1(),
             .CLKOUT1B(),
             .CLKOUT2(),
             .CLKOUT2B(),
             .CLKOUT3(),
             .CLKOUT3B(),
             .CLKOUT4(),
             .CLKOUT5(),
             .CLKOUT6(),
             .CLKFBOUT(clkfbout),
             .CLKFBOUTB(),
             .LOCKED(mmcm_locked)
       );

    // Output clock buffers.
    BUFG clk0_buf (.I(clkout0), .O(clk));
    BUFG clkfb_buf (.I(clkfbout), .O(clkfbin));

    // Create a synchronized reset.
    initial begin
        reset_p1 = 1;
        reset = 1;
    end
    always @(posedge clk) begin
        reset_p1 <= (/* BTN[3] || */ ~mmcm_locked);
        reset <= reset_p1;
    end

    /////////////////////////////////////////////////////////////////////

    // Synchronize inputs
    reg [2:0]   sw_1;
    reg [2:0]   sw_2;
    reg         ps2_clk_1, ps2_clk_2;
    reg         ps2_data_1, ps2_data_2;
    always @(posedge clk) begin
        sw_1 <= SW;
        sw_2 <= sw_1;
        ps2_clk_1 <= PS2_CLK;
        ps2_clk_2 <= ps2_clk_1;
        ps2_data_1 <= PS2_DATA;
        ps2_data_2 <= ps2_data_1;
    end

    wire [3:0]  joy_l;
    wire        joy_l_trig;
    wire [3:0]  joy_r;
    wire        joy_r_trig;
    wire        start;
    wire        select;

    atari2600_top
        atari_top(
                  .vga_r(VGA_R),
                  .vga_g(VGA_G),
                  .vga_b(VGA_B),
                  .vga_hsync(VGA_HSYNC),
                  .vga_vsync(VGA_VSYNC),

                  .start(start),
                  .select(select),
                  .expert_l(sw_2[0] ),
                  .expert_r(sw_2[1]),
                  .selcolor(~sw_2[2]),

                  .joy_l(joy_l),
                  .joy_l_trig(joy_l_trig),
                  .padd_l_a(1'b1),
                  .padd_l_b(1'b1),

                  .joy_r(joy_r),
                  .joy_r_trig(joy_r_trig),
                  .padd_r_a(1'b1),
                  .padd_r_b(1'b1),

                  .clk(clk),
                  .reset(reset)
        );

    atari2600ps2
        atari2600ps2_0(.joy_l(joy_l),
                       .joy_l_trig(joy_l_trig),
                       .joy_r(joy_r),
                       .joy_r_trig(joy_r_trig),

                       .start(start),
                       .select(select),

                       .ps2_clk(ps2_clk_2),
                       .ps2_data(ps2_data_2),

                       .clk(clk),
                       .reset(reset)
        );

endmodule // Atari2600_Basys3
