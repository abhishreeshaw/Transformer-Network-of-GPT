//---------------------------------------------------------------------------
// DUT - 564/464 Project
//---------------------------------------------------------------------------
`include "common.vh"

module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output wire dut_ready                   ,

//---------------------------------------------------------------------------
//input SRAM interface
  output wire                           dut__tb__sram_input_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_input_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_input_read_data     ,     

//weight SRAM interface
  output wire                           dut__tb__sram_weight_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_weight_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_weight_read_data     ,     

//result SRAM interface
  output wire                           dut__tb__sram_result_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_result_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_result_read_data     ,     

//scratchpad SRAM interface
  output wire                           dut__tb__sram_scratchpad_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_scratchpad_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_scratchpad_read_data  

);

//assign dut__tb__sram_input_write_enable = 1'b0;
//assign dut__tb__sram_input_write_address = `SRAM_ADDR_WIDTH'b0;
//assign dut__tb__sram_input_write_data = `SRAM_DATA_WIDTH'b0;

assign dut__tb__sram_weight_write_enable = 1'b0;
assign dut__tb__sram_weight_write_address = `SRAM_ADDR_WIDTH'b0;
assign dut__tb__sram_weight_write_data = `SRAM_DATA_WIDTH'b0;



//---------------------------------------------------------------------------
//q_state_output SRAM interface
  //reg                    sram_write_enable_rc  ;
 // reg [`SRAM_ADDR_RANGE] sram_write_address_rc ;
// reg [`SRAM_DATA_RANGE] sram_write_data_rc    ;

//address of matrix 1 and matrix 2
  reg [`SRAM_ADDR_RANGE] sram_read_address_ra  ; 
  reg [`SRAM_ADDR_RANGE] sram_read_address_rb  ;
  //complete 
  reg compute_complete;//do we need this
  //conditional variables
  //c element and row completion of result conditions for first three matrix.
  wire all_element_row_completed;
  wire row_c_done;
  wire row_q_done;
  wire multiplication_completed;
  wire multiplication_completed_score;
  //c element and row completion of result conditions for first score matrix.
  wire all_element_q_completed;
  wire row_score_done;
  wire score_done;
  //c element and row completion of result conditions for first score matrix.
  wire all_element_score_completed;
  wire row_attention_done;
  //wire attention_done;

 
 //number of elements in I, (kqv),(KQVZ), and score
  reg[31:0] a_elements;
  reg[31:0] b_elements;
  reg[31:0] c_elements;
  reg[31:0] score_elements;
  reg[31:0]A_size;
  reg[31:0]B_size;

  reg [`SRAM_DATA_RANGE]sram_read_data_A;//do i need this?
  reg [`SRAM_DATA_RANGE]sram_read_data_B;
  reg [`SRAM_DATA_RANGE]sram_read_data_C;
  reg [`SRAM_DATA_RANGE]sram_read_data_SP;
  //counters
  //counters for first three matrix multiplications
  reg [31:0]count_a;
  reg [31:0]count_b;
  reg [31:0]count_bm;
  reg [31:0]count_c;
  //counters for first three score multiplications
  reg [31:0]count_ascore;
  reg [31:0]count_bscore;
  reg [31:0]count_bm_score;
  reg [31:0]count_cscore;//needed to loop for score matrix
  //reg [31:0] count_score;
  //counters for first three matrix multiplications
  reg [31:0]count_aattention;
  reg [31:0]count_battention;
  reg [31:0]count_bm_attention;
  reg [31:0]count_cattention;//i dont think i need this check later
  reg [31:0]count_v;
  //control signals for counters
  reg start_a_count;
  reg start_b_count;
  reg start_score;
  reg start_v;
  //reg multiplication_completed;//indicate coputation of one set of matrix multiplication. 
  reg [2:0]count_m;
  
  
  //keep track of which multiplication is going on and indicate end of implementation of self attention  module.
  //indiacte end of a matrix multiplication
  reg complete_flag;
  reg flag_complete;
  reg complete_flag_score;
  reg flag_complete_score;

  //reg [31:0] accum_result;
  //wire[31:0] mac_result_z;

  reg res_mult;
  reg res_multscore;
  reg res_multattention;
  reg start_c;//use?

  reg [31:0] write_result;//register value assigned to write data wires
  reg [31:0] write_result_score;
  reg [31:0] write_result_attention;
  reg start_accum;//indicates when to start accumulating the products to form SOP
  reg all_S_done;//indicator for score matrix computation
  //reg matrix_I;not needed for now
  //select lines for multiplexing between different srams
  reg sel_sram1;
  reg sel_sram2;
  //regsters to store product and SOP respectively.
  wire [31:0]res_i;
  reg [31:0]res_i_accum;
  reg [31:0]res_i_accum_score;
  reg [31:0]res_i_accum_attention;
  wire [31:0]value1;
  wire [31:0]value2;
  reg start_multiply;//indicates when to start multiplying
  reg [31:0]count_sp;
 

