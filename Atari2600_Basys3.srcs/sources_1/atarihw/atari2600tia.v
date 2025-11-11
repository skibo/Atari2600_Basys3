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

// atari2600tia.v - handle all functionality of the Atari TIA chip.

module atari2600tia(
                    // Cpu interface
                    output reg [7:0] data_out,
                    input [7:0]      data_in,
                    input [5:0]      addr,
                    input            we,
                    output reg       rdy,

                    // Video interface
                    output reg [3:0] color,
                    output reg [2:0] luma,
                    output reg       hsync,
                    output reg       vsync,

                    // I/O
                    input [5:0]      inpts,

                    input            slow_clock1,
                    input            slow_clock3,
                    input            clk,
                    input            reset
             );

    // Write registers.
    localparam [5:0]
                    VSYNC =     6'h00,
                    VBLANK =    6'h01,
                    WSYNC =     6'h02,
                    RSYNC =     6'h03,
                    NUSIZ0 =    6'h04,
                    NUSIZ1 =    6'h05,
                    COLUP0 =    6'h06,
                    COLUP1 =    6'h07,
                    COLUPF =    6'h08,
                    COLUBK =    6'h09,
                    CTRLPF =    6'h0a,
                    REFP0 =     6'h0b,
                    REFP1 =     6'h0c,
                    PF0 =       6'h0d,
                    PF1 =       6'h0e,
                    PF2 =       6'h0f,
                    RESP0 =     6'h10,
                    RESP1 =     6'h11,
                    RESM0 =     6'h12,
                    RESM1 =     6'h13,
                    RESBL =     6'h14,
                    AUDC0 =     6'h15,
                    AUDC1 =     6'h16,
                    AUDF0 =     6'h17,
                    AUDF1 =     6'h18,
                    AUDV0 =     6'h19,
                    AUDV1 =     6'h1a,
                    GRP0 =      6'h1b,
                    GRP1 =      6'h1c,
                    ENAM0 =     6'h1d,
                    ENAM1 =     6'h1e,
                    ENABL =     6'h1f,
                    HMP0 =      6'h20,
                    HMP1 =      6'h21,
                    HMM0 =      6'h22,
                    HMM1 =      6'h23,
                    HMBL =      6'h24,
                    VDELP0 =    6'h25,
                    VDELP1 =    6'h26,
                    VDELBL =    6'h27,
                    RESMP0 =    6'h28,
                    RESMP1 =    6'h29,
                    HMOVE =     6'h2a,
                    HMCLR =     6'h2b,
                    CXCLR =     6'h2c;

    // Read registers:
    localparam [3:0]
                    CXM0P =     4'h0,
                    CXM1P =     4'h1,
                    CXP0FB =    4'h2,
                    CXP1FB =    4'h3,
                    CXM0FB =    4'h4,
                    CXM1FB =    4'h5,
                    CXBLPF =    4'h6,
                    CXPPMM =    4'h7,
                    INPT0 =     4'h8,
                    INPT1 =     4'h9,
                    INPT2 =     4'ha,
                    INPT3 =     4'hb,
                    INPT4 =     4'hc,
                    INPT5 =     4'hd;

    // Register write timing.
    reg         we_p1;
    reg [5:0]   addr_1;
    reg [7:0]   data_in_1;

    always @(posedge clk)
        if (slow_clock1) begin
            we_p1 <= we;
            addr_1 <= addr;
            data_in_1 <= data_in;
        end
        else if (slow_clock3)
            we_p1 <= 0;

    wire we_1 = we_p1 && slow_clock3;

    ////////////////////////////////////////////////////
    // Horizontal Sync Counter
    ////////////////////////////////////////////////////

    // RSYNC register.  Delay until slow_clock1 to keep CPU in sync.
    reg         rsync_p;
    always @(posedge clk)
        if (we_1 && addr_1 == RSYNC)
            rsync_p <= 1;
        else if (slow_clock1)
            rsync_p <= 0;
    wire        rsync = rsync_p && slow_clock1;

    reg [7:0]   hsync_ctr;

    wire        shb = slow_clock3 && hsync_ctr == 8'd227;    // set HBLANK
    wire        shs = slow_clock3 && hsync_ctr == 8'd19;     // set HSYNC
    wire        rhs = slow_clock3 && hsync_ctr == 8'd35;     // reset HSYNC
    wire        rhb = slow_clock3 && hsync_ctr == 8'd67;     // reset HBLANK
    wire        lrhb = slow_clock3 && hsync_ctr == 8'd75;    // late rst HBLANK
    wire        hcent = slow_clock3 && hsync_ctr == 8'd147;  // center

    always @(posedge clk)
        if (reset || shb || rsync)
            hsync_ctr <= 8'd0;
        else if (slow_clock3)
            hsync_ctr <= hsync_ctr + 1'b1;

    wire        h01 = hsync_ctr[1:0] == 2'b10;
    wire        h02 = hsync_ctr[1:0] == 2'b00;

    reg         hsync_p;
    always @(posedge clk)
        if (reset || rhs || rsync)
            hsync_p <= 0;
        else if (shs)
            hsync_p <= 1;

    reg         sec;            // sec driven in horz motion counters section.
    reg         lateblank;      // extend hblank for HMOVE
    always @(posedge clk)
        if (sec)
            lateblank <= 1;
        else if (shb)
            lateblank <= 0;

    reg         hblank;
    always @(posedge clk)
        if (shb || rsync)
            hblank <= 1;
        else if (lateblank ? lrhb : rhb)
            hblank <= 0;

    reg         hhalf;
    always @(posedge clk)
        if (shb || rsync)
            hhalf <= 0;
        else if (hcent)
            hhalf <= 1;

    // WSYNC and RDY logic
    reg         shbx;           // shb extended
    always @(posedge clk)
        if (shb)
            shbx <= 1;
        else if (h02 && slow_clock3)
            shbx <= 0;

    always @(posedge clk)
        if (reset || shbx)
            rdy <= 1'b1;
        else if (we_1 && addr_1 == WSYNC)
            rdy <= 0;

    /////////////////////////////////////////////////////////////////////
    // Playfield
    /////////////////////////////////////////////////////////////////////

    // PF0-2 registers
    reg [3:0]   pf0;
    always @(posedge clk)
        if (we_1 && addr_1 == PF0)
            pf0 <= data_in_1[7:4];

    reg [7:0]   pf1;
    always @(posedge clk)
        if (we_1 && addr_1 == PF1)
            pf1 <= {data_in_1[0], data_in_1[1], data_in_1[2], data_in_1[3],
                    data_in_1[4], data_in_1[5], data_in_1[6], data_in_1[7]};

    reg [7:0]   pf2;
    always@(posedge clk)
        if (we_1 && addr_1 == PF2)
            pf2 <= data_in_1;

    // PFCTRL register
    reg         ctrlpf_ref;
    reg         ctrlpf_sc;
    reg         ctrlpf_pfp;
    reg [1:0]   ctrlpf_bsz;
    always @(posedge clk)
        if (we_1 && addr_1 == CTRLPF) begin
            ctrlpf_ref <= data_in_1[0];
            ctrlpf_sc <= data_in_1[1];
            ctrlpf_pfp <= data_in_1[2];
            ctrlpf_bsz <= data_in_1[5:4];
        end

    // Playfield serial register.
    reg [19:0] pf_sr;
    always @(posedge clk)
        if (rhb)
            pf_sr <= 20'd1;
        else if (hcent)
            pf_sr <= ctrlpf_ref ? 20'h80000 : 20'd1;
        else if (slow_clock3 && hsync_ctr[1:0] == 3'b11)
            pf_sr <= (ctrlpf_ref && hhalf) ?
                     {1'b0, pf_sr[19:1]} : {pf_sr[18:0], 1'b0};

    wire       bitpf = (pf_sr & {pf2,pf1,pf0}) != 20'd0;

    /////////////////////////////////////////////////////////////////////
    // Horizontal motion registers
    /////////////////////////////////////////////////////////////////////
    reg [3:0]  hmbl;
    reg [3:0]  hmm0;
    reg [3:0]  hmm1;
    reg [3:0]  hmp0;
    reg [3:0]  hmp1;
    wire       hmclr = we_1 && addr_1 == HMCLR;

    always @(posedge clk)
        if (reset || hmclr) begin
            hmbl <= 4'h8;
            hmm0 <= 4'h8;
            hmm1 <= 4'h8;
            hmp0 <= 4'h8;
            hmp1 <= 4'h8;
        end
        else if (we_1) begin
            if (addr_1 == HMBL)
                hmbl <= data_in_1[7:4] ^ 4'h8;
            if (addr_1 == HMM0)
                hmm0 <= data_in_1[7:4] ^ 4'h8;
            if (addr_1 == HMM1)
                hmm1 <= data_in_1[7:4] ^ 4'h8;
            if (addr_1 == HMP0)
                hmp0 <= data_in_1[7:4] ^ 4'h8;
            if (addr_1 == HMP1)
                hmp1 <= data_in_1[7:4] ^ 4'h8;
        end

    // HMOVE logic:
    wire        hmove = we_1 && addr_1 == HMOVE;

    // HMOVE --> SEC delay.  Mimicks gates which pass HMOVE strobe
    // through H01 and H02 phases to get SEC.
    reg         hmove_1;
    always @(posedge clk)
        if (reset || h01)
            hmove_1 <= 0;
        else if (hmove)
            hmove_1 <= 1;

    reg         hmove_2;
    always @(posedge clk)
        if (reset || h02)
            hmove_2 <= 0;
        else if ((hmove || hmove_1) && h01)
            hmove_2 <= 1;

    reg         hmove_3;
    always @(posedge clk)
        if (reset || h01)
            hmove_3 <= 0;
        else if (hmove_2 && h02)
            hmove_3 <= 1;

    always @(posedge clk)
        if (reset)
            sec <= 0;
        else if (h02)
            sec <= hmove_3;

    reg         sec_1;
    always @(posedge clk)
        if (slow_clock3 && sec)
            sec_1 <= 1;
        else if (slow_clock3 && h02)
            sec_1 <= 0;

    // HMOVE Counter.
    reg [3:0]   hmove_ctr;
    always @(posedge clk)
        if (reset)
            hmove_ctr <= 4'd0;
        else if (slow_clock3 && h02 && (sec_1 || hmove_ctr != 4'd0))
            hmove_ctr <= hmove_ctr + 1'b1;

    // Extra clock logic
    reg         blec_r;
    always @(posedge clk)
        if (reset || (hmove_ctr == hmbl && h02))
            blec_r <= 0;
        else if (sec_1 && h02)
            blec_r <= 1;
    wire        blec = slow_clock3 && h01 && blec_r;

    reg         m0ec_r;
    always @(posedge clk)
        if (reset || (hmove_ctr == hmm0 && h02))
            m0ec_r <= 0;
        else if (sec_1 && h02)
            m0ec_r <= 1;
    wire        m0ec = slow_clock3 && h01 && m0ec_r;

    reg         m1ec_r;
    always @(posedge clk)
        if (reset || (hmove_ctr == hmm1 && h02))
            m1ec_r <= 0;
        else if (sec_1 && h02)
            m1ec_r <= 1;
    wire        m1ec = slow_clock3 && h01 && m1ec_r;

    reg         p0ec_r;
    always @(posedge clk)
        if (reset || (hmove_ctr == hmp0 && h02))
            p0ec_r <= 0;
        else if (sec_1 && h02)
            p0ec_r <= 1;
    wire        p0ec = slow_clock3 && h01 && p0ec_r;

    reg         p1ec_r;
    always @(posedge clk)
        if (reset || (hmove_ctr == hmp1 && h02))
            p1ec_r <= 0;
        else if (sec_1 && h02)
            p1ec_r <= 1;
    wire        p1ec = slow_clock3 && h01 && p1ec_r;

    /////////////////////////////////////////////////////////////////////
    // Ball Logic
    /////////////////////////////////////////////////////////////////////

    // ENABL register
    reg         enabl_new;
    reg         enabl_old;
    always @(posedge clk)
        if (reset) begin
            enabl_new <= 0;
            enabl_old <= 0;
        end
        else if (we_1 && addr_1 == ENABL)
            enabl_new <= data_in_1[1];
        else if (we_1 && addr_1 == GRP1)
            enabl_old <= enabl_new;

    // VDELBL register
    reg         vdelbl;
    always @(posedge clk)
        if (reset)
            vdelbl <= 0;
        else if (we_1 && addr_1 == VDELBL)
            vdelbl <= data_in_1[0];

    wire        enabl = vdelbl ? enabl_old : enabl_new;

    wire        bitbl;
    wire        resbl = we_1 && addr_1 == RESBL;
    atari2600tiaball
        ball_0(.bitbl(bitbl),
               .resbl(resbl),
               .blec(blec),
               .ball_sz(ctrlpf_bsz),
               .enable(enabl),
               .hblank(hblank),
               .slow_clock3(slow_clock3),
               .clk(clk),
               .reset(reset)
            );

    /////////////////////////////////////////////////////////////////////
    // Missile logic
    /////////////////////////////////////////////////////////////////////

    // ENAM0 register
    reg         enam0;
    always @(posedge clk)
        if (reset)
            enam0 <= 0;
        else if (we_1 && addr_1 == ENAM0)
            enam0 <= data_in_1[1];

    // NUSIZ0 register
    reg [4:0]   nusiz0;
    always @(posedge clk)
        if (reset)
            nusiz0 <= 5'd0;
        else if (we_1 && addr_1 == NUSIZ0)
            nusiz0 <= {data_in_1[5:4], data_in_1[2:0]};

    // RESMP0 register
    reg         resmp0;
    always @(posedge clk)
        if (reset)
            resmp0 <= 0;
        else if (we_1 && addr_1 == RESMP0)
            resmp0 <= data_in_1[1];

    wire        bitm0;
    wire        pcent0;
    wire        resm0 = we_1 && addr_1 == RESM0;
    atari2600tiamis
        mis_0(.bitm(bitm0),
              .resm(resm0),
              .resmp(resmp0),
              .pcent(pcent0),
              .mec(m0ec),
              .nusiz(nusiz0),
              .enable(enam0),
              .hblank(hblank),
              .slow_clock3(slow_clock3),
              .clk(clk),
              .reset(reset)
           );

    // ENAM1 register
    reg         enam1;
    always @(posedge clk)
        if (reset)
            enam1 <= 0;
        else if (we_1 && addr_1 == ENAM1)
            enam1 <= data_in_1[1];

    // NUSIZ1 register
    reg [4:0]   nusiz1;
    always @(posedge clk)
        if (reset)
            nusiz1 <= 5'd0;
        else if (we_1 && addr_1 == NUSIZ1)
            nusiz1 <= {data_in_1[5:4], data_in_1[2:0]};

    // RESMP1 register
    reg         resmp1;
    always @(posedge clk)
        if (reset)
            resmp1 <= 0;
        else if (we_1 && addr_1 == RESMP1)
            resmp1 <= data_in_1[1];

    wire        bitm1;
    wire        pcent1;
    wire        resm1 = we_1 && addr_1 == RESM1;
    atari2600tiamis
        mis_1(.bitm(bitm1),
              .resm(resm1),
              .resmp(resmp1),
              .pcent(pcent1),
              .mec(m1ec),
              .nusiz(nusiz1),
              .enable(enam1),
              .hblank(hblank),
              .slow_clock3(slow_clock3),
              .clk(clk),
              .reset(reset)
           );

    /////////////////////////////////////////////////////////////////////
    // Player Logic
    /////////////////////////////////////////////////////////////////////

    // GRP0 register
    reg [7:0]   grp0_old;
    reg [7:0]   grp0_new;
    always @(posedge clk)
        if (reset) begin
            grp0_old <= 8'd0;
            grp0_new <= 8'd0;
        end
        else if (we_1 && addr_1 == GRP0)
            grp0_new <= data_in_1;
        else if (we_1 && addr_1 == GRP1)
            grp0_old <= grp0_new;

    // VDELP0 register
    reg         vdelp0;
    always @(posedge clk)
        if (reset)
            vdelp0 <= 0;
        else if (we_1 && addr_1 == VDELP0)
            vdelp0 <= data_in_1[0];

    wire [7:0]  grp0 = vdelp0 ? grp0_old : grp0_new;

    // REFP0 register
    reg         refp0;
    always @(posedge clk)
        if (reset)
            refp0 <= 0;
        else if (we_1 && addr_1 == REFP0)
            refp0 <= data_in_1[3];

    wire        bitp0;
    wire        resp0 = we_1 && addr_1 == RESP0;
    atari2600tiaplay
        play_0(.bitp(bitp0),
               .pcent(pcent0),
               .resp(resp0),
               .pec(p0ec),
               .nusiz(nusiz0),
               .grp(grp0),
               .refp(refp0),
               .hblank(hblank),
               .slow_clock3(slow_clock3),
               .clk(clk),
               .reset(reset)
            );

    // GRP1 register
    reg [7:0]   grp1_old;
    reg [7:0]   grp1_new;
    always @(posedge clk)
        if (reset) begin
            grp1_old <= 8'd0;
            grp1_new <= 8'd0;
        end
        else if (we_1 && addr_1 == GRP1)
            grp1_new <= data_in_1;
        else if (we_1 && addr_1 == GRP0)
            grp1_old <= grp1_new;

    // VDELP1 register
    reg         vdelp1;
    always @(posedge clk)
        if (reset)
            vdelp1 <= 0;
        else if (we_1 && addr_1 == VDELP1)
            vdelp1 <= data_in_1[0];

    wire [7:0]  grp1 = vdelp1 ? grp1_old : grp1_new;

    // REFP1 register
    reg         refp1;
    always @(posedge clk)
        if (reset)
            refp1 <= 0;
        else if (we_1 && addr_1 == REFP1)
            refp1 <= data_in_1[3];

    wire        bitp1;
    wire        resp1 = we_1 && addr_1 == RESP1;
    atari2600tiaplay
        play_1(.bitp(bitp1),
               .pcent(pcent1),
               .resp(resp1),
               .pec(p1ec),
               .nusiz(nusiz1),
               .grp(grp1),
               .refp(refp1),
               .hblank(hblank),
               .slow_clock3(slow_clock3),
               .clk(clk),
               .reset(reset)
            );

    /////////////////////////////////////////////////////////////////////
    // Video Logic
    /////////////////////////////////////////////////////////////////////

    // VSYNC
    always @(posedge clk)
        if (reset)
            vsync <= 0;
        else if (we_1 && addr_1 == VSYNC)
            vsync <= data_in_1[1];

    // VBLANK
    reg         vblank;
    reg         vblank_enl45;
    reg         vblank_di03;
    always @(posedge clk)
        if (reset) begin
            vblank <= 0;
            vblank_enl45 <= 0;
            vblank_di03 <= 0;
        end
        else if (we_1 && addr_1 == VBLANK) begin
            vblank <= data_in_1[1];
            vblank_enl45 <= data_in_1[6];
            vblank_di03 <= data_in_1[7];
        end

    // COLUxx registers;
    reg [6:0]   colup0;
    reg [6:0]   colup1;
    reg [6:0]   colupf;
    reg [6:0]   colubk;
    always @(posedge clk) begin
        if (we && slow_clock1 && addr == COLUP0)
            colup0 <= data_in[7:1];
        if (we && slow_clock1 && addr == COLUP1)
            colup1 <= data_in[7:1];
        if (we && slow_clock1 && addr == COLUPF)
            colupf <= data_in[7:1];
        if (we && slow_clock1 && addr == COLUBK)
            colubk <= data_in[7:1];
    end

    always @(posedge clk) begin
        if (slow_clock3) begin
            {color, luma} <= 7'd0;

            if (!hblank && !vblank) begin
                // Implement pixel priority
                {color, luma} <= colubk;

                if (bitpf || bitbl)
                    {color, luma} <= (ctrlpf_sc ? (hhalf ? colup1 : colup0) :
                                      colupf);

                if (bitm0 || bitp0)
                    {color, luma} <= colup0;
                if (bitm1 || bitp1)
                    {color, luma} <= colup1;

                if (ctrlpf_pfp && (bitpf || bitbl))
                    {color, luma} <= colupf;
            end

            hsync <= hsync_p;
        end // slow_clock3
    end // posedge clk

    /////////////////////////////////////////////////////////////////////
    // Collision Registers
    /////////////////////////////////////////////////////////////////////
    reg         cx_m0p1;
    reg         cx_m0p0;
    reg         cx_m1p0;
    reg         cx_m1p1;
    reg         cx_p0pf;
    reg         cx_p0bl;
    reg         cx_p1pf;
    reg         cx_p1bl;
    reg         cx_m0pf;
    reg         cx_m0bl;
    reg         cx_m1pf;
    reg         cx_m1bl;
    reg         cx_blpf;
    reg         cx_p0p1;
    reg         cx_m0m1;

    wire        cxclr = (we_1 && addr_1 == CXCLR); // CXCLR strobe

    always @(posedge clk)
        if (reset || cxclr) begin
            cx_m0p1 <= 0;
            cx_m0p0 <= 0;
            cx_m1p0 <= 0;
            cx_m1p1 <= 0;
            cx_p0pf <= 0;
            cx_p0bl <= 0;
            cx_p1pf <= 0;
            cx_p1bl <= 0;
            cx_m0pf <= 0;
            cx_m0bl <= 0;
            cx_m1pf <= 0;
            cx_m1bl <= 0;
            cx_blpf <= 0;
            cx_p0p1 <= 0;
            cx_m0m1 <= 0;
        end
        else if (!vblank) begin
            if (bitm0 && bitp1)
                cx_m0p1 <= 1;
            if (bitm0 && bitp0)
                cx_m0p0 <= 1;
            if (bitm1 && bitp0)
                cx_m1p0 <= 1;
            if (bitm1 && bitp1)
                cx_m1p1 <= 1;
            if (bitp0 && bitpf)
                cx_p0pf <= 1;
            if (bitp0 && bitbl)
                cx_p0bl <= 1;
            if (bitp1 && bitpf)
                cx_p1pf <= 1;
            if (bitp1 && bitbl)
                cx_p1bl <= 1;
            if (bitm0 && bitpf)
                cx_m0pf <= 1;
            if (bitm0 && bitbl)
                cx_m0bl <= 1;
            if (bitm1 && bitpf)
                cx_m1pf <= 1;
            if (bitm1 && bitbl)
                cx_m1bl <= 1;
            if (bitbl && bitpf)
                cx_blpf <= 1;
            if (bitp0 && bitp1)
                cx_p0p1 <= 1;
            if (bitm0 && bitm1)
                cx_m0m1 <= 1;
        end

    /////////////////////////////////////////////////////////////////////
    // Input I/O
    /////////////////////////////////////////////////////////////////////

    // I4 and I5 "latches"
    reg inpts_l4;
    reg inpts_l5;
    always @(posedge clk)
        if (reset || !vblank_enl45) begin
            inpts_l4 <= 1;
            inpts_l5 <= 1;
        end
    else if (vblank_enl45) begin
        if (!inpts[4])
            inpts_l4 <= 0;
        if (!inpts[5])
            inpts_l5 <= 0;
    end

    // data_out mux
    always @(*) begin
        case (addr[3:0])
            CXM0P:
                data_out = {cx_m0p1, cx_m0p0, 6'd0};
            CXM1P:
                data_out = {cx_m1p0, cx_m1p1, 6'd0};
            CXP0FB:
                data_out = {cx_p0pf, cx_p0bl, 6'd0};
            CXP1FB:
                data_out = {cx_p1pf, cx_p1bl, 6'd0};
            CXM0FB:
                data_out = {cx_m0pf, cx_m0bl, 6'd0};
            CXM1FB:
                data_out = {cx_m1pf, cx_m1bl, 6'd0};
            CXBLPF:
                data_out = {cx_blpf, 7'd0};
            CXPPMM:
                data_out = {cx_p0p1, cx_m0m1, 6'd0};
            INPT0:
                data_out = {inpts[0] && !vblank_di03, 7'd0};
            INPT1:
                data_out = {inpts[1] && !vblank_di03, 7'd0};
            INPT2:
                data_out = {inpts[2] && !vblank_di03, 7'd0};
            INPT3:
                data_out = {inpts[3] && !vblank_di03, 7'd0};
            INPT4:
                data_out = {inpts[4] && inpts_l4, 7'd0};
            INPT5:
                data_out = {inpts[5] && inpts_l5, 7'd0};
            default:
                data_out = 8'hXX;
        endcase
    end

endmodule // atari2600tia
