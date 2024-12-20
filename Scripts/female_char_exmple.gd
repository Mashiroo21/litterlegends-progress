extends CharacterBody3D

# How fast the player moves in meters per second.
#@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
#@export var fall_acceleration = 75
#@export var jump_impulse = 20
#var target_velocity = Vector3.ZERO

#Camera
@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25

@export_group("Movement")
@export var move_speed := 10.0
@export var acceleration := 20.0
#@export var rotation_speed := 8.0
@export var jump_impulse := 10.0
@export var pickup_range: float = 2.0
@export var fall_timeout := 3.0
@export var min_y_position := -2
@export var respawn_delay := 3.0


var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var _gravity := -30.0
var held_item: Node3D = null
var fall_timer := 0
var spawn_position := Vector3.ZERO
var is_respawning: bool = false

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: CharacterEx = %CharacterEx
@onready var respawn_timer: Timer = $RespawnTimer
@onready var ui_panel: Panel = $CanvasLayer/Panel
@onready var countdown_label: Label = $CanvasLayer/Panel/CountdownLabel

func _ready():
	respawn_timer.timeout.connect(_on_RespawnTimer_timeout)
	spawn_position = global_position
	ui_panel.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction = event.screen_relative * mouse_sensitivity
		
func try_pickup_item():
	var items = get_tree().get_nodes_in_group("pickupable")
	for item in items:
		if item.global_position.distance_to(global_position) <= pickup_range:
			pickup_item(item)
			break

func pickup_item(item: Node3D):
	held_item = item
	held_item.reparent($HeldItemPosition)
	held_item.position = Vector3(0, 0.05, 0)
	#held_item.scale = Vector3(0.5, 0.5, 0.5)
	#held_item.freeze = true
	print("item picked up: ", held_item.name)
	
func drop_item():
	held_item.reparent(get_tree().root)
	#held_item.freeze = false
	held_item.global_position = $HeldItemPosition.global_position - Vector3(0, 1.5, 0)
	print("item droppd: ", held_item.name)
	held_item = null
	
func trigger_respawn():
	is_respawning = true
	ui_panel.visible = true
	respawn_timer.start(respawn_delay)
	
func _on_RespawnTimer_timeout():
	respawn_player()
	
func respawn_player():
	global_position = spawn_position
	velocity = Vector3.ZERO
	fall_timer = 0.0
	ui_panel.visible = false
	is_respawning = false
	
func kill_and_respawn():
	print ("player died! respawning...")
	global_position = spawn_position
	velocity = Vector3.ZERO
	fall_timer = 0.0

func _process(delta: float) -> void:
	if is_respawning:
		var time_left: int = ceil(respawn_timer.time_left)
		countdown_label.text = str("Respawn dalam ", time_left)

func _physics_process(delta: float) -> void:
	if is_respawning:
		return
	
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, -PI / 6.0, PI / 3.0)
	_camera_pivot.rotation.y += -_camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO
	
	var raw_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
	
	var y_velocity := velocity.y
	velocity.y = 0.0
	
	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	velocity.y = y_velocity + _gravity * delta
	
	var is_starting_jump := Input.is_action_just_pressed("jump") and is_on_floor()
	if is_starting_jump:
		velocity.y += jump_impulse
	
	move_and_slide()
	
	if move_direction.length() > 0.2:
		_last_movement_direction = move_direction
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	_skin.global_rotation.y = target_angle
	
	if global_position.y < min_y_position:
		trigger_respawn()
	
	if is_starting_jump:
		_skin.jump()
	elif not is_on_floor() and velocity.y < 0:
		_skin.fall()
		fall_timer += delta
		if fall_timer >= fall_timeout:
			kill_and_respawn()
	elif is_on_floor():
		fall_timer = 0.0
		var ground_speed := velocity.length()
		if ground_speed > 0.0:
			_skin.move()
		else:
			_skin.idle()
	
	if Input.is_action_just_pressed("ui_hold"):
		if held_item == null:
			try_pickup_item()
		else:
			drop_item()
