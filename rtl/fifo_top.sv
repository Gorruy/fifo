module fifo_top (
  input  logic        clk_i,
  input  logic        srst_i,

  input  logic [31:0] data_i,
  input  logic        wrreq_i,
  input  logic        rdreq_i,

  output logic [31:0] q_o,
  output logic [10:0] usedw_o,
  output logic        full_o,
  output logic        empty_o,
  output logic        almost_full_o,
  output logic        almost_empty_o
);

  logic [31:0] data;
  logic        wrreq;
  logic        rdreq;

  logic [31:0] q;
  logic [10:0] usedw;
  logic        full;
  logic        empty;
  logic        almost_full;
  logic        almost_empty;

  always_ff @( posedge clk_i )
    begin
      data  <= data_i;
      wrreq <= wrreq_i;
      rdreq <= rdreq_i;
    end 

  fifo #(
    .DWIDTH             ( 32                 ),
    .AWIDTH             ( 10                 ),
    .SHOWAHEAD          ( 1                  ),
    .ALMOST_FULL_VALUE  ( 14                 ),
    .ALMOST_EMPTY_VALUE ( 2                  ),
    .REGISTER_OUTPUT    ( 0                  )
  ) fifo_impl ( 
    .clk_i              ( clk_i              ),
    .srst_i             ( srst_i             ),
    .data_i             ( data               ),
    .wrreq_i            ( wrreq              ),
    .rdreq_i            ( rdreq              ),
    .q_o                ( q                  ),
    .usedw_o            ( usedw              ),
    .full_o             ( full               ),
    .empty_o            ( empty              ),
    .almost_full_o      ( almost_full        ),
    .almost_empty_o     ( almost_empty       )
  );

  always_ff @( posedge clk_i )
    begin
      q_o            <= q;
      usedw_o        <= usedw;
      full_o         <= full;
      empty_o        <= empty;
      almost_full_o  <= almost_full;
      almost_empty_o <= almost_empty; 
    end


endmodule