@tool
class_name GraphView
extends Control

# Constants =======================================================================================
const Drawing = preload("res://addons/godot-flow/util/drawing.gd")
const Geometry = preload("res://addons/godot-flow/util/geometry.gd")
const GraphEdge = preload("res://addons/godot-flow/control/graph_edge.gd")
const GraphPort = preload("res://addons/godot-flow/control/graph_port.gd")
const GraphVertex = preload("res://addons/godot-flow/control/graph_vertex.gd")
const InputController = preload("res://addons/godot-flow/control/input_controller.gd")
const GRID_SIZE := 20
const ZOOM_MIN := 1.0
const ZOOM_MAX := 4.0

# Signals =========================================================================================

signal edge_connected(edge)
signal edge_disconnected(edge)
signal edge_selected(edge)
signal edge_unselected(edge)
signal vertex_added(vertex)
signal vertex_removed(vertex)
signal vertex_selected(vertex)

# Properties ======================================================================================

var __arrow_hit_edge: GraphEdge = null
var __edges: Array[GraphEdge] = []
var __edge_drag_in_progress: bool = false
var __edge_drag_start_port: GraphPort = null
var __input_controller: InputController = null
var __vertices: Array[GraphVertex] = []
var __vertex_drag_offset: Vector2 = Vector2.ZERO
var __zoom_factor: float = 1.0
var __pan_offset: Vector2 = Vector2.ZERO
var __pan_drag_start_offset: Vector2 = Vector2.ZERO
var __pan_drag_start_mouse: Vector2 = Vector2.ZERO
var __port_template: Callable = Callable(self, "__default_port_template")

# Internal Methods ================================================================================

func __default_port_template(vertex: GraphVertex):
    pass

func __draw_edge_preview():
    # Show a preview edge when dragging from a port
    if __edge_drag_in_progress and __edge_drag_start_port != null:
        var from_pos = (__edge_drag_start_port.get_global_position() - __pan_offset) * __zoom_factor
        var to_pos = __input_controller.get_mouse_position()
        var bezier = Geometry.get_bezier_points(from_pos, to_pos)
        var color = get_theme_color("edge_color_preview", "GraphView")
        var thickness = 2 * __zoom_factor
        Drawing.draw_cubic_bezier(self, bezier[0], bezier[1], bezier[2], bezier[3], color, thickness)
        Drawing.draw_connection_arrow(self, bezier[0], bezier[1], bezier[2], bezier[3], color, __zoom_factor)

func __draw_edges():
    for edge in __edges:
        edge.__draw()

func __draw_vertices():
    for vertex in __vertices:
        vertex.__draw()

func __draw_vertex_ports():
    for vertex in __vertices:
        vertex.__draw_vertex_ports()

func __get_hovered_edges(ignore_edge: GraphEdge = null) -> Array[GraphEdge]:
    var hovered_edges: Array[GraphEdge] = []
    for edge in __edges:
        if edge.__is_hovered() and edge != ignore_edge:
            hovered_edges.append(edge)
    return hovered_edges

func __get_hovered_ports(ignore_port: GraphPort = null) -> Array[GraphPort]:
    var hovered_ports: Array[GraphPort] = []
    for vertex in __vertices:
        for port in vertex.get_ports():
            if port.__is_hovered() and port != ignore_port:
                hovered_ports.append(port)
    return hovered_ports

func __get_hovered_vertices(ignore_vertex: GraphVertex = null) -> Array[GraphVertex]:
    var hovered_vertices: Array[GraphVertex] = []
    for vertex in __vertices:
        if vertex.__is_hovered() and vertex != ignore_vertex:
            hovered_vertices.append(vertex)
    return hovered_vertices

func __get_pan_offset() -> Vector2:
    return __pan_offset

func __get_selected_edges(ignore_edge: GraphEdge = null) -> Array[GraphEdge]:
    var selected_edges: Array[GraphEdge] = []
    for edge in __edges:
        if edge.is_selected() and edge != ignore_edge:
            selected_edges.append(edge)
    return selected_edges

func __get_selected_vertices(ignore_vertex: GraphVertex = null) -> Array[GraphVertex]:
    var selected_vertices: Array[GraphVertex] = []
    for vertex in __vertices:
        if vertex.is_selected() and vertex != ignore_vertex:
            selected_vertices.append(vertex)
    return selected_vertices

func __get_zoom_factor() -> float:
    return __zoom_factor

