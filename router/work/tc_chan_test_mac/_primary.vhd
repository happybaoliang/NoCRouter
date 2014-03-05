library verilog;
use verilog.vl_types.all;
entity tc_chan_test_mac is
    generic(
        cfg_node_addr_width: integer := 10;
        cfg_reg_addr_width: integer := 6;
        num_cfg_node_addrs: integer := 2;
        cfg_data_width  : integer := 32;
        lfsr_index      : integer := 0;
        lfsr_width      : integer := 16;
        channel_width   : integer := 16;
        test_duration_width: integer := 32;
        warmup_duration_width: integer := 32;
        cal_interval_width: integer := 16;
        cal_duration_width: integer := 8;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        cfg_node_addrs  : in     vl_logic_vector;
        cfg_req         : in     vl_logic;
        cfg_write       : in     vl_logic;
        cfg_addr        : in     vl_logic_vector;
        cfg_write_data  : in     vl_logic_vector;
        cfg_read_data   : out    vl_logic_vector;
        cfg_done        : out    vl_logic;
        xmit_cal        : out    vl_logic;
        xmit_data       : out    vl_logic_vector;
        recv_cal        : out    vl_logic;
        recv_data       : in     vl_logic_vector;
        error           : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of cfg_node_addr_width : constant is 1;
    attribute mti_svvh_generic_type of cfg_reg_addr_width : constant is 1;
    attribute mti_svvh_generic_type of num_cfg_node_addrs : constant is 1;
    attribute mti_svvh_generic_type of cfg_data_width : constant is 1;
    attribute mti_svvh_generic_type of lfsr_index : constant is 1;
    attribute mti_svvh_generic_type of lfsr_width : constant is 1;
    attribute mti_svvh_generic_type of channel_width : constant is 1;
    attribute mti_svvh_generic_type of test_duration_width : constant is 1;
    attribute mti_svvh_generic_type of warmup_duration_width : constant is 1;
    attribute mti_svvh_generic_type of cal_interval_width : constant is 1;
    attribute mti_svvh_generic_type of cal_duration_width : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end tc_chan_test_mac;
