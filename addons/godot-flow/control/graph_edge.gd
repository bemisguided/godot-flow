class_name GraphEdge

# Constants =======================================================================================

const Drawing = preload("res://addons/godot-flow/util/drawing.gd")
const Geometry = preload("res://addons/godot-flow/util/geometry.gd")
const GraphVertex = preload("res://addons/godot-flow/control/graph_vertex.gd")

# Signals =========================================================================================

signal edge_hovered(edge: GraphEdge)
signal edge_selected(edge: GraphEdge)

# Properties ======================================================================================

var __control: GraphView
var __out_port: GraphPort
var __from_vertex: GraphVertex
var __hovered := false
var __metadata: Dictionary = {}
var __is_selected := false
var __in_port: GraphPort
var __to_vertex: GraphVertex

# Constructors ====================================================================================

func _init(control: GraphView, from_vertex: GraphVertex, out_port: GraphPort, to_vertex: GraphVertex, in_port: GraphPort):
    __control = control
    __from_vertex = from_vertex
    __out_port = out_port
    __to_vertex = to_vertex
    __in_port = in_port

# Internal Methods ================================================================================

func __draw() -> void:
    var canvas = __control
    var zoom_factor = __control.__get_zoom_factor()
    var origin = __control.__get_pan_offset()
    var color = canvas.get_theme_color("edge_color", "GraphView")
    if __is_selected:
        color = canvas.get_theme_color("edge_color_selected", "GraphView")
    elif __hovered:
        color = canvas.get_theme_color("edge_color_hover", "GraphView")
    var out_pos = (__out_port.get_global_position() - origin) * zoom_factor
    var in_pos = (__in_port.get_global_position() - origin) * zoom_factor
    var bezier = Geometry.get_bezier_points(out_pos, in_pos)
    var thickness = 2 * zoom_factor
    Drawing.draw_cubic_bezier(canvas, bezier[0], bezier[1], bezier[2], bezier[3], color, thickness)
    Drawing.draw_connection_arrow(canvas, bezier[0], bezier[1], bezier[2], bezier[3], color, zoom_factor)

func __is_hovered() -> bool:
    return __hovered
    
func __is_mouse_hover(mouse_pos: Vector2) -> bool:
    var zoom_factor = __control.__get_zoom_factor()
    var origin = __control.__get_pan_offset()
    var out_pos = (__out_port.get_global_position() - origin) * zoom_factor
    var in_pos = (__in_port.get_global_position() - origin) * zoom_factor
    var bezier = Geometry.get_bezier_points(out_pos, in_pos)
    var arrow = Geometry.get_arrow_triangle(bezier[0], bezier[1], bezier[2], bezier[3], 28.0 * zoom_factor, 18.0 * zoom_factor)
    return Geometry.is_point_in_triangle(mouse_pos, arrow[0], arrow[1], arrow[2])

func __set_hover(value: bool) -> void:
    __hovered = value
    if value:
        emit_signal("edge_hovered", self)

func __unselect() -> void:
    if not __is_selected:
        return
    __is_selected = false

# Public Methods ==================================================================================

func get_metadata(name: String) -> Variant:
    return __metadata[name]

func is_selected() -> bool:
    return __is_selected

func set_metadata(name: String, value: Variant) -> void:
    __metadata[name] = value
    emit_signal("edge_updated", self)

func select() -> void:
    if __is_selected:
        return
    __is_selected = true
    emit_signal("edge_selected", self)
