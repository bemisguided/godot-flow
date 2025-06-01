class_name InputController

# Signals =========================================================================================
signal mouse_click(position, item)
signal mouse_double_click(position, item)
signal mouse_drag(start_position, current_position, item)
signal mouse_drag_end(start_position, end_position, start_item, end_item)
signal mouse_drag_start(position, item)
signal mouse_hover_on(position, item)
signal mouse_hover_off(position, item)
signal mouse_wheel(delta, position)

# Properties ======================================================================================

var __control: Control
var __drag_start_item = null
var __dragging = false
var __hovered_item = null
var __mouse_entered = false
var __mouse_position: Vector2 = Vector2.ZERO
var __resolver_item: Callable
var __drag_start_position: Vector2 = Vector2.ZERO

# Constructors ====================================================================================

func _init(control: Control, resolver_item):
    __control = control
    __resolver_item = resolver_item
    __control.mouse_entered.connect(Callable(self, "__on_mouse_entered"))
    __control.mouse_exited.connect(Callable(self, "__on_mouse_exited"))

# Internal Methods ================================================================================

func __process():
    if !__mouse_entered:
        return
    var mouse_position = __control.get_local_mouse_position()
    var item = __resolver_item.call(mouse_position)
    __mouse_position = mouse_position
    if item != __hovered_item:
        if __hovered_item != null:
            emit_signal("mouse_hover_off", mouse_position, __hovered_item)
        if item != null:
            emit_signal("mouse_hover_on", mouse_position, item)
        __hovered_item = item


func __handle_gui(event: InputEvent):
    if event is InputEventMagnifyGesture:
        var zoom_delta = event.factor - 1.0
        emit_signal("mouse_wheel", zoom_delta, __mouse_position)
        return
    if event is InputEventMouseButton:
        __mouse_position = event.position
        var item = __resolver_item.call(event.position)
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            emit_signal("mouse_wheel", 1, event.position)
            return
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            emit_signal("mouse_wheel", -1, event.position)
            return
        if event.pressed:
            if event.double_click:
                emit_signal("mouse_double_click", event.position, item)
            else:
                emit_signal("mouse_click", event.position, item)
            __drag_start_item = item
            __drag_start_position = event.position
            __dragging = true
            emit_signal("mouse_drag_start", event.position, item)
        else:
            if __dragging:
                var end_item = __resolver_item.call(event.position)
                emit_signal("mouse_drag_end", __drag_start_position, event.position, __drag_start_item, end_item)
                __dragging = false
                __drag_start_item = null
    elif event is InputEventMouseMotion:
        __mouse_position = event.position
        if __dragging:
            emit_signal("mouse_drag", __drag_start_position, __mouse_position, __drag_start_item)

func __on_mouse_entered():
    __mouse_entered = true

func __on_mouse_exited():
    __mouse_entered = false

# Public Methods ==================================================================================
func get_drag_start_item():
    return __drag_start_item

func get_mouse_position() -> Vector2:
    return __mouse_position

func is_dragging() -> bool:
    return __dragging