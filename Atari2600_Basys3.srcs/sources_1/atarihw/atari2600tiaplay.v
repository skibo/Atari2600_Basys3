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

// atari2600tiaplay.v

// horizontal position counter and other logic for players.

module atari2600tiaplay(
                        output reg  bitp,
                        output      pcent,
                        input       resp,
                        input       pec,
                        input [4:0] nusiz,
                        input [7:0] grp,
                        input       refp,
                        input       hblank,
                        input       slow_clock3,
                        input       clk,
                        input       reset
                    );

    reg [7:0]   ctr;
    wire        pl_clk = pec || (slow_clock3 && !hblank);
    wire        ctr_end = pl_clk && ctr == 8'd159;
    wire        nbig = !(nusiz[2] && nusiz[0]);  // not big players
    wire        pl2_nxt = pl_clk && ctr == 8'd15 && nbig && nusiz[0];
    wire        pl3_nxt = pl_clk && ctr == 8'd31 && nbig && nusiz[1];
    wire        pl4_nxt = pl_clk && ctr == 8'd63 && nbig && nusiz[2];

    // Stretch RESP by a pixel clock.
    reg         resp_1;
    always @(posedge clk)
        if (slow_clock3)
            resp_1 <= resp;

    // horizontal position counter
    always @(posedge clk)
        if (reset || resp || resp_1 || ctr_end)
            ctr <= 8'h00;
        else if (pl_clk)
            ctr <= ctr + 1'b1;

    // delay starting player
    reg [2:0]   pl_start_dly;
    always @(posedge clk)
        if (pl_clk)
            pl_start_dly <= {(ctr_end || pl2_nxt || pl3_nxt || pl4_nxt),
                             pl_start_dly[2:1]};
    wire        pl_start = nbig ? pl_start_dly[1] : pl_start_dly[0];

    wire        pl_stop;
    reg         pl_active;
    always @(posedge clk)
        if (pl_start && pl_clk)
            pl_active <= 1;
        else if (pl_stop)
            pl_active <= 0;

    wire        inc = nbig || (!nusiz[1] && !ctr[0]) || ctr[1:0] == 2'b10;

    // Graphics scan counter
    reg [2:0]   gctr;
    always @(posedge clk)
        if (pl_start && pl_clk)
            gctr <= 3'd0;
        else if (inc && pl_clk)
            gctr <= gctr + 1'b1;

    assign pl_stop = pl_clk && inc && gctr == 3'd7;

    always @(posedge clk)
        if (pl_clk)
            bitp <= pl_active && grp[refp ? gctr : ~gctr];

    // Gererate pcent, player center for reset missile-to-player.
    reg         pl_first;
    always @(posedge clk)
        if (ctr_end)
            pl_first <= 1;
        else if (pl_stop && pl_active)
            pl_first <= 0;

    reg         pcent_p;
    always @(posedge clk)
        if (pl_clk)
            pcent_p <= inc && pl_first && gctr == 3'b001;

    assign pcent = pl_clk && pcent_p;

endmodule // atari2600tiaplay
