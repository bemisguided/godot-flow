class_name Geometry

# Static Methods ==================================================================================

# Returns true if point p is inside triangle (a, b, c)
static func is_point_in_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
    var as_x = p.x - a.x
    var as_y = p.y - a.y
    var s_ab = (b.x - a.x) * as_y - (b.y - a.y) * as_x > 0
    if ((c.x - a.x) * as_y - (c.y - a.y) * as_x > 0) == s_ab:
        return false
    if ((c.x - b.x) * (p.y - b.y) - (c.y - b.y) * (p.x - b.x) > 0) != s_ab:
        return false
    return true

# Returns a perpendicular vector (rotated 90 degrees counterclockwise)
static func perpendicular(v: Vector2) -> Vector2:
    return Vector2(-v.y, v.x)

# Returns the three points of an arrow triangle at the midpoint of a cubic Bezier
static func get_arrow_triangle(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, arrow_length := 28.0, arrow_width := 18.0) -> PackedVector2Array:
    var t = 0.5
    var a = p0.lerp(p1, t)
    var b = p1.lerp(p2, t)
    var c = p2.lerp(p3, t)
    var d = a.lerp(b, t)
    var e = b.lerp(c, t)
    var pos = d.lerp(e, t)
    var dir = (e - d).normalized()
    var tip = pos + dir * arrow_length * 0.5
    var perp = perpendicular(dir)
    var base_left = pos - dir * arrow_length * 0.5 + perp * (arrow_width * 0.5)
    var base_right = pos - dir * arrow_length * 0.5 - perp * (arrow_width * 0.5)
    return PackedVector2Array([tip, base_left, base_right])

# Returns the four points for a cubic Bezier curve between from_pos and to_pos, with control points dynamically offset based on distance and direction.
static func get_bezier_points(from_pos: Vector2, to_pos: Vector2) -> Array:
    var delta = to_pos - from_pos
    var distance = delta.length()
    var direction = delta.normalized()
    var perpendicular = Vector2(-direction.y, direction.x)
    var offset = clamp(distance * 0.3, 40, 200) # Dynamic offset
    var ctrl1 = from_pos + direction * offset + perpendicular * offset * 0.1
    var ctrl2 = to_pos - direction * offset + perpendicular * offset * -0.1
    return [from_pos, ctrl1, ctrl2, to_pos]

static func get_port_circle_path(position: Vector2, radius: float) -> PackedVector2Array:
    var points = []
    var steps = 24
    for i in range(steps):
        var angle = TAU * float(i) / steps
        points.append(position + Vector2(cos(angle), sin(angle)) * radius)
    return PackedVector2Array(points)

static func snap_point(p: Vector2, grid: float = 0.1) -> Vector2:
    return Vector2(round(p.x / grid) * grid, round(p.y / grid) * grid)

static func get_port_half_circle_with_rect_path(position: Vector2, radius: float, angle: float, rect_extension := -1.0) -> PackedVector2Array:
    if rect_extension < 0:
        rect_extension = radius * 0.5
    if radius <= 0 or rect_extension <= 0:
        return PackedVector2Array()
    var steps = 12
    var arc_points = []
    for i in range(steps + 1):
        var arc_angle = angle + PI + PI * float(i) / steps
        arc_points.append(snap_point(position + Vector2(cos(arc_angle), sin(arc_angle)) * radius, 1.0))
    var flat2 = arc_points[0]
    var flat1 = arc_points[steps]
    var flat_dir = (flat1 - flat2).normalized()
    var rect_dir = Vector2(-flat_dir.y, flat_dir.x) # Perpendicular to flat side
    # Determine which side to extend: pick the direction that points away from the center
    var to_center = (position - (flat1 + flat2) * 0.5).normalized()
    if rect_dir.dot(to_center) < 0:
        rect_dir = - rect_dir
    var rect1 = flat1 + rect_dir * rect_extension
    var rect2 = flat2 + rect_dir * rect_extension
    var points = []
    points += arc_points
    points.append(rect1)
    points.append(rect2)
    return PackedVector2Array(points)

static func is_point_in_port_circle(point: Vector2, position: Vector2, radius: float) -> bool:
    return position.distance_to(point) <= radius

static func is_point_in_port_half_circle_with_rect(point: Vector2, position: Vector2, radius: float, angle: float, rect_extension := -1.0) -> bool:
    if rect_extension < 0:
        rect_extension = radius * 0.5
    var path = get_port_half_circle_with_rect_path(position, radius, angle, rect_extension)
    return Geometry2D.is_point_in_polygon(point, path)

static func transform_path_to_screen(path: PackedVector2Array, pan_offset: Vector2, zoom: float) -> PackedVector2Array:
    var screen_path = PackedVector2Array()
    for p in path:
        screen_path.append((p - pan_offset) * zoom)
    return screen_path