func __hover_clear(ignore_edge: GraphEdge = null, ignore_port: GraphPort = null, ignore_vertex: GraphVertex = null):
    var hovered_edges = __get_hovered_edges(ignore_edge)
    for edge in hovered_edges:
        edge.__set_hover(false)
    var hovered_ports = __get_hovered_ports(ignore_port)
    for port in hovered_ports:
        port.__set_hover(false)
    var hovered_vertices = __get_hovered_vertices(ignore_vertex)
    for vertex in hovered_vertices:
        vertex.__set_hover(false)

func __on_edge_selected(edge: GraphEdge):
    __hover_clear()
    __selection_clear(edge)
    queue_redraw()
    emit_signal("edge_selected", edge)

func __on_edge_hovered(edge: GraphEdge):
    __hover_clear(edge)
    queue_redraw()

func __on_mouse_click(position, item):
    if item is GraphVertex:
        select_vertex(item)
    elif item is GraphEdge:
        select_edge(item)
    else:
        __hover_clear()
        __selection_clear()

func __on_mouse_double_click(position, item):
    pass

func __on_mouse_drag_start(position, item):
    if item is GraphPort:
        __edge_drag_in_progress = true
        __edge_drag_start_port = item
        queue_redraw()
    elif item is GraphVertex:
        var graph_pos = position / __zoom_factor
        __vertex_drag_offset = graph_pos - item.get_position()
        __edge_drag_in_progress = false
        __edge_drag_start_port = null
        queue_redraw()
    elif item == null:
        __pan_drag_start_offset = __pan_offset
        __pan_drag_start_mouse = position
    else:
        __edge_drag_in_progress = false
        __edge_drag_start_port = null
        queue_redraw()

func __on_mouse_drag(start_position, current_position, item):
    if __edge_drag_in_progress:
        # Just update preview; actual drawing uses __edge_drag_start_port and mouse position
        queue_redraw()
    elif item is GraphVertex:
        var graph_pos = current_position / __zoom_factor
        item.set_position(graph_pos - __vertex_drag_offset)
        queue_redraw()
    elif item == null:
        var delta = (current_position - __pan_drag_start_mouse) / __zoom_factor
        set_pan_offset(__pan_drag_start_offset - delta)
        queue_redraw()

func __on_mouse_drag_end(start_position, end_position, start_item, end_item):
    if __edge_drag_in_progress and end_item is GraphPort and end_item != __edge_drag_start_port:
        var from_vertex = __edge_drag_start_port.get_vertex()
        var to_vertex = end_item.get_vertex()
        add_edge(from_vertex, __edge_drag_start_port, to_vertex, end_item)
    __edge_drag_in_progress = false
    __edge_drag_start_port = null
    __pan_drag_start_offset = Vector2.ZERO
    __pan_drag_start_mouse = Vector2.ZERO
    queue_redraw()

func __on_mouse_hover_on(position, item):
    if item is GraphVertex:
        item.__set_hover(true)
        queue_redraw()
    elif item is GraphEdge:
        item.__set_hover(true)
        queue_redraw()
    elif item is GraphPort:
        item.__set_hover(true)
        queue_redraw()

func __on_mouse_hover_off(position, item):
    if item is GraphVertex:
        item.__set_hover(false)
        queue_redraw()
    elif item is GraphEdge:
        item.__set_hover(false)
        queue_redraw()
    elif item is GraphPort:
        item.__set_hover(false)
        queue_redraw()

func __on_mouse_wheel(delta, position):
    __zoom_factor = clamp(__zoom_factor + delta * 0.1, ZOOM_MIN, ZOOM_MAX)
    queue_redraw()

func __on_vertex_port_added(port: GraphPort):
    queue_redraw()

func __on_vertex_hovered(vertex: GraphVertex):
    __hover_clear(null, null, vertex)
    queue_redraw()

func __on_vertex_selected(vertex: GraphVertex):
    __selection_clear(null, vertex)
    queue_redraw()
    emit_signal("vertex_selected", vertex)

func __on_vertex_port_removed(port: GraphPort):
    queue_redraw()

func __resolve_item(position: Vector2):
    for vertex in __vertices:
        for port in vertex.get_ports():
            if port.__is_mouse_hover(position):
                return port
    for vertex in __vertices:
        if vertex.__is_mouse_hover(position):
            return vertex
    for edge in __edges:
        if edge.__is_mouse_hover(position):
            return edge
    return null

func __selection_clear(ignore_edge: GraphEdge = null, ignore_vertex: GraphVertex = null):
    var selected_edges = __get_selected_edges(ignore_edge)
    for edge in selected_edges:
        edge.__unselect()
    var selected_vertices = __get_selected_vertices(ignore_vertex)
    for vertex in selected_vertices:
        vertex.__unselect()

