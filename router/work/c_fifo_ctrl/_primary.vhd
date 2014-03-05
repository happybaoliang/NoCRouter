library verilog;
use verilog.vl_types.all;
entity c_fifo_ctrl is
    generic(
        depth           : integer := 8;
        extra_addr_width: integer := 0;
        offset          : integer := 0;
        fast_almost_empty: integer := 0;
        enable_bypass   : integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        push_active     : in     vl_logic;
        pop_active      : in     vl_logic;
        push            : in     vl_logic;
        pop             : in     vl_logic;
        push_addr       : out    vl_logic_vector;
        pop_addr        : out    vl_logic_vector;
        almost_empty    : out    vl_logic;
        empty           : out    vl_logic;
        full            : out    vl_logic;
        errors          : out    vl_logic_vector(0 to 1)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of depth : constant is 1;
    attribute mti_svvh_generic_type of extra_addr_width : constant is 1;
    attribute mti_svvh_generic_type of offset : constant is 1;
    attribute mti_svvh_generic_type of fast_almost_empty : constant is 1;
    attribute mti_svvh_generic_type of enable_bypass : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end c_fifo_ctrl;
