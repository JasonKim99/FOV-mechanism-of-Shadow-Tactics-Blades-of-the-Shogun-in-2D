extends Node2D

@export var view_texture : Texture2D
@export var view_color := Color.SEA_GREEN:
	set(new_color):
		view_color = new_color
		material.set_shader_parameter("stripe_color",view_color)

var outer_points : PackedVector2Array = []

func _draw() -> void:
	for i in outer_points.size():
		var triangle_points = []
		if i < outer_points.size() - 1:
			var first_point := outer_points[0]
			var second_point := outer_points[i]
			var third_point := outer_points[i + 1]
			triangle_points = [first_point,second_point,third_point]
		else:
			var first_point := outer_points[0]
			var second_point := outer_points[i]
			triangle_points = [first_point,second_point,first_point]
		draw_colored_polygon(triangle_points,view_color,triangle_points,view_texture)
	pass


func update_points(inner_points: PackedVector2Array) -> void:
	outer_points = inner_points
