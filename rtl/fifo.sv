module fifo #(
  parameter DWIDTH             = 32,
  parameter AWIDTH             = 4,
  parameter SHOWAHEAD          = 1,
  parameter ALMOST_FULL_VALUE  = 20,
  parameter ALMOST_EMPTY_VALUE = 20,
  parameter REGISTER_OUTPUT    = 0
) (
  input  logic                clk_i,
  input  logic                srst_i,
  
  input  logic [DWIDTH - 1:0] data_i,
  input  logic                wrreq_i,
  input  logic                rdreq_i,

  output logic [DWIDTH - 1:0] q_o,
  output logic                empty_o,
  output logic                full_o,
  output logic [AWIDTH:0]     usedw_o,
  output logic                almost_full_o,
  output logic                almost_empty_o
);

  logic [AWIDTH - 1:0] rd_ptr;
  logic [AWIDTH - 1:0] wr_ptr;
  logic [DWIDTH - 1:0] mem [2**AWIDTH - 1:0];

  assign almost_empty_o = ( usedw_o == ALMOST_EMPTY_VALUE );
  assign almost_full_o  = ( usedw_o == ALMOST_FULL_VALUE );
  assign empty_o        = ( usedw_o == '0 );
  assign full_o         = ( usedw_o == AWIDTH**2 );

  always_ff @( posedge clk_i )
    begin
      if ( srst_i )
        rd_ptr <= '0;
      else if ( wrreq_i && !full_o )
        rd_ptr <= rd_ptr + (AWIDTH)'(1);
    end
  
  always_ff @( posedge clk_i )
    begin
      if ( srst_i )
        wr_ptr <= '0;
      else if ( rdreq_i && !empty_o )
        wr_ptr <= wr_ptr + (AWIDTH)'(1);
    end

  always_ff @( posedge clk_i )
    begin
      if ( srst_i )
        usedw_o <= '0;
      else 
        begin
          if ( wrreq_i && !full_o )
            usedw_o <= usedw_o + (AWIDTH + 1)'(1);
          if ( rdreq_i && !empty_o )
            usedw_o <= usedw_o + (AWIDTH + 1)'(1);
        end
    end

  always_ff @( posedge clk_i )
    begin
      if ( wrreq_i )
        mem[rd_ptr] <= data_i;
    end

  always_ff @( posedge clk_i )
    begin
      if ( rdreq_i )
        q_o <= mem[wr_ptr];
    end

  
endmodule