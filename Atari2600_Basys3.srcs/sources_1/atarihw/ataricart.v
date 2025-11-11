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

module ataricart(
                 output reg [7:0] data_out,
                 input [11:0]     addr,
                 input            strobe,
                 input            clk,
                 input            reset
         );

    parameter   ROM_FILE = "cart.mem";
    parameter   NBANKS = 2;

    localparam  BANK0_ADDR = 12'hffa - NBANKS,
                BANK1_ADDR = 12'hffb - NBANKS,
                BANK2_ADDR = 12'hffc - NBANKS,
                BANK3_ADDR = 12'hffd - NBANKS;

    // Implement F16 banking.
    reg [1:0]   bank;

    if (NBANKS == 1) begin
        initial bank = 2'b00;
    end
    else if (NBANKS == 2) begin
        always @(posedge clk)
            if (reset)
                bank <= 2'b00;
            else if (strobe &&addr == BANK0_ADDR)
                bank <= 2'b00;
            else if (strobe && addr == BANK1_ADDR)
                bank <= 2'b01;
    end
    else if (NBANKS == 4) begin
    end

    (* ram_style = "block" *)
    reg [7 : 0] rom[16383 : 0];

    initial $readmemh(ROM_FILE, rom);

    always @(posedge clk)
        data_out <= rom[{bank, addr}];

endmodule // pet2001roms
