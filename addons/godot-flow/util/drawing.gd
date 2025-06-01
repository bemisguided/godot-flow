class_name Drawing

# Constants ======================================================================================= 

const Geometry = preload("res://addons/godot-flow/util/geometry.gd")

# Static Methods ==================================================================================

static func draw_connection_arrow(canvas: CanvasItem, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, color: Color, zoom_factor: float = 1.0):
    var points = Geometry.get_arrow_triangle(p0, p1, p2, p3, 28.0 * zoom_factor, 18.0 * zoom_factor)
    canvas.draw_colored_polygon(points, color)

static func draw_cubic_bezier(canvas: CanvasItem, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, color: Color, width: float, steps: int = 32):
    var points = PackedVector2Array()
    for i in range(steps + 1):
        var t = float(i) / float(steps)
        var a = p0.lerp(p1, t)
        var b = p1.lerp(p2, t)
        var c = p2.lerp(p3, t)
        var d = a.lerp(b, t)
        var e = b.lerp(c, t)
        var point = d.lerp(e, t)
        points.append(point)
    canvas.draw_polyline(points, color, width)

static func draw_points(canvas: CanvasItem, points: Array, color: Color, radius: float = 3.0, zoom_factor: float = 1.0):
    var n = points.size()
    if n == 0:
        return
    for p in points:
        canvas.draw_circle(p * zoom_factor, radius, color)
    # Draw lines between consecutive points, and close the polygon
    for i in range(n):
        var p1 = points[i] * zoom_factor
        var p2 = points[(i + 1) % n] * zoom_factor
        canvas.draw_line(p1, p2, color, 2.0)

static func draw_polygon(canvas: CanvasItem, path: PackedVector2Array, color: Color):
    canvas.draw_colored_polygon(path, color)

static func draw_port_circle(canvas: CanvasItem, position: Vector2, radius: float, color: Color):
    canvas.draw_circle(position, radius, color)

static func draw_port_half_circle_with_rect(canvas: CanvasItem, position: Vector2, radius: float, angle: float, color: Color, rect_extension := -1.0):
    if rect_extension < 0:
        rect_extension = radius * 0.5
    var path = Geometry.get_port_half_circle_with_rect_path(position, radius, angle, rect_extension)
    canvas.draw_colored_polygon(path, color)

static func get_arrow_triangle(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> PackedVector2Array:
    return Geometry.get_arrow_triangle(p0, p1, p2, p3)
