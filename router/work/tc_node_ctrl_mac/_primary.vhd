library verilog;
use verilog.vl_types.all;
entity tc_node_ctrl_mac is
    generic(
        cfg_node_addr_width: integer := 10;
        cfg_reg_addr_width: integer := 6;
        num_cfg_node_addrs: integer := 2;
        cfg_data_width  : integer := 32;
        done_delay_width: integer := 6;
        node_ctrl_width : integer := 2;
        node_status_width: integer := 1;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        io_write        : in     vl_logic;
        io_read         : in     vl_logic;
        io_addr         : in     vl_logic_vector;
        io_write_data   : in     vl_logic_vector;
        io_read_data    : out    vl_logic_vector;
        io_done         : out    vl_logic;
        cfg_node_addrs  : in     vl_logic_vector;
        cfg_req         : out    vl_logic;
        cfg_write       : out    vl_logic;
        cfg_addr        : out    vl_logic_vector;
        cfg_write_data  : out    vl_logic_vector;
        cfg_read_data   : in     vl_logic_vector;
        cfg_done        : in     vl_logic;
        node_ctrl       : out    vl_logic_vector;
        node_status     : in     vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of cfg_node_addr_width : constant is 1;
    attribute mti_svvh_generic_type of cfg_reg_addr_width : constant is 1;
    attribute mti_svvh_generic_type of num_cfg_node_addrs : constant is 1;
    attribute mti_svvh_generic_type of cfg_data_width : constant is 1;
    attribute mti_svvh_generic_type of done_delay_width : constant is 1;
    attribute mti_svvh_generic_type of node_ctrl_width : constant is 1;
    attribute mti_svvh_generic_type of node_status_width : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end tc_node_ctrl_mac;
