@tool
extends EditorPlugin

var graph_view_control = preload("res://addons/godot-flow/control/graph_view.gd")

func _enter_tree():
    add_custom_type("GraphView", "Control", graph_view_control, null)

func _exit_tree():
    remove_custom_type("GraphView")
