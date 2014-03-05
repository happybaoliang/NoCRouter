library verilog;
use verilog.vl_types.all;
entity rtr_flags_mux is
    generic(
        num_message_classes: integer := 2;
        num_resource_classes: integer := 2;
        num_ports       : integer := 5;
        width           : integer := 1
    );
    port(
        sel_mc          : in     vl_logic_vector;
        route_op        : in     vl_logic_vector;
        route_orc       : in     vl_logic_vector;
        flags_op_opc    : in     vl_logic_vector;
        flags           : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_message_classes : constant is 1;
    attribute mti_svvh_generic_type of num_resource_classes : constant is 1;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of width : constant is 1;
end rtr_flags_mux;
