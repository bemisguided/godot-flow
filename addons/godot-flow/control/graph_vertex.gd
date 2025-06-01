class_name GraphVertex

# Signals =========================================================================================

signal vertex_hovered(vertex: GraphVertex)
signal vertex_port_added(port: GraphPort)
signal vertex_port_hovered(port: GraphPort)
signal vertex_port_removed(port: GraphPort)
signal vertex_selected(vertex: GraphVertex)
signal vertex_updated(vertex: GraphVertex)

# Constants =======================================================================================

const FIXED_HEIGHT := 60
const SNAP_WIDTH := 20
const LABEL_FONT_SIZE := 16
const LABEL_PADDING := 48
const MIN_WIDTH := 120

# Properties ======================================================================================

var __control: GraphView
var __hovered := false
var __is_selected := false
var __label := ""
var __metadata: Dictionary = {}
var __ports: Array[GraphPort] = []
var __position := Vector2.ZERO

# Constructors ====================================================================================

func _init(control: GraphView, position: Vector2, label: String):
    __control = control
    __position = position
    __label = label

# Internal Methods ================================================================================

func __calc_box_size() -> Vector2:
    var label_width = __calc_label_size().x
    var padding = LABEL_PADDING
    var width = max(MIN_WIDTH, label_width + padding)
    width = ceil(width / SNAP_WIDTH) * SNAP_WIDTH
    var height = FIXED_HEIGHT
    return Vector2(width, height)

func __calc_font_size() -> int:
    return LABEL_FONT_SIZE

