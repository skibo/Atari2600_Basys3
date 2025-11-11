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

module test_Atari2600_Basys3;

    reg [7:0]   SW;
    wire [3:0]  VGA_R;
    wire [3:0]  VGA_G;
    wire [3:0]  VGA_B;
    wire        VGA_HSYNC;
    wire        VGA_VSYNC;
    reg         PS2_CLK;
    reg         PS2_DATA;
    reg         CLK;


    initial begin
        SW = 8'd0;
        PS2_CLK = 1;
        PS2_DATA = 1;
        CLK = 0;
    end

    always #5.0 CLK = ~CLK;

    Atari2600_Basys3
        Atari2600_Basys3_0(
                           .SW(SW),
                           .VGA_R(VGA_R),
                           .VGA_G(VGA_G),
                           .VGA_B(VGA_B),
                           .VGA_HSYNC(VGA_HSYNC),
                           .VGA_VSYNC(VGA_VSYNC),
                           .PS2_CLK(PS2_CLK),
                           .PS2_DATA(PS2_DATA),
                           .CLK(CLK)
                   );

endmodule // test_Atari2600_Basys3
