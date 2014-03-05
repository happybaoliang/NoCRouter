library verilog;
use verilog.vl_types.all;
entity c_fbgen is
    generic(
        width           : integer := 32;
        index           : integer := 0
    );
    port(
        feedback        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of index : constant is 1;
end c_fbgen;
