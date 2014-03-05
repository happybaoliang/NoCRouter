library verilog;
use verilog.vl_types.all;
entity rtr_channel_output is
    generic(
        num_vcs         : integer := 4;
        packet_format   : integer := 2;
        enable_link_pm  : integer := 1;
        flit_data_width : integer := 64;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active          : in     vl_logic;
        flit_valid_in   : in     vl_logic;
        flit_head_in    : in     vl_logic;
        flit_tail_in    : in     vl_logic;
        flit_data_in    : in     vl_logic_vector;
        flit_sel_in_ovc : in     vl_logic_vector;
        channel_out     : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_vcs : constant is 1;
    attribute mti_svvh_generic_type of packet_format : constant is 1;
    attribute mti_svvh_generic_type of enable_link_pm : constant is 1;
    attribute mti_svvh_generic_type of flit_data_width : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end rtr_channel_output;
