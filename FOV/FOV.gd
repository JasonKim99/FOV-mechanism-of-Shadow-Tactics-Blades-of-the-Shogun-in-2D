#@tool
extends CanvasGroup
#extends Node2D


enum view_layer {
	OUT,
	IN,
	INTEREST
}


@onready var inner_view: Node2D = $InnerView
@onready var outer_view: Node2D = $OuterView
@onready var interest_view: Node2D = $InterestView
@onready var marker: Marker2D = $Marker

#@export var place_hold_texture : Texture2D 
@export_range(10.0,10000.0,1.0) var inner_radius := 200
@export_range(10.0,10000.0,1.0) var outer_radius := 100
@export_range(1,90,1) var angle_range := 20
@export_range(5,1001,2) var raycast_resolution := 7
@export_range(1,100,1) var edge_resolution := 10
@export var view_color := Color.SEA_GREEN:
	set(new_color):
		view_color = new_color
		if inner_view and outer_view:
			inner_view.view_color = view_color
			outer_view.view_color = view_color

const heading := Vector2.RIGHT
var left_edge := Vector2.RIGHT
var outer_raycast_pool : Array[RayCast2D]
var inner_raycast_pool : Array[RayCast2D]
var outer_r := preload("res://view_raycast.tscn")
var inner_r := preload("res://inner_raycast.tscn") 
var outer_points : PackedVector2Array = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN]
var inner_points : PackedVector2Array = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN]
var interest_points : PackedVector2Array = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN]
var raycast_updated := false

var tween : Tween
var sake_detect_speed := 100
var sake : Area2D
var sake_distance : float =0.0
var progress : float = 0.0
var detect_time : float = 0.0
var zoom := Vector2(1,1)

func _ready() -> void:
	
	left_edge = heading.rotated(-deg_to_rad(angle_range)).normalized()
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
	set_physics_process(true)
	patrol()

func _physics_process(delta: float) -> void:
	zoom = get_viewport().get_camera_2d().zoom
	var fov_screen_uv = global_to_uv(global_position)
	material.set_shader_parameter("fov_uv_pos",fov_screen_uv)
	setup_raycast()
	detect_sake(delta)
	queue_redraw()

func _draw() -> void:
	Geometry2D.convex_hull(outer_points)
	Geometry2D.convex_hull(inner_points)
	outer_view.update_points(outer_points)
	inner_view.update_points(inner_points)
	interest_view.update_points(interest_points)
	outer_view.queue_redraw()
	inner_view.queue_redraw()
	interest_view.queue_redraw()

func setup_raycast() -> void:
	var angle_num = raycast_resolution - 1
	outer_points.clear()
	outer_points.append(position)
	inner_points.clear()
	inner_points.append(position)
	interest_points.clear()
	interest_points.append(position)
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
				var outer_edge_points = refine_edge(old_outer_raycast,new_outer_raycast,view_layer.OUT)
				outer_points.append_array(outer_edge_points)
			if old_inner_raycast.get_collider() != new_inner_raycast.get_collider():
				var inner_edge_points = refine_edge(old_inner_raycast,new_inner_raycast,view_layer.IN)
#				var interest_edge_points = refine_edge(old_inner_raycast,new_inner_raycast,view_layer.INTEREST)
				inner_points.append_array(inner_edge_points)
#				interest_points.append_array(interest_edge_points)
		#虚视角外围的点坐标
		var outer_point : Vector2 = new_outer_raycast.target_position
		#实视角内围的点坐标
		var inner_point : Vector2 = new_inner_raycast.target_position
		#判断外围碰撞
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
#		interest_points.append(calculate_interest_point(inner_point))
		old_outer_raycast = new_outer_raycast
		old_inner_raycast = new_inner_raycast

func refine_edge(mincast: RayCast2D,maxcast: RayCast2D, layer: view_layer) -> PackedVector2Array:
	var min_angle = mincast.target_position.angle()
	var max_angle = maxcast.target_position.angle()
	var edge_points : PackedVector2Array = []
	var raycast : RayCast2D
	if layer == view_layer.OUT:
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
		if raycast.is_colliding() and layer == view_layer.OUT:
			if raycast.get_collider().get_collision_layer_value(1):
				var collision_point = to_local(raycast.get_collision_point())
				edge_point = collision_point
		elif raycast.is_colliding() and layer != view_layer.OUT:
			if raycast.get_collider().get_collision_layer_value(2) or raycast.get_collider().get_collision_layer_value(1):
				var collision_point = to_local(raycast.get_collision_point())
				edge_point = collision_point
		else:
			edge_point = edge_point.normalized() * (inner_radius if layer != view_layer.OUT else (inner_radius + outer_radius))
#		#内视角且是有sake
#		if layer == view_layer.INTEREST and sake:
#			edge_point = calculate_interest_point(edge_point)
		edge_points.append(edge_point)
	raycast.queue_free()
	return edge_points

func patrol() -> void:
	if tween:
		tween.kill()
	else:
		tween = create_tween().set_loops()
	tween.tween_property(self,"rotation_degrees",-45,2).set_delay(2)
	tween.tween_property(self,"rotation_degrees",45,2).set_delay(2)
	pass

func detect_sake(delta: float) -> void:
	if not sake:
		for ray in inner_raycast_pool:
			if ray.is_colliding() and ray.get_collider().get_collision_layer_value(4):
				sake = ray.get_collider()
				break
			else:
				sake = null
#				detect_time = 0.0
				view_color = Color.SEA_GREEN
				interest_view.hide()
	else:
		if tween:
			tween.kill()
		look_at(sake.global_position)
		interest_view.show()
		sake_distance = global_position.distance_to(sake.global_position)
		detect_time += delta
		progress = min(detect_time * sake_detect_speed / sake_distance,1)
		#屏幕的距离和实际的距离要乘以放大倍数，假如放大倍数不一致则取最大值
		material.set_shader_parameter("radius",detect_time * sake_detect_speed * max(zoom.x,zoom.y))
		if is_equal_approx(progress,1):
			interest_view.hide()
			view_color = Color.PURPLE
			material.set_shader_parameter("radius",0.0)
	pass

func calculate_interest_point(point: Vector2) -> Vector2:
	if point.length() > sake_distance * progress:
		return point.normalized() * progress * sake_distance
	else:
		return point
	pass

func global_to_uv(global: Vector2) -> Vector2:
	var camera_zoom = get_viewport().get_camera_2d().zoom
	## 定位视窗的global position
	var screen_origin = get_viewport().get_camera_2d().get_screen_center_position() - Vector2(get_viewport().size / 2) / camera_zoom
	## 计算在视窗坐标系下的坐标
	var screen_pos = global - screen_origin
	
	## 换算成视窗uv
	var screen_uv = screen_pos / (Vector2(get_viewport().size)/ camera_zoom)
	return screen_uv