func __calc_label_size() -> Vector2:
    var font = __theme_font()
    var font_size = __calc_font_size()
    return font.get_string_size(__label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

func __draw() -> void:
    __draw_vertex_box()
    __draw_vertex_label()

func __draw_vertex_box() -> void:
    var canvas = __control
    var bg_color = __theme_background_color()
    var border_color = __theme_border_color()
    var zoom_factor = __control.__get_zoom_factor()
    var origin = __control.__get_pan_offset()
    var screen_pos = (get_position() - origin) * zoom_factor
    var screen_size = __calc_box_size() * zoom_factor
    var rect = Rect2(screen_pos, screen_size)
    canvas.draw_rect(rect, bg_color)
    canvas.draw_rect(rect, border_color, false, 2 * zoom_factor)

func __draw_vertex_ports() -> void:
    for port in __ports:
        port.__draw()

func __draw_vertex_label() -> void:
    var canvas = __control
    var zoom_factor = __control.__get_zoom_factor()
    var origin = __control.__get_pan_offset()
    var label_font = __theme_font()
    var label_color = __theme_label_color()
    var font_size = int(LABEL_FONT_SIZE * zoom_factor)
    var label_size = label_font.get_string_size(__label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
    var label_ascent_size = label_font.get_ascent(font_size)
    var screen_pos = (get_position() - origin) * zoom_factor
    var screen_size = __calc_box_size() * zoom_factor
    var label_position = screen_pos + Vector2((screen_size.x - label_size.x) / 2, (screen_size.y - label_size.y) / 2 + label_ascent_size)
    canvas.draw_string(label_font, label_position, __label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, label_color)

func __is_hovered() -> bool:
    return __hovered

func __is_mouse_hover(mouse_pos: Vector2) -> bool:
    var zoom_factor = __control.__get_zoom_factor()
    var origin = __control.__get_pan_offset()
    var screen_pos = (get_position() - origin) * zoom_factor
    var screen_size = __calc_box_size() * zoom_factor
    if Rect2(screen_pos, screen_size).has_point(mouse_pos):
        return true
    for port in __ports:
        if port.__is_mouse_hover(mouse_pos):
            return true
    return false

func __layout_ports():
    var size = __calc_box_size()
    for side in [GraphPort.Side.LEFT, GraphPort.Side.RIGHT, GraphPort.Side.TOP, GraphPort.Side.BOTTOM]:
        var side_ports = get_ports_by_side(side)
        var count = side_ports.size()
        for i in range(count):
            match side:
                GraphPort.Side.LEFT:
                    side_ports[i].__position = Vector2(0, size.y * (i + 1) / (count + 1))
                GraphPort.Side.RIGHT:
                    side_ports[i].__position = Vector2(size.x, size.y * (i + 1) / (count + 1))
                GraphPort.Side.TOP:
                    side_ports[i].__position = Vector2(size.x * (i + 1) / (count + 1), 0)
                GraphPort.Side.BOTTOM:
                    side_ports[i].__position = Vector2(size.x * (i + 1) / (count + 1), size.y)

func __on_port_hovered(port: GraphPort):
    emit_signal("vertex_port_hovered", port)
    
func __on_port_updated(port: GraphPort):
    __layout_ports()

func __theme_background_color() -> Color:
    if __hovered:
        return __control.get_theme_color("vertex_background_color_hover", "GraphView")
    if __is_selected:
        return __control.get_theme_color("vertex_background_color_selected", "GraphView")
    return __control.get_theme_color("vertex_background_color", "GraphView")

func __theme_border_color() -> Color:
    if __hovered:
        return __control.get_theme_color("vertex_border_color_hover", "GraphView")
    if __is_selected:
        return __control.get_theme_color("vertex_border_color_selected", "GraphView")
    return __control.get_theme_color("vertex_border_color", "GraphView")

func __theme_font() -> Font:
    return __control.get_theme_font("vertex_label", "GraphView")

func __theme_label_color() -> Color:
    if __hovered:
        return __control.get_theme_color("vertex_label_color_hover", "GraphView")
    if __is_selected:
        return __control.get_theme_color("vertex_label_color_selected", "GraphView")
    return __control.get_theme_color("vertex_label_color", "GraphView")

func __set_hover(value: bool) -> void:
    __hovered = value
    if value:
        emit_signal("vertex_hovered", self)

func __unselect() -> void:
    if not __is_selected:
        return
    __is_selected = false

# Public Methods ==================================================================================

func add_port(side: int, direction: GraphPort.Direction = GraphPort.Direction.BOTH) -> GraphPort:
    var port = GraphPort.new(__control, self, Vector2.ZERO, direction, side)
    __ports.append(port)
    port.port_updated.connect(__on_port_updated)
    __layout_ports()
    emit_signal("vertex_port_added", port)
    return port

# func find_closest_port(point: Vector2, direction: GraphPort.Direction) -> GraphPort:
#     var closest_port = null
#     var closest_distance = INF
#     for port in __ports:
#         if not port.allows_direction(direction):
#             continue
#         var distance = port.get_global_position().distance_to(point)
#         if distance < closest_distance:
#             closest_distance = distance
#             closest_port = port
#     return closest_port

func get_bounds(size: Vector2) -> Rect2:
    return Rect2(get_position(), size)

func get_global_position() -> Vector2:
    return __position

func get_label() -> String:
    return __label

func get_metadata(name: String) -> Variant:
    return __metadata[name]

func get_port(index: int) -> GraphPort:
    return __ports[index]

func get_ports() -> Array:
    return __ports

func get_ports_by_side(side: int) -> Array:
    return __ports.filter(func(p): return p.get_side() == side)

func get_position() -> Vector2:
    return __position

func set_position(value: Vector2) -> void:
    __position = value

func is_selected() -> bool:
    return __is_selected

func remove_port(port: GraphPort):
    __ports.erase(port)
    port.port_updated.disconnect(__on_port_updated)
    __layout_ports()
    emit_signal("vertex_port_removed", port)

func set_label(value: String) -> void:
    __label = value
    __layout_ports()
    emit_signal("vertex_updated", self)

func set_metadata(name: String, value: Variant) -> void:
    __metadata[name] = value
    emit_signal("vertex_updated", self)

func select() -> void:
    if __is_selected:
        return
    __is_selected = true
    emit_signal("vertex_selected", self)
