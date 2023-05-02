#@tool
extends Node2D

@export var fov_texture : Texture2D
@export_range(10.0,10000.0,1.0) var inner_radius := 200
@export_range(10.0,10000.0,1.0) var outer_radius := 300
@export_range(1,90,1) var angle_range := 20
@export_range(5,1001,2) var raycast_resolution := 101
@export var view_color := Color.SEA_GREEN

var heading := Vector2.RIGHT
var left_edge := Vector2.RIGHT
var left_endpoint := Vector2.RIGHT
var left_angle := 0.0
var right_edge := Vector2.RIGHT
var outer_raycast_pool : Array[RayCast2D]
var inner_raycast_pool : Array[RayCast2D]
var outer_raycast: RayCast2D
var inner_raycast: RayCast2D
var outer_r := preload("res://view_raycast.tscn")
var inner_r := preload("res://inner_raycast.tscn") 
var outer_points : PackedVector2Array = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN]
var inner_points : PackedVector2Array = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN]
var raycast_updated := false
#var edge_outer_raycast_pool : Array[RayCast2D]


func _ready() -> void:
	left_edge = Vector2.RIGHT.rotated(-deg_to_rad(angle_range)).normalized()
	left_angle = left_edge.angle()
	outer_raycast = outer_r.instantiate()
	outer_raycast.collide_with_areas = true
	outer_raycast.collide_with_bodies = true
	add_child(outer_raycast)

	inner_raycast = inner_r.instantiate()
	inner_raycast.collide_with_areas = true
	inner_raycast.collide_with_bodies = true
	add_child(inner_raycast)

func _physics_process(delta: float) -> void:
	setup_angle()
#	await get_tree().process_frame
	queue_redraw()

func _draw() -> void:
	Geometry2D.convex_hull(outer_points)
	Geometry2D.convex_hull(inner_points)
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
		draw_colored_polygon(triangle_points,view_color,triangle_points,fov_texture)

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
	pass

func setup_angle() -> void:
	heading = (get_local_mouse_position() - position).normalized()
#	rotate(heading.angle())
	look_at(get_global_mouse_position())
	left_edge = heading.rotated(-deg_to_rad(angle_range)).normalized()
	left_angle = left_edge.angle()
	setup_raycast()


func setup_raycast() -> void:
	outer_points.clear()
	outer_points.append(position)
	inner_points.clear()
	inner_points.append(position)
	
	var angle_num = raycast_resolution - 1
	var angle_step = deg_to_rad(angle_range * 2) / angle_num

	for i in range(raycast_resolution):
		var current_angle = left_edge.angle() + i * angle_step
		var outer_target = Vector2(cos(current_angle), sin(current_angle)) * (inner_radius + outer_radius)
		var inner_target = Vector2(cos(current_angle), sin(current_angle)) * inner_radius

		outer_raycast.target_position = outer_target
		outer_raycast.force_raycast_update()
		inner_raycast.target_position = inner_target
		inner_raycast.force_raycast_update()

		var outer_point = outer_target
		var inner_point = inner_target

		if outer_raycast.is_colliding():
			if outer_raycast.get_collider().get_collision_layer_value(1):
				outer_point = to_local(outer_raycast.get_collision_point())
		outer_points.append(outer_point)

		if inner_raycast.is_colliding():
			if inner_raycast.get_collider().get_collision_layer_value(2) or inner_raycast.get_collider().get_collision_layer_value(1):
				inner_point = to_local(inner_raycast.get_collision_point())
		inner_points.append(inner_point)
