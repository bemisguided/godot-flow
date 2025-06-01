@tool
extends Control

var __graph_view: GraphView = null
var __vertex1: GraphVertex = null
var __vertex2: GraphVertex = null
var __edge: GraphEdge = null

# Example parameters for the port shape
var port_position = Vector2(200, 200)
var port_radius = 40.0
var port_angle = 0.0 # Facing right
var port_rect_extension = 20.0

func _enter_tree() -> void:
    __graph_view = get_node("VBoxContainer/GraphView")

func _ready() -> void:
    __vertex1 = __graph_view.add_vertex(Vector2(100, 100), "Vertex 1")
    __vertex2 = __graph_view.add_vertex(Vector2(200, 200), "Vertex 2")
    var __vertex3 = __graph_view.add_vertex(Vector2(300, 300), "Vertex 3")
    var vertex1_port = __vertex1.add_port(GraphPort.Side.RIGHT, GraphPort.Direction.FROM)
    var vertex2_port = __vertex2.add_port(GraphPort.Side.LEFT, GraphPort.Direction.TO)
    __vertex3.add_port(GraphPort.Side.TOP, GraphPort.Direction.ANY)
    __vertex2.add_port(GraphPort.Side.RIGHT, GraphPort.Direction.FROM)
    var vertex3_port = __vertex3.add_port(GraphPort.Side.LEFT, GraphPort.Direction.TO)
    __edge = __graph_view.add_edge(__vertex1, vertex1_port, __vertex2, vertex2_port)

func _exit_tree() -> void:
    __graph_view.remove_edge(__edge)
    __graph_view.remove_vertex(__vertex1)
    __graph_view.remove_vertex(__vertex2)
    __graph_view = null
    __vertex1 = null
    __vertex2 = null
    __edge = null
