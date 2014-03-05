library verilog;
use verilog.vl_types.all;
entity rtr_channel_input is
    generic(
        num_vcs         : integer := 4;
        packet_format   : integer := 2;
        max_payload_length: integer := 4;
        min_payload_length: integer := 1;
        route_info_width: integer := 14;
        enable_link_pm  : integer := 1;
        flit_data_width : integer := 64;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active          : in     vl_logic;
        channel_in      : in     vl_logic_vector;
        flit_valid_out  : out    vl_logic;
        flit_head_out   : out    vl_logic;
        flit_head_out_ivc: out    vl_logic_vector;
        flit_tail_out   : out    vl_logic;
        flit_tail_out_ivc: out    vl_logic_vector;
        flit_data_out   : out    vl_logic_vector;
        flit_sel_out_ivc: out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_vcs : constant is 1;
    attribute mti_svvh_generic_type of packet_format : constant is 1;
    attribute mti_svvh_generic_type of max_payload_length : constant is 1;
    attribute mti_svvh_generic_type of min_payload_length : constant is 1;
    attribute mti_svvh_generic_type of route_info_width : constant is 1;
    attribute mti_svvh_generic_type of enable_link_pm : constant is 1;
    attribute mti_svvh_generic_type of flit_data_width : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end rtr_channel_input;
