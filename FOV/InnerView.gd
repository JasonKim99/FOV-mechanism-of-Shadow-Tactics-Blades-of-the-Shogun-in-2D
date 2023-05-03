extends Node2D

@export var view_color := Color.SEA_GREEN
var inner_points : PackedVector2Array = []


func _draw() -> void:
	for i in inner_points.size():
		var triangle_points = []
		if i < inner_points.size() - 1:
			var first_point := inner_points[0]
			var second_point := inner_points[i]
			var third_point := inner_points[i + 1]
			triangle_points = [first_point,second_point,third_point]
		else:
			var first_point := inner_points[0]
			var second_point := inner_points[i]
			triangle_points = [first_point,second_point,first_point]
		draw_colored_polygon(triangle_points,view_color)
	pass


func update_points(points: PackedVector2Array) -> void:
	inner_points = points