typedef enum logic [3:0] {
  IDLE                          = 4'b0000,
  READ_SRAM_ZERO_ADDR           = 4'b0001,
  READ_SRAM_FIRST_ARRAY_ELEMENT = 4'b0010,
  READ_SRAM_A_complete_row      = 4'b0011,
  Ci_done                       = 4'b0100,
  WRITE_SRAM_elementc           = 4'b0101,
  //COMPUTE_COMPLETE              = 4'b0110,
  RESET_FOR_ANOTHER_MATRIX      = 4'b0111,
  Read_SRAM_Q_complete_row      = 4'b1000,
  Score_Ci_done                 = 4'b1001,
  Write_score_in_A              = 4'b1010,
  set_for_attention_computation = 4'b1011,
  Read_SRAM_score_complete_row  = 4'b1100,
  Attention_ci_done             = 4'b1101,
  write_attention_c             = 4'b1110,
  product_available             = 4'b1111
  } e_states;

  e_states current_state, next_state;

// Local control path variables
  reg                           set_dut_ready             ;
  reg                           get_array_size_A          ;
  reg                           get_array_size_B          ;
  reg [2:0]                     read_addr_sel_A           ;
  reg [2:0]                     read_addr_sel_B           ;
  reg                           compute_accumulation      ;
  reg                           save_array_size           ;
  reg                           write_enable_sel          ;

// Local data path variables 
  reg [`SRAM_DATA_WIDTH-1:0]      array_size_A            ;
  reg [`SRAM_DATA_WIDTH-1:0]      array_size_B            ;

  
// -------------------- Control path ------------------------
always @(posedge clk) begin : proc_current_state_fsm
  if(!reset_n) begin // Synchronous reset
  begin
    current_state <= IDLE;
  end
  end else begin
    current_state <= next_state;
  end
end

//read data from sram (matrix A,B,C and SP)
/*always@(posedge clk) begin
if(reset_n) begin
  sram_read_data_A <= tb__dut__sram_input_read_data ;
  sram_read_data_B <= tb__dut__sram_weight_read_data ;
  sram_read_data_C <= tb__dut__sram_result_read_data;//added
  sram_read_data_SP <= tb__dut__sram_scratchpad_read_data;//added
end
else begin
  sram_read_data_A <= 32'b0; ;
  sram_read_data_B <=  32'b0;
  sram_read_data_C <= 32'b0;//added
  sram_read_data_SP <= 32'b0;//added
end
end*/ //check if this needed

