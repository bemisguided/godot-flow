@tool
extends Control

# Properties ======================================================================================

var __graph_view: GraphView = null
var __vertex1: GraphVertex = null
var __vertex2: GraphVertex = null
var __edge: GraphEdge = null

# Internal Methods ================================================================================

func __port_template(vertex: GraphVertex):
    vertex.add_port(GraphPort.Side.BOTTOM, GraphPort.Direction.OUT)
    vertex.add_port(GraphPort.Side.TOP, GraphPort.Direction.IN)

# Lifecycle =======================================================================================

func _enter_tree() -> void:
    __graph_view = get_node("GraphView")

func _exit_tree() -> void:
    __graph_view.remove_edge(__edge)
    __graph_view.remove_vertex(__vertex1)
    __graph_view.remove_vertex(__vertex2)
    __graph_view = null
    __vertex1 = null
    __vertex2 = null
    __edge = null

func _ready() -> void:
    __graph_view.set_port_template(Callable(self, "__port_template"))
    __vertex1 = __graph_view.add_vertex(Vector2(100, 100), "Vertex 1")
    __vertex2 = __graph_view.add_vertex(Vector2(200, 200), "Vertex 2")
    __graph_view.add_vertex(Vector2(300, 300), "Vertex 3")

    var out_port = __vertex1.get_ports_by_side(GraphPort.Side.BOTTOM)[0]
    var in_port = __vertex2.get_ports_by_side(GraphPort.Side.TOP)[0]
    __edge = __graph_view.add_edge(__vertex1, out_port, __vertex2, in_port)
