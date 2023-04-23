extends Node2D

@export_range(10.0,10000.0,1.0) var radius:= 200
@export_range(1,90,1) var angle_range := 30
@export_range(5,1001,2) var raycast_num := 9
@export var view_color := Color.SEA_GREEN

var heading := Vector2.RIGHT
var left_edge := Vector2.RIGHT
var left_endpoint := Vector2.RIGHT
var left_angle := 0.0
var right_edge := Vector2.RIGHT
var raycast_pool : Array[RayCast2D]
var r = preload("res://view_raycast.tscn")
var drawpoint_pool : PackedVector2Array = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN]
var raycast_updated := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in raycast_num:
		var raycast = r.instantiate()
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = true
		add_child(raycast)
		raycast_pool.append(raycast)


func _draw() -> void:
#	draw_arc(position,radius,left_angle ,right_angle,raycast_num,Color.WHITE,10,true)
#	draw_line(position,position + left_edge * radius,Color.WHITE,10,true)
#	draw_line(position,position + right_edge * radius,Color.WHITE,10,true)
#	for ray in raycast_pool:
#		var draw_pos := ray.target_position if not ray.is_colliding() else to_local(ray.get_collision_point())
#		draw_line(position,draw_pos,Color.WHITE,1,true)
	if drawpoint_pool.size() < 3:
		print("少于三个点")
		return
	draw_colored_polygon(drawpoint_pool,view_color)
	pass

func setup_angle(init: bool) -> void:
	if not init:
		heading = (get_local_mouse_position() - position).normalized()
	rotate(heading.angle())
	left_edge = Vector2.RIGHT.rotated(-deg_to_rad(angle_range)).normalized()
	left_angle = left_edge.angle()
	setup_raycast()
	

func setup_raycast() -> void:
	var angle_num = raycast_pool.size() - 1
	drawpoint_pool.clear()
	drawpoint_pool.append(position)
	for i in raycast_pool.size():
		raycast_pool[i].target_position = (left_edge.rotated(deg_to_rad(i * angle_range * 2 / angle_num)))* radius
		drawpoint_pool.append(raycast_pool[i].target_position if not raycast_pool[i].is_colliding() else to_local(raycast_pool[i].get_collision_point()))

func _process(delta: float) -> void:
	setup_angle(false)
	queue_redraw()

