extends Node2D

@export var view_color := Color.PURPLE
var points : PackedVector2Array = []


func _draw() -> void:
	for i in points.size():
		var triangle_points = []
		if i < points.size() - 1:
			var first_point := points[0]
			var second_point := points[i]
			var third_point := points[i + 1]
			triangle_points = [first_point,second_point,third_point]
		else:
			var first_point := points[0]
			var second_point := points[i]
			triangle_points = [first_point,second_point,first_point]
		draw_colored_polygon(triangle_points,view_color)
	pass


func update_points(_points: PackedVector2Array) -> void:
	points = _points