always @(*) begin : proc_next_state_fsm
  case (current_state)

    IDLE                    : begin
      if (dut_valid) begin
        start_a_count         = 1'b0;
        start_b_count         = 1'b0;
        start_score           = 1'b0;
        start_v               = 1'b0;
        set_dut_ready         = 1'b0;
        get_array_size_A      = 1'b0;
        get_array_size_B      = 1'b0;
        read_addr_sel_A       = 3'b000;
        read_addr_sel_B       = 3'b000;
        compute_accumulation  = 1'b0;
        save_array_size       = 1'b0;
        write_enable_sel      = 1'b0;
        next_state            = READ_SRAM_ZERO_ADDR;
        start_c               = 1'b0;
        start_accum           = 1'b0;
        sel_sram1             = 1'b0;
        sel_sram2             = 1'b0;
        
      end
      else begin
        start_a_count         = 1'b0;
        start_b_count         = 1'b0;
        start_v               = 1'b0;
        start_score           = 1'b1;
        set_dut_ready         = 1'b1;
        get_array_size_A      = 1'b0;
        get_array_size_B      = 1'b0;
        read_addr_sel_A       = 3'b000;
        read_addr_sel_B       = 3'b000;
        compute_accumulation  = 1'b0;
        write_enable_sel      = 1'b0;
        save_array_size       = 1'b0;
        next_state            = IDLE;
        start_c               = 1'b1;
        start_accum           =32'b0;
        sel_sram1             = 1'b0;
        sel_sram2             = 1'b0;
    
      end
    end
  
    READ_SRAM_ZERO_ADDR  : begin //address is 0 here, but address generator is at +1 stage, so address 1 is available in next cycle and value at address one is available next to that
      start_a_count           = 1'b1;
      start_b_count           = 1'b1;
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = 1'b0;
      set_dut_ready           = 1'b0;
      get_array_size_A        = 1'b1;
      get_array_size_B        = 1'b1;
      read_addr_sel_A         = 3'b001;
      read_addr_sel_B         = 3'b001;
      compute_accumulation    = 1'b0;
      save_array_size         = 1'b0;
      write_enable_sel        = 1'b0;
      next_state              = READ_SRAM_FIRST_ARRAY_ELEMENT;
      sel_sram1               = 1'b0;
      sel_sram2               = 1'b0;
     
    end 

    READ_SRAM_FIRST_ARRAY_ELEMENT: begin
      start_a_count         = 1'b1;
      start_b_count         = 1'b1;//
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = 3'b001;
      read_addr_sel_B       = 3'b001;
      compute_accumulation  = 1'b0;//should this be 1
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;
      next_state            = READ_SRAM_A_complete_row;
      sel_sram1               = 1'b0;
      sel_sram2               = 1'b0; 
     
    end

    READ_SRAM_A_complete_row     : begin
      start_a_count         = 1'b1;
      start_b_count         = 1'b1;
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = all_element_row_completed ?(row_c_done?3'b001:3'b010):3'b001;//changedK
      read_addr_sel_B       = row_c_done ?(multiplication_completed?3'b110:3'b010):3'b001;
      compute_accumulation  = 1'b1;//do we need this?
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;
      next_state            = (res_mult)?WRITE_SRAM_elementc:(all_element_row_completed ? Ci_done:READ_SRAM_A_complete_row);//all_element_row_completed ? Ci_done:READ_SRAM_A_complete_row;
      sel_sram1               = 1'b0;
      sel_sram2               = 1'b0;
    
    end 

    Ci_done : begin
      start_a_count         = (complete_flag)?1'b0:1'b1;
      start_b_count         = (complete_flag)?1'b0:1'b1;
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = complete_flag?3'b011:3'b001;//store or increment
      read_addr_sel_B       = 3'b001;//complete_flag?3'b001:3'b001;//3'b001;//row_c_done ? 2'b10 :2'b01;110 changed to 001
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;
      next_state            = WRITE_SRAM_elementc; 
      sel_sram1               = 1'b0;
      sel_sram2               = 1'b0;
     // write_result          <=mac_result_z;  
    end
