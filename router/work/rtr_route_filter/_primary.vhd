library verilog;
use verilog.vl_types.all;
entity rtr_route_filter is
    generic(
        num_message_classes: integer := 2;
        num_resource_classes: integer := 2;
        num_vcs_per_class: integer := 1;
        num_ports       : integer := 5;
        num_neighbors_per_dim: integer := 2;
        num_nodes_per_router: integer := 4;
        restrict_turns  : integer := 1;
        connectivity    : integer := 0;
        routing_type    : integer := 0;
        dim_order       : integer := 0;
        port_id         : integer := 0;
        vc_id           : integer := 0
    );
    port(
        clk             : in     vl_logic;
        route_valid     : in     vl_logic;
        route_in_op     : in     vl_logic_vector;
        route_in_orc    : in     vl_logic_vector;
        route_out_op    : out    vl_logic_vector;
        route_out_orc   : out    vl_logic_vector;
        errors          : out    vl_logic_vector(0 to 1)
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_message_classes : constant is 1;
    attribute mti_svvh_generic_type of num_resource_classes : constant is 1;
    attribute mti_svvh_generic_type of num_vcs_per_class : constant is 1;
    attribute mti_svvh_generic_type of num_ports : constant is 1;
    attribute mti_svvh_generic_type of num_neighbors_per_dim : constant is 1;
    attribute mti_svvh_generic_type of num_nodes_per_router : constant is 1;
    attribute mti_svvh_generic_type of restrict_turns : constant is 1;
    attribute mti_svvh_generic_type of connectivity : constant is 1;
    attribute mti_svvh_generic_type of routing_type : constant is 1;
    attribute mti_svvh_generic_type of dim_order : constant is 1;
    attribute mti_svvh_generic_type of port_id : constant is 1;
    attribute mti_svvh_generic_type of vc_id : constant is 1;
end rtr_route_filter;
