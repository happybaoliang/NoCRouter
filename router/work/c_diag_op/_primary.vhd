library verilog;
use verilog.vl_types.all;
entity c_diag_op is
    generic(
        width           : integer := 1;
        op              : integer := 4
    );
    port(
        data_in         : in     vl_logic_vector;
        data_out        : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of op : constant is 1;
end c_diag_op;
