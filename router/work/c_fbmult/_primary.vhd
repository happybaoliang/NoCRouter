library verilog;
use verilog.vl_types.all;
entity c_fbmult is
    generic(
        width           : integer := 32;
        iterations      : integer := 1
    );
    port(
        feedback        : in     vl_logic_vector;
        complete        : in     vl_logic;
        data_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of iterations : constant is 1;
end c_fbmult;
