#@tool
extends Node2D

@export var fov_texture : Texture2D
@export_range(10.0,10000.0,1.0) var inner_radius := 200
@export_range(10.0,10000.0,1.0) var outer_radius := 300
@export_range(1,90,1) var angle_range := 20
@export_range(5,1001,2) var raycast_resolution := 5
@export_range(1,100,1) var edge_resolution := 20
@export var view_color := Color.SEA_GREEN

var heading := Vector2.RIGHT
var left_edge := Vector2.RIGHT
var left_endpoint := Vector2.RIGHT
var left_angle := 0.0
var right_edge := Vector2.RIGHT
var outer_raycast_pool : Array[RayCast2D]
var inner_raycast_pool : Array[RayCast2D]
var outer_r := preload("res://view_raycast.tscn")
var inner_r := preload("res://inner_raycast.tscn") 
var outer_points : PackedVector2Array = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN]
var inner_points : PackedVector2Array = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN]
var raycast_updated := false
#var edge_outer_raycast_pool : Array[RayCast2D]


func _ready() -> void:
	left_edge = Vector2.RIGHT.rotated(-deg_to_rad(angle_range)).normalized()
	left_angle = left_edge.angle()
	for i in raycast_resolution:
		var raycast = outer_r.instantiate()
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
		add_child(raycast)
		outer_raycast_pool.append(raycast)
	for i in raycast_resolution:
		var raycast = inner_r.instantiate()
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
		add_child(raycast)
		inner_raycast_pool.append(raycast)

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
	var angle_num = raycast_resolution - 1
	outer_points.clear()
	outer_points.append(position)
	inner_points.clear()
	inner_points.append(position)
	var old_outer_raycast : RayCast2D
	var new_outer_raycast : RayCast2D
	var old_inner_raycast : RayCast2D
	var new_inner_raycast : RayCast2D
	for i in raycast_resolution:
		new_outer_raycast = outer_raycast_pool[i]
		new_inner_raycast = inner_raycast_pool[i]
		new_outer_raycast.target_position = (left_edge.rotated(deg_to_rad(i * angle_range * 2 / angle_num)))* (inner_radius + outer_radius)
		new_inner_raycast.target_position = (left_edge.rotated(deg_to_rad(i * angle_range * 2 / angle_num)))* inner_radius
		new_outer_raycast.force_raycast_update()
		new_inner_raycast.force_raycast_update()
		if i > 0:
			if old_outer_raycast.get_collider() != new_outer_raycast.get_collider():
				var outer_edge_points = refine_edge(old_outer_raycast,new_outer_raycast,true)
				outer_points.append_array(outer_edge_points)
			if old_inner_raycast.get_collider() != new_inner_raycast.get_collider():
				var inner_edge_points = refine_edge(old_inner_raycast,new_inner_raycast,false)
				inner_points.append_array(inner_edge_points)
		#虚视角外围的点坐标
		var outer_point : Vector2 = new_outer_raycast.target_position
		#实视角内围的点坐标
		var inner_point : Vector2 = new_inner_raycast.target_position
		#判断外围彭政
		if new_outer_raycast.is_colliding():
			if new_outer_raycast.get_collider().get_collision_layer_value(1):
				var collision_point = to_local(new_outer_raycast.get_collision_point())
				outer_point = collision_point
				pass
		outer_points.append(outer_point)
		#判断内维碰撞
		if new_inner_raycast.is_colliding():
			if new_inner_raycast.get_collider().get_collision_layer_value(2) or new_inner_raycast.get_collider().get_collision_layer_value(1):
				var collision_point = to_local(new_inner_raycast.get_collision_point())
				inner_point = collision_point
		inner_points.append(inner_point)
		old_outer_raycast = new_outer_raycast
		old_inner_raycast = new_inner_raycast


func refine_edge(mincast: RayCast2D,maxcast: RayCast2D, is_outer_view: bool) -> PackedVector2Array:
	var min_angle = mincast.target_position.angle()
	var max_angle = maxcast.target_position.angle()
	var edge_points : PackedVector2Array = []
	var raycast : RayCast2D
	if is_outer_view:
		raycast = outer_r.instantiate()
	else:
		raycast = inner_r.instantiate()
	raycast.collide_with_areas = true
	raycast.collide_with_bodies = true
	add_child(raycast)
	raycast.target_position = mincast.target_position
	var angle = max_angle - min_angle
	for i in edge_resolution:
		raycast.target_position = raycast.target_position.rotated(angle/edge_resolution)
		raycast.force_raycast_update()
		var edge_point : Vector2 = raycast.target_position
		if raycast.is_colliding() and is_outer_view:
			if raycast.get_collider().get_collision_layer_value(1):
				var collision_point = to_local(raycast.get_collision_point())
				edge_point = collision_point
		elif raycast.is_colliding() and not is_outer_view:
			if raycast.get_collider().get_collision_layer_value(2) or raycast.get_collider().get_collision_layer_value(1):
				var collision_point = to_local(raycast.get_collision_point())
				edge_point = collision_point
		else:
			edge_point = edge_point.normalized() * (inner_radius if not is_outer_view else (inner_radius + outer_radius))
		edge_points.append(edge_point)
	raycast.queue_free()
	return edge_points
