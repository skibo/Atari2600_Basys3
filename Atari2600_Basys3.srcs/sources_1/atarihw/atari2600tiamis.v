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

// atari2600tiamis.v

// horizontal position counter and other logic for missiles.

module atari2600tiamis(
                        output reg  bitm,
                        input       resm,
                        input       resmp,
                        input       pcent,
                        input       mec,
                        input [4:0] nusiz,
                        input       enable,
                        input       hblank,
                        input       slow_clock3,
                        input       clk,
                        input       reset
                    );

    reg [7:0]   ctr;
    wire        mis_clk = mec || (slow_clock3 && !hblank);
    wire        ctr_end = mis_clk && ctr == 8'd159;
    wire        nbig = !(nusiz[2] && nusiz[0]);  // not big players
    wire        mis2_nxt = mis_clk && ctr == 8'd15 && nbig && nusiz[0];
    wire        mis3_nxt = mis_clk && ctr == 8'd31 && nbig && nusiz[1];
    wire        mis4_nxt = mis_clk && ctr == 8'd63 && nbig && nusiz[2];

    // Stretch RESM by a pixel clock.
    reg         resm_1;
    always @(posedge clk)
        if (slow_clock3)
            resm_1 <= resm;

    // horizontal position counter
    always @(posedge clk)
        if (reset || resm || resm_1 || (resmp && pcent) ||  ctr_end)
            ctr <= 8'h00;
        else if (mis_clk)
            ctr <= ctr + 1'b1;

    reg         mis_start_p;
    reg         mis_start;
    always @(posedge clk)
        if (reset) begin
            mis_start_p <= 0;
            mis_start <= 0;
        end
        else if (mis_clk) begin
            mis_start_p <= (ctr_end || mis2_nxt || mis3_nxt || mis4_nxt);
            mis_start <= mis_start_p && enable && !resmp;
        end

    // counter to stretch missile to size.
    reg [2:0]   mictr;
    always @(posedge clk)
        if (reset)
            mictr <= 3'd0;
        else if (mis_start)
            mictr <= 3'b111;
        else if (mis_clk && mictr != 3'd0)
            mictr <= mictr - 1'b1;

    always @(posedge clk)
        if (mis_clk)
            bitm <= mis_start || (mictr > (3'b111 << nusiz[4:3]));

endmodule // atari2600tiamis
