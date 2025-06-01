class_name GraphPort
extends RefCounted

# Constants =======================================================================================

const RADIUS := 4
const RECT_EXTENSION := RADIUS * 0.75

# Classes =========================================================================================
class Connection:
    var edge: GraphEdge
    var index: int
    func _init(_edge: GraphEdge, _index: int):
        edge = _edge
        index = _index

# Enums ===========================================================================================

enum Direction {
    BOTH,
    OUT,
    IN
}

enum Side {
    TOP,
    LEFT,
    RIGHT,
    BOTTOM
}

# Signals =========================================================================================

signal port_connected(connection: Connection)
signal port_disconnected(connection: Connection)
signal port_hovered(port: GraphPort)
signal port_updated(port: GraphPort)

# Properties ======================================================================================

var __control: GraphView
var __connection: Connection = null
var __direction: Direction
var __hovered := false
var __position: Vector2
var __side: Side
var __vertex: GraphVertex

# Constructors ====================================================================================

func _init(control: GraphView, vertex: GraphVertex, position: Vector2, direction: Direction, side: Side):
    __control = control
    __vertex = vertex
    __position = position
    __direction = direction
    __side = side

# Internal Methods ================================================================================

func __get_port_shape_path() -> PackedVector2Array:
    var world_pos = get_global_position()
    var radius = RADIUS
    var rect_ext = (RECT_EXTENSION) if RECT_EXTENSION >= 0 else (radius * 0.5)
    var angle = __get_angle_for_side()
    match __direction:
        Direction.OUT:
            return Geometry.get_port_half_circle_with_rect_path(world_pos, radius, angle, rect_ext)
        Direction.IN:
            return Geometry.get_port_half_circle_with_rect_path(world_pos, radius, angle + PI, rect_ext)
    return PackedVector2Array()

func __draw() -> void:
    var canvas = __control
    var zoom = __vertex.__control.__get_zoom_factor()
    var origin = __vertex.__control.__get_pan_offset()
    var color = canvas.get_theme_color("port_color", "GraphView")
    if __hovered:
        color = canvas.get_theme_color("port_color_hover", "GraphView")
    var path = __get_port_shape_path()
    match __direction:
        Direction.BOTH:
            var world_pos = get_global_position()
            Drawing.draw_port_circle(canvas, (world_pos - origin) * zoom, RADIUS * zoom, color)
        Direction.OUT, Direction.IN:
            if path:
                var screen_path = Geometry.transform_path_to_screen(path, origin, zoom)
                Drawing.draw_polygon(canvas, screen_path, color)

func __get_angle_for_side() -> float:
    match __side:
        Side.RIGHT: return PI / 2
        Side.LEFT: return -PI / 2
        Side.TOP: return 0
        Side.BOTTOM: return PI
        _: return 0

func __is_hovered() -> bool:
    return __hovered

func __is_mouse_hover(pos: Vector2) -> bool:
    var zoom = __vertex.__control.__get_zoom_factor()
    var origin = __vertex.__control.__get_pan_offset()
    var world_mouse_pos = (pos / zoom) + origin
    match __direction:
        Direction.BOTH:
            var world_pos = get_global_position()
            return Geometry.is_point_in_port_circle(world_mouse_pos, world_pos, RADIUS)
        Direction.OUT, Direction.IN:
            var path = __get_port_shape_path()
            if path:
                return Geometry2D.is_point_in_polygon(world_mouse_pos, path)
    return false

func __set_hover(value: bool) -> void:
    __hovered = value
    if value:
        emit_signal("port_hovered", self)

# Public Methods ==================================================================================

func allows_direction(direction: Direction) -> bool:
    return __direction == Direction.BOTH or __direction == direction

func get_connection() -> Connection:
    return __connection

func get_direction() -> Direction:
    return __direction

func get_global_position() -> Vector2:
    return __vertex.get_global_position() + __position

func get_side() -> Side:
    return __side

func get_vertex() -> GraphVertex:
    return __vertex

func has_connection() -> bool:
    return __connection != null

func set_connection(edge: GraphEdge, index: int) -> void:
    if __connection:
        emit_signal("port_disconnected", __connection)
    __connection = Connection.new(edge, index)
    emit_signal("port_connected", __connection)

func set_direction(direction: Direction) -> void:
    __direction = direction
    emit_signal("port_updated", self)

func set_side(side: Side) -> void:
    __side = side
    emit_signal("port_updated", self)