func __draw_background():
    var bg_color = get_theme_color("view_background_color", "GraphView")
    draw_rect(Rect2(Vector2.ZERO, size), bg_color)

func __draw_grid():
    var grid_color = get_theme_color("view_grid_color", "GraphView")
    var width = int(size.x)
    var height = int(size.y)
    var grid_size = int(GRID_SIZE * __zoom_factor)
    var offset = __pan_offset * __zoom_factor
    var x0 = int(fposmod(-offset.x, grid_size))
    var y0 = int(fposmod(-offset.y, grid_size))
    for x in range(x0, width, grid_size):
        draw_line(Vector2(x, 0), Vector2(x, height), grid_color, 1)
    for y in range(y0, height, grid_size):
        draw_line(Vector2(0, y), Vector2(width, y), grid_color, 1)

func __draw_border():
    var border_color = get_theme_color("view_border_color", "GraphView")
    draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 2)

# Methods =========================================================================================

func add_edge(from_vertex: GraphVertex, out_port: GraphPort, to_vertex: GraphVertex, in_port: GraphPort) -> GraphEdge:
    var edge = GraphEdge.new(self, from_vertex, out_port, to_vertex, in_port)
    edge.edge_selected.connect(Callable(self, "__on_edge_selected"))
    edge.edge_hovered.connect(Callable(self, "__on_edge_hovered"))
    __edges.append(edge)
    emit_signal("edge_connected", edge)
    return edge

func add_vertex(_position: Vector2, _title: String) -> GraphVertex:
    var vertex = GraphVertex.new(self, _position, _title)
    __port_template.call(vertex)
    vertex.vertex_selected.connect(Callable(self, "__on_vertex_selected"))
    vertex.vertex_hovered.connect(Callable(self, "__on_vertex_hovered"))
    __vertices.append(vertex)
    emit_signal("vertex_added", vertex)
    return vertex

func get_edges() -> Array[GraphEdge]:
    return __edges

func get_vertices() -> Array[GraphVertex]:
    return __vertices

func remove_edge(_edge: GraphEdge) -> void:
    __edges.erase(_edge)
    emit_signal("edge_disconnected", _edge)

func remove_vertex(_vertex: GraphVertex) -> void:
    __vertices.erase(_vertex)
    for edge in __edges.duplicate():
        if edge.from_vertex == _vertex or edge.to_vertex == _vertex:
            remove_edge(edge)
    _vertex.vertex_selected.disconnect(Callable(self, "__on_vertex_selected"))
    emit_signal("vertex_removed", _vertex)

func select_edge(edge: GraphEdge) -> void:
    if edge:
        edge.select()
        queue_redraw()

func select_vertex(vertex: GraphVertex) -> void:
    if vertex:
        vertex.select()
        queue_redraw()

func get_zoom_factor() -> float:
    return __zoom_factor

func set_port_template(template: Callable) -> void:
    __port_template = template

func set_zoom_factor(value: float) -> void:
    __zoom_factor = clamp(value, ZOOM_MIN, ZOOM_MAX)
    queue_redraw()

func get_pan_offset() -> Vector2:
    return __pan_offset

func set_pan_offset(value: Vector2) -> void:
    __pan_offset = value
    queue_redraw()

# Lifecycle Methods ===============================================================================

func _draw():
    __draw_background()
    __draw_grid()
    __draw_border()
    for vertex in __vertices:
        vertex.__draw()
    for edge in __edges:
        edge.__draw()
    __draw_edge_preview()
    for vertex in __vertices:
        vertex.__draw_vertex_ports()
    __draw_border()

func _gui_input(event: InputEvent):
    __input_controller.__handle_gui(event)

func _process(_delta: float):
    __input_controller.__process()

func _ready():
    self.theme = preload("res://addons/godot-flow/control/theme.tres")
    self.clip_contents = true
    __input_controller = InputController.new(self, __resolve_item)
    __input_controller.mouse_click.connect(Callable(self, "__on_mouse_click"))
    __input_controller.mouse_double_click.connect(Callable(self, "__on_mouse_double_click"))
    __input_controller.mouse_drag_start.connect(Callable(self, "__on_mouse_drag_start"))
    __input_controller.mouse_drag.connect(Callable(self, "__on_mouse_drag"))
    __input_controller.mouse_drag_end.connect(Callable(self, "__on_mouse_drag_end"))
    __input_controller.mouse_hover_on.connect(Callable(self, "__on_mouse_hover_on"))
    __input_controller.mouse_hover_off.connect(Callable(self, "__on_mouse_hover_off"))
    __input_controller.mouse_wheel.connect(Callable(self, "__on_mouse_wheel"))
