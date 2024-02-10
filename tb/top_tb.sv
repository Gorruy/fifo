`timescale 1ps/1ps

module top_tb;

  parameter DWIDTH              = 320;
  parameter AWIDTH              = 10;
  parameter SHOWAHEAD           = 1;
  parameter ALMOST_FULL_VALUE   = 14;
  parameter ALMOST_EMPTY_VALUE  = 2;
  parameter REGISTER_OUTPUT     = 0;

  parameter NUMBER_OF_TEST_RUNS = 2**AWIDTH * 4;
  parameter NUMBER_OF_TESTS     = 6;
  parameter TIMEOUT             = 10;
  
  bit                  clk;
  logic                srst;

  logic [DWIDTH - 1:0] data_ref;
  logic                wrreq_ref;
  logic                rdreq_ref;
  logic                aclr;

  logic [DWIDTH - 1:0] q_ref;
  logic [AWIDTH:0]     usedw_ref;
  logic                full_ref;
  logic                empty_ref;
  logic                almost_full_ref;
  logic                almost_empty_ref;
  logic [1:0]          eccstatus;

  logic [DWIDTH - 1:0] data;
  logic                wrreq;
  logic                rdreq;
  logic [DWIDTH - 1:0] q;
  logic [AWIDTH:0]     usedw;
  logic                full;
  logic                empty;
  logic                almost_full;
  logic                almost_empty;

  logic                srst_done;
  bit                  test_succeed;

  initial forever #5 clk = !clk;

  default clocking cb @( posedge clk );
  endclocking

  initial 
    begin
      srst      <= 1'b0;
      ##1;
      srst      <= 1'b1;
      ##1;
      srst      <= 1'b0;
      srst_done <= 1'b1;
    end

  scfifo #(
    .lpm_width               ( DWIDTH                ),
    .lpm_widthu              ( AWIDTH + 1            ),
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
    .data                    ( data_ref              ),
    .clock                   ( clk                   ),
    .wrreq                   ( wrreq_ref             ),
    .rdreq                   ( rdreq_ref             ),
    .aclr                    ( aclr                  ),
    .sclr                    ( srst                  ),
    .q                       ( q_ref                 ),
    .usedw                   ( usedw_ref             ),
    .full                    ( full_ref              ),
    .empty                   ( empty_ref             ),
    .almost_full             ( almost_full_ref       ),
    .almost_empty            ( almost_empty_ref      ),
    .eccstatus               ( eccstatus             )
  );

  fifo #(
    .DWIDTH             ( DWIDTH             ),
    .AWIDTH             ( AWIDTH             ),
    .SHOWAHEAD          ( 1                  ),
    .ALMOST_FULL_VALUE  ( ALMOST_FULL_VALUE  ),
    .ALMOST_EMPTY_VALUE ( ALMOST_EMPTY_VALUE ),
    .REGISTER_OUTPUT    ( 0                  )
  ) DUT ( 
    .srst_i             ( srst               ),
    .data_i             ( data               ),
    .clk_i              ( clk                ),
    .wrreq_i            ( wrreq              ),
    .rdreq_i            ( rdreq              ),
    .q_o                ( q                  ),
    .usedw_o            ( usedw              ),
    .full_o             ( full               ),
    .empty_o            ( empty              ),
    .almost_full_o      ( almost_full        ),
    .almost_empty_o     ( almost_empty       )
  );

  mailbox #( logic[DWIDTH - 1:0] ) generated_data[NUMBER_OF_TESTS - 1:0];

  task generate_data( mailbox #( logic[DWIDTH - 1:0] ) generated_data[NUMBER_OF_TESTS - 1:0] );
    
    logic[DWIDTH - 1:0] gen_data;

    repeat (NUMBER_OF_TEST_RUNS)
      begin
        gen_data = $urandom_range( 2**DWIDTH - 1, 0 );

        foreach ( generated_data[i] )
          generated_data[i].put( gen_data );
      end

  endtask

  task send_data ( mailbox #( logic[DWIDTH - 1:0]) generated_data,
                   int                             no_delay,
                   int                             one_delay 
                 );

    logic[DWIDTH - 1:0] data_to_write;
    int                 random_delay;
    int                 timeout_counter;
    
    while ( generated_data.num() )
      begin
        random_delay = $urandom_range( TIMEOUT - 1, 0 ) * !no_delay + one_delay;
        ##(random_delay);

        generated_data.get( data_to_write );

        timeout_counter = 0;

        while ( full_ref === 1'b1 || full === 1'b1 ) 
          begin
            ##1;
            if ( timeout_counter == TIMEOUT + 1 )
              return;
            else
              timeout_counter += 1;
          end

        wrreq_ref = 1'b1;
        data_ref  = data_to_write;
        wrreq     = 1'b1;
        data      = data_to_write;
        ##1;
        wrreq_ref = 1'b0;
        wrreq     = 1'b0;

      end

  endtask

  task observe_sessions;

    int timeout_counter;

    timeout_counter = 0;
    
    while ( timeout_counter != TIMEOUT + 1 )
      begin
        @( posedge clk );

        if ( full !== full_ref )
          begin
            $error( "DUT and ref model ran out of space differently! Ref:%b, DUT:%b", full, full_ref );
            test_succeed = 1'b0;
            return;
          end
        
        if ( empty !== empty_ref )
          begin
            $error( "DUT and ref model emptied at different time! Ref:%b, DUT:%b", empty, empty_ref );
            test_succeed = 1'b0;
            return;
          end

        if ( usedw !== usedw_ref )
          begin
            $error( "Different amount of data stored in DUT and ref model! Ref:%d, DUT:%d", usedw, usedw_ref );
            test_succeed = 1'b0;
            return;
          end

        if ( almost_empty !== almost_empty_ref )
          begin
            $error( "Almost_empty signal at different time! Ref:%b, DUT:%b", almost_empty, almost_empty_ref );
            test_succeed = 1'b0;
            return;
          end

        if ( almost_full !== almost_full_ref )
          begin
            $error( "Almost_full signal at different time! Ref:%b, DUT:%b", almost_full, almost_full_ref );
            test_succeed = 1'b0;
            return;
          end

        if ( q !== q_ref )
          begin
            $error( "Data from DUT and ref model differ!: Ref:%b, DUT:%b", q_ref, q );
            test_succeed = 1'b0;
            return;
          end

        if ( wrreq || rdreq )
          timeout_counter = 0;
        else
          timeout_counter += 1;
      end

  endtask

  task read_data( int no_delay, 
                  int one_delay 
                );

    logic[DWIDTH - 1:0] read_data;
    int                 random_delay;
    int                 timeout_counter;

    repeat(NUMBER_OF_TEST_RUNS)
      begin
        random_delay = $urandom_range( TIMEOUT - 1, 0 ) * !no_delay + one_delay;
        ##(random_delay);

        timeout_counter = 0;

        while ( empty_ref === 1'b1 || empty === 1'b1 ) 
          begin
            ##1;
            if ( timeout_counter == TIMEOUT + 1 )
              return;
            else
              timeout_counter += 1;
          end

        rdreq_ref = 1'b1;
        rdreq     = 1'b1;
        ##1;
        rdreq_ref = 1'b0;
        rdreq     = 1'b0;
      end

  endtask

  initial begin
    test_succeed = 1'b1;
    rdreq_ref    = 1'b0;
    rdreq        = 1'b0;
    wrreq_ref    = 1'b0;
    wrreq        = 1'b0;
    aclr         = 1'b0;

    foreach( generated_data[i] )
      begin
        generated_data[i] = new();
      end

    $display("Simulation started!");
    generate_data( generated_data );
    wait( srst_done === 1'b1 );

    $display("Tests with random delays started!");
    fork
      send_data( generated_data[0], 0, 0 );
      observe_sessions();
      read_data( 0, 0 );
    join

    $display("Tests without time delay started!");
    fork
      send_data( generated_data[1], 1, 0 );
      observe_sessions();
      read_data( 1, 0 );
    join

    $display("Tests with one read delay started!");
    fork
      // checks cases when fifo becomes full
      send_data( generated_data[2], 1, 0 );
      observe_sessions();
      read_data( 0, 0 );
    join

    $display("Making fifo full");
    fork
      send_data( generated_data[3], 1, 0 );
      observe_sessions();
    join

    $display("Emptying fifo");
    fork
      read_data( 1, 1 );
      observe_sessions();
    join

    $display("Tests with rare read started!");
    fork
      send_data( generated_data[4], 1, 0 );
      read_data( 0, 0 );
      observe_sessions();
    join

    $display("Tests with rare write started!");
    fork
      send_data( generated_data[5], 0, 0 );
      read_data( 1, 0 );
      observe_sessions();
    join
    $display("Simulation is over!");

    observe_sessions();
    ##1;
    wrreq_ref = 1'b1;
    data_ref  = '0;
    wrreq     = 1'b1;
    data      = '0;
    ##1;
    wrreq_ref = 1'b0;
    wrreq     = 1'b0;
    ##2;

    ##1;
    wrreq_ref = 1'b1;
    data_ref  = '1;
    wrreq     = 1'b1;
    data      = '1;
    rdreq_ref = 1'b1;
    rdreq     = 1'b1;
    ##1;
    wrreq_ref = 1'b0;
    wrreq     = 1'b0;
    rdreq_ref = 1'b0;
    rdreq     = 1'b0;
    ##5;


    if ( test_succeed )
      begin
        $display("All tests passed!");
      end

    $stop();

  end

endmodule