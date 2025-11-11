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

// riot6532.v

module riot6532(
                // Cpu interface
                output reg [7:0] data_out,
                input [7:0]      data_in,
                input [6:0]      addr,
                input            rs_,
                input            strobe,
                input            we,

                output reg [7:0] porta_out,
                input [7:0]      porta_in,
                output reg [7:0] portb_out,
                input [7:0]      portb_in,

                input            slow_clock,
                input            clk,
                input            reset
             );

    localparam [1:0]
                    PORTA =     2'h0,
                    DDRA =      2'h1,
                    PORTB =     2'h2,
                    DDRB =      2'h3;

    //////////////////////// I/O /////////////////////////

    reg [7:0]   ddra;
    reg [7:0]   ddrb;
    always @(posedge clk) begin
        if (reset) begin
            ddra <= 8'h00;
            ddrb <= 8'h00;
            porta_out <= 8'h00;
            portb_out <= 8'h00;
        end
        else if (we && rs_ && !addr[2]) begin
            case (addr[1:0])
                PORTA:
                    porta_out <= data_in;
                PORTB:
                    portb_out <= data_in;
                DDRA:
                    ddra <= data_in;
                DDRB:
                    ddrb <= data_in;
            endcase
        end
    end

    wire [7:0]  porta_read = (porta_in & ~ddra) | (porta_out & ddra);
    wire [7:0]  portb_read = (portb_in & ~ddrb) | (portb_out & ddrb);

    //////////// Timer /////////////////////////

    function [9:0] intvlinit(input [1:0] a10);
        begin
            case (a10)
                2'b00:
                    intvlinit = 10'd1;
                2'b01:
                    intvlinit = 10'd8;
                2'b10:
                    intvlinit = 10'd64;
                2'b11:
                    intvlinit = 10'd0;
            endcase
        end
    endfunction

    reg [7:0]   intim;
    reg         tim_flag;
    reg [1:0]   timintvl;  // 1, 8, 64, 1024
    reg [9:0]   intvlcnt;

    wire        intim_rd_strobe = strobe && rs_ && addr[2] && !addr[0];
    wire        intim_wr_strobe = strobe && rs_ && we &&
                addr[4] && addr[2];
    wire        intim_tick = slow_clock && (intvlcnt == 10'd1 ||
                                            (tim_flag && !intim_rd_strobe));
    wire        intim_fire = intim_tick && intim == 8'h00;

    // Interval timer
    always @(posedge clk)
        if (reset)
            intvlcnt <= 10'd1;
        else if (intim_wr_strobe)
            intvlcnt <= intvlinit(addr[1:0]);
        else if (intim_tick)
            intvlcnt <= intvlinit(timintvl);
        else if (slow_clock)
            intvlcnt <= intvlcnt - 1'b1;

    // INTIM
    always @(posedge clk)
        if (reset)
            intim <= 8'h00;
        else if (intim_wr_strobe)
            intim <= data_in - 1'b1;
        else if (intim_tick)
            intim <= intim - 1'b1;

    // Register the interval size from address.
    always @(posedge clk)
        if (reset)
            timintvl <= 2'b11;
        else if (intim_wr_strobe)
            timintvl <= addr[1:0];

    // Timer flag
    always @(posedge clk)
        if (reset || intim_rd_strobe || intim_wr_strobe)
            tim_flag <= 0;
        else if (intim_fire)
            tim_flag <= 1;

    // PA7 flag XXX: unimplemented
    reg         pa7_flag;
    initial pa7_flag = 1'b0;

    //////////// 128 bytes RAM /////////////////

    reg [7:0]   ram_data_out;

    reg [7:0]   ram[127 : 0];

    always @(posedge clk)
        if (we && !rs_)
            ram[addr] <= data_in;

    always @(posedge clk)
        ram_data_out <= ram[addr];

    /////////// Read Mux ///////////////////////
    always @(*)
        if (!rs_)
            data_out = ram_data_out;
        else begin
            if (addr[2]) begin
                if (addr[0])
                    data_out = {tim_flag, pa7_flag, 6'd0}; // INSTAT
                else
                    data_out = intim;   // INTIM
            end
            else begin // !addr[2]
                case (addr[1:0])
                    PORTA:
                        data_out = porta_read;
                    PORTB:
                        data_out = portb_read;
                    DDRA:
                        data_out = ddra;
                    DDRB:
                        data_out = ddrb;
                    default:
                        data_out = 8'hXX;
                endcase
            end
        end

endmodule // riot6532
