library verilog;
use verilog.vl_types.all;
entity c_fifo_tracker is
    generic(
        depth           : integer := 8;
        fast_almost_empty: integer := 0;
        fast_two_free   : integer := 0;
        enable_bypass   : integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active          : in     vl_logic;
        push            : in     vl_logic;
        pop             : in     vl_logic;
        almost_empty    : out    vl_logic;
        empty           : out    vl_logic;
        almost_full     : out    vl_logic;
        full            : out    vl_logic;
        two_free        : out    vl_logic;
        errors          : out    vl_logic_vector(0 to 1)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of depth : constant is 1;
    attribute mti_svvh_generic_type of fast_almost_empty : constant is 1;
    attribute mti_svvh_generic_type of fast_two_free : constant is 1;
    attribute mti_svvh_generic_type of enable_bypass : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end c_fifo_tracker;