//have to fix mux selection for this
    WRITE_SRAM_elementc : begin
      start_a_count         = (flag_complete)?1'b0:1'b1;
      start_b_count         = (flag_complete)?1'b0:1'b1;
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;//(flag_complete)?1'b1:1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b1;
      next_state            = (res_mult)?WRITE_SRAM_elementc:(flag_complete ? RESET_FOR_ANOTHER_MATRIX:READ_SRAM_A_complete_row);
      read_addr_sel_A       = (flag_complete) ? 3'b101: (all_element_row_completed ?(row_c_done?3'b001:3'b010):3'b001);//3'b001;
      read_addr_sel_B       = (flag_complete) ? 3'b110:( row_c_done ?(multiplication_completed?3'b110:3'b010):3'b001);//3'b001;
      sel_sram1               = 1'b0;
      sel_sram2               = 1'b0;
     // write_result          <=32'b0;
     //add logic to write S to A and K to scratchpad
    end

    RESET_FOR_ANOTHER_MATRIX : begin
      set_dut_ready         = 1'b0;//will it be 0/1?
      start_a_count         = 1'b1;
      start_b_count         = 1'b1;//changed to 1
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = (next_state==Read_SRAM_Q_complete_row)?1'b1:1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      compute_accumulation  = 1'b0;//check if this should be 1/0?
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;
      next_state            = (count_m==2)?Read_SRAM_Q_complete_row:READ_SRAM_A_complete_row;
      read_addr_sel_A       = (next_state==READ_SRAM_A_complete_row)?3'b011:3'b000;//
      read_addr_sel_B       = (next_state==READ_SRAM_A_complete_row)?3'b110:3'b000;
      sel_sram1             = (next_state==READ_SRAM_A_complete_row)?1'b0:1'b1;//change
      sel_sram2             = (next_state==READ_SRAM_A_complete_row)?1'b0:1'b1;//change
    end

    Read_SRAM_Q_complete_row : begin 
      start_a_count         = 1'b1;
      start_b_count         = 1'b1;
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = all_element_q_completed ?(row_score_done?3'b001:3'b110):3'b001;//changedK
      read_addr_sel_B       = all_element_q_completed?(row_score_done ?(multiplication_completed_score?3'b110:3'b010):3'b001):001;//change
      compute_accumulation  = 1'b1;//do we need this?
      save_array_size       = 1'b1;
      write_enable_sel      =1'b0;// (count_ascore==2)?1'b1:1'b0;
      next_state            =(res_multscore)?Write_score_in_A:(all_element_q_completed ? Score_Ci_done:Read_SRAM_Q_complete_row);
      sel_sram1               = 1'b1;
      sel_sram2               = 1'b1;

    end

    Score_Ci_done : begin 
      start_a_count         = (complete_flag_score)?1'b0:1'b1;
      start_b_count         = (complete_flag_score)?1'b0:1'b1;
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = (flag_complete_score) ? 3'b101:(row_score_done)?3'b001:((all_element_q_completed)?3'b110:3'b001);//store or increment
      read_addr_sel_B       = (flag_complete_score) ? 3'b110:(row_score_done)? 3'b111:3'b001;//3'b001;//complete_flag?3'b001:3'b001;//3'b001;//row_c_done ? 2'b10 :2'b01;110 changed to 001
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;//(count_ascore==2&&write_result_score!=32'b0)?1'b1:1'b0;
      next_state            = Write_score_in_A; 
      sel_sram1               = 1'b1;
      sel_sram2               = 1'b1;
    end

    Write_score_in_A : begin 
      start_a_count         = (flag_complete_score)?1'b0:1'b1;
      start_b_count         = (flag_complete_score)?1'b0:1'b1;
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b1;
      next_state            = (res_multscore)?Write_score_in_A:(flag_complete_score ? set_for_attention_computation:Read_SRAM_Q_complete_row);
      read_addr_sel_A       = (flag_complete_score) ? 3'b101:(row_score_done)?3'b001:((all_element_q_completed)?3'b110:3'b001);
      read_addr_sel_B       = (flag_complete_score) ? 3'b110:(row_score_done)? 3'b111:3'b001;
      sel_sram1               = 1'b1;
      sel_sram2               = 1'b1;
    end

    set_for_attention_computation          :  begin
      set_dut_ready         = 1'b0;
      start_a_count         = 1'b0;
      start_c               = 1'b0;
      start_v               = 1'b0;
      start_score           = 1'b0;
      start_b_count         = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = 3'b100;//plus 1 logic
      read_addr_sel_B       = 3'b011;//think
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;
      next_state            = Read_SRAM_score_complete_row;//all_S_done? attention_computation : write_S_matrix;
      sel_sram1               = 1'b1;
      sel_sram2               = 1'b1;

    end

    Read_SRAM_score_complete_row :begin 
      start_a_count         = 1'b1;
      start_b_count         = 1'b1;
      start_c               = 1'b0;
      start_v=1'b1;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = all_element_score_completed ?(row_attention_done?3'b001:3'b111):3'b001;//changedK
      read_addr_sel_B       = all_element_score_completed?(row_attention_done ?3'b011:3'b101):3'b100;//rb+bcol
      compute_accumulation  = 1'b1;//do we need this?
      save_array_size       = 1'b1;
      write_enable_sel      = (count_aattention==2&&write_result_score!=32'b0)?1'b1:1'b0;//1'b0;//(count_ascore==2)?1'b1:1'b0;
      next_state            =(res_multattention)?write_attention_c:(all_element_score_completed?Attention_ci_done:Read_SRAM_score_complete_row);
      sel_sram1               = 1'b1;//flag_complete_score?IDLE:(all_element_score_completed?Attention_ci_done:Read_SRAM_score_complete_row);
      sel_sram2               = 1'b1;
    end

    Attention_ci_done : begin 
      start_a_count         = 1'b1;
      start_b_count         = 1'b1;
      start_c               = 1'b0;
      start_v=1'b1;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = all_element_score_completed ?(row_attention_done?3'b001:3'b111):3'b001;
      read_addr_sel_B       = all_element_score_completed?(row_attention_done ?3'b011:3'b101):3'b100;//3'b001;//complete_flag?3'b001:3'b001;//3'b001;//row_c_done ? 2'b10 :2'b01;110 changed to 001
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;//(count_ascore==2&&write_result_score!=32'b0)?1'b1:1'b0;
      next_state            = write_attention_c; 
      sel_sram1               = 1'b1;
      sel_sram2               = 1'b1;

    end

    write_attention_c : begin
      start_a_count         = (flag_complete)?1'b0:1'b1;
      start_b_count         = (flag_complete)?1'b0:1'b1;
      start_c               = 1'b0;
      start_v=1'b1;
      start_score           = 1'b0;
      set_dut_ready         = 1'b0;//(flag_complete)?1'b1:1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      compute_accumulation  = 1'b1;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b1;//1'b1;
      next_state            =(flag_complete_score) ? product_available:(res_multattention?write_attention_c:Read_SRAM_score_complete_row);
      read_addr_sel_A       = all_element_score_completed ?(row_attention_done?3'b001:3'b111):3'b001;
      read_addr_sel_B       = all_element_score_completed?(row_attention_done ?3'b011:3'b101):3'b100;
      sel_sram1               = 1'b1;
      sel_sram2               = 1'b1;
 end
   /* attention_computation   : begin
      set_dut_ready         = 1'b0;
      start_a_count         =1'b1;
      start_b_count         =1'b1;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = 1'b11;//read matrix S from Sram A
      read_addr_sel_B       = 1'b10;//read matrix V from Scratchpad
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;
      next_state            = (count_m==5)?product_available:READ_SRAM_A_complete_row;
      sel_sram1               = 1'b1;
      sel_sram2               = 1'b1;
    end*/

    product_available       : begin
      set_dut_ready         = 1'b1;
      start_a_count         = 1'b0;//(flag_complete)?1'b0:1'b1;
      start_b_count         = 1'b0;//(flag_complete)?1'b0:1'b1;
      start_v=1'b0;
      start_c               = 1'b0;
      start_score           = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = 1'b00;//read matrix S from Sram A
      read_addr_sel_B       = 1'b00;//read matrix V from Scratchpad
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;
      next_state            = IDLE;
      sel_sram1               = 1'b0;
      sel_sram2               = 1'b0;
    end

    default                 :  begin
      set_dut_ready         = 1'b1;
      start_v=1'b0;
      start_a_count         = 1'b0;//(flag_complete)?1'b0:1'b1;
      start_b_count         = 1'b0;//(flag_complete)?1'b0:1'b1;
      start_c               = 1'b0;
      start_score           = 1'b0;
      get_array_size_A      = 1'b0;
      get_array_size_B      = 1'b0;
      read_addr_sel_A       = 2'b00;
      read_addr_sel_B       = 2'b00;
      compute_accumulation  = 1'b0;
      save_array_size       = 1'b1;
      write_enable_sel      = 1'b0;      
      next_state            = IDLE;
      sel_sram1             = 1'b0;
      sel_sram2             = 1'b0;
    // write_result          <=32'b0;
    end
  endcase
end

//number of elements in I, kqv, KQVZ, score matrix
 assign a_elements = A_size[31:16]*A_size[15:0];
 assign b_elements = B_size[31:16]*B_size[15:0];
 assign c_elements = A_size[31:16]*B_size[15:0];
 assign score_elements = A_size[31:16]*A_size[31:16];

// DUT ready handshake logic
always @(posedge clk) begin : proc_compute_complete
  if(!reset_n) begin
    compute_complete <= 0;
  end else begin
    compute_complete <= (set_dut_ready)?1'b1:1'b0;//(set_dut_ready) ? 1'b1 : 1'b0;
  end
end

assign dut_ready = compute_complete;

always@(posedge clk) begin
    if(dut_valid) begin
A_size <= tb__dut__sram_input_read_data;
B_size <= tb__dut__sram_weight_read_data;
    end
    else begin
A_size <= A_size;
B_size <= B_size;
    end
end

// Find the number of rows and columns of matrix A and B 
always @(posedge clk) begin : proc_array_size
  if(!reset_n) begin
    array_size_A <= `SRAM_DATA_WIDTH'b0;
    array_size_A <= `SRAM_DATA_WIDTH'b0;
  end else begin
    array_size_A <= get_array_size_A ? A_size : (save_array_size ? array_size_A : `SRAM_DATA_WIDTH'b0);// wire name of read data
    array_size_B <= get_array_size_B ? B_size : (save_array_size ? array_size_B : `SRAM_DATA_WIDTH'b0);
  end
end

//counter for a
always@(posedge clk) begin : proc_counter_for_a
if(start_a_count)
    if (all_element_row_completed)
count_a<=32'b1;
    else
    count_a<=count_a+32'b1;
else
count_a<=32'b0;
end

//counter for score matrix calculation (a)
always@(posedge clk) begin : proc_counter_for_ascore
if(start_a_count)
    if (all_element_q_completed)
count_ascore<=32'b1;
    else
    count_ascore<=count_ascore+32'b1;
else
count_ascore<=32'b0;
end

//counter for attention matrix
always@(posedge clk) begin : proc_counter_for_aattention
if(start_a_count)
    if (all_element_score_completed)
count_aattention<=32'b1;
    else
    count_aattention<=count_aattention+32'b1;
else
count_aattention<=32'b1;
end

//counter for b score
always@(posedge clk) begin : proc_counter_for_bscore
if(start_b_count)
     if(row_score_done)
      count_bscore <= 32'b1;
      else
      count_bscore<=count_bscore+32'b1;
else count_bscore <= 32'b0;
end

//counter for  (b)
always@(posedge clk) begin : proc_counter_for_b
if(start_b_count)
     if(row_c_done)
      count_b <= 32'b1;
      else
      count_b<=count_b+32'b1;
else count_b <= 32'b0;
end

//counter for b attention 
always@(posedge clk) begin : proc_counter_for_battention
if(start_b_count)
     if(row_attention_done)
      count_battention <= 32'b1;
      else
      count_battention<=count_battention+32'b1;
else count_battention <= 32'b1;
end

//master counter b
always@(posedge clk) begin : proc_counter_for_bm
if(start_b_count) 
     if(multiplication_completed)
      count_bm <= 32'b1;
      else
      count_bm<=count_bm+32'b1;
else count_bm <= 32'b0;
end

always@(posedge clk) begin : proc_counter_for_bm_score
if(start_b_count) 
     if(multiplication_completed_score)
      count_bm_score <= 32'b1;
      else
      count_bm_score<=count_bm_score+32'b1;
else count_bm_score <= 32'b0;
end



//counter for scratchpad
always@(posedge clk)begin : proc_counter_for_sp
if(start_c)
    count_sp<=-1;
else if(res_mult&&(count_m==1||count_m==2))
    count_sp <= count_sp+32'b1;
else
    count_sp<=count_sp;
end

//counter for c
always@(posedge clk) begin : proc_counter_for_c
if(start_score)
    count_c<=0;
else if(dut__tb__sram_result_write_enable)
    count_c <= count_c+32'b1;
else
    count_c<=count_c;
end

/*always@(posedge clk) begin : proc_counter_for_c
if(start_score)
    count_c<=-1;
else if()
    count_c <= count_c+32'b1;
else
    count_c<=count_c;
end*/

//counter for score matrix address
/*always@(posedge clk) begin : proc_counter_for_score
if(start_score)
    count_score<=-1;
else if(res_multscore)
    count_score <= count_score+32'b1;
else
    count_score<=count_score;
end*/

always@(posedge clk) begin : proc_counter_for_vtranspose
if(start_v)
  if(all_element_score_completed&& !row_attention_done)
   count_v <= count_v+1;
   else if(row_attention_done)
   count_v <=0;
   else 
   count_v <= count_v;
else count_v <=0;
end

//to count for number of multiplcations done
always@(posedge clk) begin :proc_count_no_of_multiplications
if(!dut_ready)begin
if(current_state==RESET_FOR_ANOTHER_MATRIX || current_state==set_for_attention_computation)//assign this value in the state where multiplication is done for one set of matrices
  count_m<=count_m+32'b1;
  else
  count_m<=count_m; end
  else
  count_m<=0;
end


  //assign start_a_count = (count_a==15)?1:0;  

// SRAM read address generator for matrix A
always @(posedge clk) begin
    if (!reset_n) begin
      sram_read_address_ra   <= 3'b0;
    end
    else begin
      if (read_addr_sel_A == 3'b000) begin
        sram_read_address_ra <= `SRAM_ADDR_WIDTH'b0; 
        end
      else if (read_addr_sel_A == 3'b001) begin
        sram_read_address_ra <= sram_read_address_ra + `SRAM_ADDR_WIDTH'b1;
         end
      else if (read_addr_sel_A == 3'b010) begin
        sram_read_address_ra <= sram_read_address_ra-array_size_A[15:0]+1; 
        end
      else if (read_addr_sel_A == 3'b011) begin
        sram_read_address_ra <= 32'b1;
        end//to read elements of matrix 
        else if(read_addr_sel_A ==3'b100) begin
       sram_read_address_ra <=c_elements*3;end
       else if(read_addr_sel_A ==3'b101)begin
       sram_read_address_ra<=sram_read_address_ra;
        end
        else if(read_addr_sel_A == 3'b110)
        sram_read_address_ra<=sram_read_address_ra-B_size[15:0]+1;
        else
        sram_read_address_ra<=sram_read_address_ra-A_size[31:16]+1;
    end
end

//reading address of first matrix

assign dut__tb__sram_input_read_address = (!sel_sram1)?sram_read_address_ra:`SRAM_ADDR_WIDTH'b0;//to read from Sram A
assign dut__tb__sram_result_read_address = (sel_sram1)?sram_read_address_ra:`SRAM_ADDR_WIDTH'b0;

  assign value1 = (sel_sram1)?tb__dut__sram_result_read_data:tb__dut__sram_input_read_data;


// SRAM read address generator for matrix B
always @(posedge clk) begin
    if (!reset_n) begin
      sram_read_address_rb   <= 3'b0;
    end
    else begin
      if (read_addr_sel_B == 3'b000) begin 
        sram_read_address_rb <= `SRAM_ADDR_WIDTH'b0;
        end
      else if (read_addr_sel_B == 3'b001) begin
        sram_read_address_rb <= sram_read_address_rb + `SRAM_ADDR_WIDTH'b1;
         end
      else if (read_addr_sel_B == 3'b010) begin
        if (count_m==3 || count_m==4)
        sram_read_address_rb <= sram_read_address_rb-c_elements+32'b1; 
        else
        sram_read_address_rb <= sram_read_address_rb-b_elements+32'b1; 
        end
      else if (read_addr_sel_B == 3'b011) begin
        sram_read_address_rb <= c_elements;
        end
        else if(read_addr_sel_B ==3'b100)begin 
          sram_read_address_rb<=sram_read_address_rb+B_size[15:0];
        end
        else if(read_addr_sel_B==3'b101)begin
          sram_read_address_rb<=c_elements+count_v+1;
         end
         else if(read_addr_sel_B==3'b110)begin 
          sram_read_address_rb<=sram_read_address_rb;
         end
         else if(read_addr_sel_B==3'b111)begin 
          sram_read_address_rb<=sram_read_address_rb-c_elements+1;
         end
    end
end

//reading address of second matrix
assign dut__tb__sram_weight_read_address = (!sel_sram2)?sram_read_address_rb:`SRAM_ADDR_WIDTH'b0;
assign dut__tb__sram_scratchpad_read_address = (sel_sram2)?sram_read_address_rb:`SRAM_ADDR_WIDTH'b0;//to read K or V matrix (B) from sratchpad
assign value2 = (sel_sram2)?tb__dut__sram_scratchpad_read_data:tb__dut__sram_weight_read_data;

// READ for all elemenets in a row in SRAM A (ci computation is done)
  assign all_element_row_completed = (count_a == (A_size[15:0])) ? 1'b1 : 1'b0;
  assign all_element_q_completed = (count_ascore == B_size[15:0])?1'b1:1'b0;
  assign all_element_score_completed = (count_aattention == A_size[31:16])?1'b1:1'b0;

//A row in result matrix is done
assign row_c_done = (count_m==3)?((count_b==c_elements)?1:0):((count_b==b_elements)?1:0);//add condition here
assign row_score_done = (count_bscore==c_elements)?1:0;
assign row_attention_done = (count_battention==c_elements)?1'b1:1'b0;//check if row_score can be used
  

    always@(posedge clk)
    begin
    if(all_element_row_completed)
    res_mult <= 1'b1;
    else
    res_mult <= 1'b0;
    end

    always@(posedge clk)
    begin
    if(all_element_q_completed)
    res_multscore <= 1'b1;
    else
    res_multscore <= 1'b0;
    end

    always@(posedge clk)
    begin 
      if(all_element_score_completed&&count_m==4)
      res_multattention <=1'b1;
      else
      res_multattention <= 1'b0;
    end

  


//enable signal logic for writing to srams
assign dut__tb__sram_result_write_enable = (write_enable_sel&&count_m<=4)?1'b1:1'b0;//add write_enable signals for scratchpad and sram A
assign dut__tb__sram_scratchpad_write_enable = (write_enable_sel&&(count_m==1||count_m==2))?1'b1:1'b0;
assign dut__tb__sram_input_write_enable = (write_enable_sel&&count_m==3)?1'b1:1'b0;

//writing to c
assign dut__tb__sram_result_write_address = count_c;
assign dut__tb__sram_result_write_data = (count_m==3)?write_result_score:(count_m==4)?write_result_attention:write_result;
//writing to scratchpad
assign dut__tb__sram_scratchpad_write_data = write_result;
assign dut__tb__sram_scratchpad_write_address = count_sp;

//writing to input, sram A to add
//assign dut__tb__sram_input_write_data = write_result;
//assign dut__tb__sram_input_write_address = count_score;

// one row of matrix c is done
/*always @(posedge clk) begin:proc_row_c_done
  if(!reset_n) begin
    row_c_done <= 1'b0;
  end
  else*/
   
    
//end 

//multiplication is done
   assign multiplication_completed =  (count_bm==(b_elements*A_size[31:16]))?1'b1:1'b0;
   assign multiplication_completed_score = (count_m==3)?((count_bm_score==(c_elements*A_size[31:16]))?1'b1:1'b0):((count_bm_score+1)==(c_elements*A_size[31:16])?1'b1:1'b0);
//complete conditions for first three matrices
  always@(posedge clk)
    begin
    
      if(multiplication_completed)
    complete_flag <= 1'b1;
      else 
    complete_flag <=1'b0;
      
    end

   always@(posedge clk)
    begin
    if(complete_flag)
  flag_complete <=1'b1;
    else 
  flag_complete<=1'b0;
  end
//complete condition for score matrix
always@(posedge clk)
    begin
      if(count_m==3)
      if(multiplication_completed_score)
    complete_flag_score <= 1'b1;
      else 
    complete_flag_score <=1'b0;
    else if(count_m==4)
     if(multiplication_completed_score)
    complete_flag_score <= 1'b1;
      else 
    complete_flag_score <=1'b0;
    end

   always@(posedge clk)
    begin
    if(complete_flag_score)
  flag_complete_score <=1'b1;
    else 
  flag_complete_score<=1'b0;
  end


   


always@(posedge clk) begin
if(count_b==0 && count_m<=3)
start_multiply<=0;
else if(count_m==4 && current_state!=set_for_attention_computation)
start_multiply<=1; 
else
start_multiply<=1;
end

assign res_i = (start_multiply==0)?32'b0:(value1*value2);//changed!!!!!


always @(posedge clk) begin : proc_accumulation_c
   if(!compute_accumulation)begin
   res_i_accum<=32'b0;
   write_result<=32'b0;end
        else if(!res_mult && compute_accumulation && count_m<=2)   //else if(!write_enable_sel && compute_accumulation)
      begin
      write_result <= write_result;
       res_i_accum <= res_i+res_i_accum;
    end
    else if(count_m==3)
    write_result<=0;
    else begin
       write_result <= res_i_accum+res_i;
       res_i_accum <=32'b0;
      // write_result <= res_i_accum;
    end
  end

  always @(posedge clk) begin : proc_accumulation_c_score
   if(!compute_accumulation)begin
   res_i_accum_score<=32'b0;
   write_result_score<=write_result;end
        else if(!res_multscore && compute_accumulation && count_m==3)   //else if(!write_enable_sel && compute_accumulation)
      begin
      write_result_score <= write_result_score;
       res_i_accum_score <= res_i+res_i_accum_score;
    end
    else begin
       write_result_score <= res_i_accum_score+res_i;
       res_i_accum_score <=32'b0;
      // write_result <= res_i_accum;
    end
  end

  always @(posedge clk) begin : proc_accumulation_z_score
   if(!compute_accumulation)begin
   res_i_accum_attention<=32'b0;
   write_result_attention<=write_result;end
        else if(!res_multattention && compute_accumulation && count_m==4)   //else if(!write_enable_sel && compute_accumulation)
      begin
      write_result_attention <= write_result_attention;
       res_i_accum_attention <= res_i+res_i_accum_attention;
    end
    else begin
       write_result_attention <= res_i_accum_attention+res_i;
       res_i_accum_attention <=32'b0;
      // write_result <= res_i_accum;
    end
  end






endmodule

 