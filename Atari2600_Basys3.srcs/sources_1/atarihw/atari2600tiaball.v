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

// atari2600tiaball.v

// horizontal position counter and other logic for ball.

module atari2600tiaball(
                        output reg  bitbl,
                        input       resbl,
                        input       blec,
                        input [1:0] ball_sz,
                        input       enable,
                        input       hblank,
                        input       slow_clock3,
                        input       clk,
                        input       reset
                    );

    reg [7:0]   ctr;
    wire        bl_clk = blec || (slow_clock3 && !hblank);
    wire        ctr_end = bl_clk && ctr == 8'd159;
    wire        bl_start = bl_clk && enable && ctr == 8'd1;

    // Stretch RESBL by a pixel clock.
    reg         resbl_1;
    always @(posedge clk)
        if (slow_clock3)
            resbl_1 <= resbl;

    // horizontal position counter
    always @(posedge clk)
        if (reset || resbl || resbl_1 || ctr_end)
            ctr <= 8'h00;
        else if (bl_clk)
            ctr <= ctr + 1'b1;

    // counter to stretch ball to size.
    reg [2:0]   blctr;
    always @(posedge clk)
        if (reset)
            blctr <= 3'd0;
        else if (bl_start)
            blctr <= 3'b111;
        else if (bl_clk && blctr != 3'd0)
            blctr <= blctr - 1'b1;

    always @(posedge clk)
        if (bl_clk)
            bitbl <= bl_start || (blctr > (3'b111 << ball_sz));

endmodule // atari2600tiaball
