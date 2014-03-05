library verilog;
use verilog.vl_types.all;
entity tc_cfg_bus_ifc is
    generic(
        cfg_node_addr_width: integer := 10;
        cfg_reg_addr_width: integer := 6;
        num_cfg_node_addrs: integer := 2;
        cfg_data_width  : integer := 32;
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
        active          : out    vl_logic;
        req             : out    vl_logic;
        write           : out    vl_logic;
        node_addr_match : out    vl_logic_vector;
        reg_addr        : out    vl_logic_vector;
        write_data      : out    vl_logic_vector;
        read_data       : in     vl_logic_vector;
        done            : in     vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of cfg_node_addr_width : constant is 1;
    attribute mti_svvh_generic_type of cfg_reg_addr_width : constant is 1;
    attribute mti_svvh_generic_type of num_cfg_node_addrs : constant is 1;
    attribute mti_svvh_generic_type of cfg_data_width : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end tc_cfg_bus_ifc;
