library verilog;
use verilog.vl_types.all;
entity c_mat_mult is
    generic(
        dim1_width      : integer := 1;
        dim2_width      : integer := 1;
        dim3_width      : integer := 1;
        prod_op         : integer := 0;
        sum_op          : integer := 4
    );
    port(
        input_a         : in     vl_logic_vector;
        input_b         : in     vl_logic_vector;
        result          : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of dim1_width : constant is 1;
    attribute mti_svvh_generic_type of dim2_width : constant is 1;
    attribute mti_svvh_generic_type of dim3_width : constant is 1;
    attribute mti_svvh_generic_type of prod_op : constant is 1;
    attribute mti_svvh_generic_type of sum_op : constant is 1;
end c_mat_mult;
