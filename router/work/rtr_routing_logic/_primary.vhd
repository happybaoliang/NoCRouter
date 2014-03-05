library verilog;
use verilog.vl_types.all;
entity rtr_routing_logic is
    generic(
        num_message_classes: integer := 2;
        num_resource_classes: integer := 2;
        num_routers_per_dim: integer := 4;
        num_dimensions  : integer := 2;
        num_nodes_per_router: integer := 1;
        connectivity    : integer := 0;
        routing_type    : integer := 0;
        dim_order       : integer := 0;
        reset_type      : integer := 0
    );
    port(
        router_address  : in     vl_logic_vector;
        sel_mc          : in     vl_logic_vector;
        sel_irc         : in     vl_logic_vector;
        dest_info       : in     vl_logic_vector;
        route_op        : out    vl_logic_vector;
        route_orc       : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of num_message_classes : constant is 1;
    attribute mti_svvh_generic_type of num_resource_classes : constant is 1;
    attribute mti_svvh_generic_type of num_routers_per_dim : constant is 1;
    attribute mti_svvh_generic_type of num_dimensions : constant is 1;
    attribute mti_svvh_generic_type of num_nodes_per_router : constant is 1;
    attribute mti_svvh_generic_type of connectivity : constant is 1;
    attribute mti_svvh_generic_type of routing_type : constant is 1;
    attribute mti_svvh_generic_type of dim_order : constant is 1;
    attribute mti_svvh_generic_type of reset_type : constant is 1;
end rtr_routing_logic;
