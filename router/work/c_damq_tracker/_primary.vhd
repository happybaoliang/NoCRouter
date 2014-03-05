library verilog;
use verilog.vl_types.all;
entity c_damq_tracker is
    generic(
        num_queues      : integer := 4;
        num_slots       : integer := 32;
        fast_almost_empty: integer := 0;
        fast_two_free   : integer := 0;
        enable_bypass   : integer := 0;
        enable_reservations: integer := 0;
        reset_type      : integer := 0
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        active          : in     vl_logic;
        push_valid      : in     vl_logic;
        push_sel_qu     : in     vl_logic_vector;
        pop_valid       : in     vl_logic;
        pop_sel_qu      : in     vl_logic_vector;
        almost_empty_qu : out    vl_logic_vector;
        empty_qu        : out    vl_logic_vector;
        almost_full_qu  : out    vl_logic_vector;
        full_qu         : out    vl_logic_vector;
        two_free_qu     : out    vl_logic_vector;
        errors_qu       : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_queues : constant is 1;
    attribute mti_svvh_generic_type of num_slots : constant is 1;
    attribute mti_svvh_generic_type of fast_almost_empty : constant is 1;
    attribute mti_svvh_generic_type of fast_two_free : constant is 1;
    attribute mti_svvh_generic_type of enable_bypass : constant is 1;
    attribute mti_svvh_generic_type of enable_reservations : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end c_damq_tracker;
