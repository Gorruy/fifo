module top_tb;

  parameter DWIDTH             = 32;
  parameter AWIDTH             = 32;
  parameter SHOWAHEAD          = 1;
  parameter ALMOST_FULL_VALUE  = 20;
  parameter ALMOST_EMPTY_VALUE = 20;
  parameter REGISTER_OUTPUT    = 0;
  
  bit                  clk;
  logic                srst;

  logic [DWIDTH - 1:0] data_ref;
  logic                wrreq;
  logic                rdreq;
  logic                aclr;
  logic                sclr;

  logic [DWIDTH - 1:0] q_ref;
  logic [AWIDTH - 1:0] usedw_ref;
  logic                full_ref;
  logic                empty_ref;
  logic                almost_full_ref;
  logic                almost_empty_ref;
  logic [1:0]          eccstatus;

  logic [DWIDTH - 1:0] data;
  logic [DWIDTH - 1:0] q;
  logic [AWIDTH - 1:0] usedw;
  logic                full;
  logic                empty;
  logic                almost_full;
  logic                almost_empty;

scfifo #(
  .lpm_width               ( DWIDTH                ),
  .lpm_widthu              ( AWIDTH                ),
  .lpm_numwords            ( 2 ** AWIDTH           ),
  .lpm_showahead           ( "ON"                  ),
  .lpm_type                ( "scfifo"              ),
  .lpm_hint                ( "RAM_BLOCK_TYPE=M10K" ),
  .intended_device_family  ( "Cyclone V"           ),
  .underflow_checking      ( "ON"                  ),
  .overflow_checking       ( "ON"                  ),
  .allow_rwcycle_when_full ( "OFF"                 ),
  .use_eab                 ( "ON"                  ),
  .add_ram_output_register ( "OFF"                 ),
  .almost_full_value       ( ALMOST_FULL_VALUE     ),
  .almost_empty_value      ( ALMOST_EMPTY_VALUE    ),
  .maximum_depth           ( 0                     ),
  .enable_ecc              ( "FALSE"               )
) fifo_ref ( 
// INPUT PORT DECLARATION
  .data                 ( data_ref                 ),
  .clock                ( clk                      ),
  .wrreq                ( wrreq                    ),
  .rdreq                ( rdreq                    ),
  .aclr                 ( aclr                     ),
  .sclr                 ( sclr                     ),

// OUTPUT PORT DECLARATION
  .q                    ( q_ref                   ),
  .usedw                ( usedw_ref               ),
  .full                 ( full_ref                ),
  .empty                ( empty_ref               ),
  .almost_full          ( almost_full_ref         ),
  .almost_empty         ( almost_empty_ref        ),
  .eccstatus            ( eccstatus               )
);

fifo #(
  .DWIDTH             ( DWIDTH             ),
  .AWIDTH             ( AWIDTH             ),
  .SHOWAHEAD          ( 1                  ),
  .ALMOST_FULL_VALUE  ( ALMOST_FULL_VALUE  ),
  .ALMOST_EMPTY_VALUE ( ALMOST_EMPTY_VALUE ),
  .REGISTER_OUTPUT    ( 0                  ),
) DUT ( 
// INPUT PORT DECLARATION
  .srst_i          ( srst               ),
  .clk_i           ( clk                ),
  .wrreq_i         ( wrreq              ),
  .rdreq_i         ( rdreq              ),

// OUTPUT PORT DECLARATION
  .q_o             ( q                  ),
  .usedw_o         ( usedw              ),
  .full_o          ( full               ),
  .empty_o         ( empty              ),
  .almost_full_o   ( almost_full        ),
  .almost_empty_o  ( almost_empty       ),
  .eccstatus_o     ( eccstatus          )
);

endmodule