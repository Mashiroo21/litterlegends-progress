extends Node3D

# Preload scene untuk tiap jenis sampah
@export var plastic_trash_scene: PackedScene = preload("res://scenes/Assets/apple.tscn")
@export var inorganic_trash_scene: PackedScene = preload("res://scenes/Assets/plastic bottle.tscn")
@export var chemical_trash_scene: PackedScene = preload("res://scenes/Assets/chemical.tscn")

# Batas area spawn (misalnya dalam koordinat X dan Z)
@export var spawn_areas: Array[Vector3] = [
	Vector3(-10, 0, -10),
	Vector3(10, 0, -10),
	Vector3(-10, 0, 10),
	Vector3(10, 0, 10)
]

# Waktu dan jadwal spawn
var elapsed_time: float = 0.0
var spawn_schedule: Array

# Timer
@export var total_game_time: float = 180.0  # 3 menit (dalam detik)
@export var chemical_spawn_interval: float = 45.0
var next_chemical_spawn_time: float = 45.0

func _ready():
	# Inisialisasi jadwal spawn
	spawn_schedule = [
		{"time": 0, "plastic": 4, "inorganic": 0, "chemical": 0},   # 0-30 detik
		{"time": 30, "plastic": 2, "inorganic": 1, "chemical": 0},  # 30-40 detik
		{"time": 40, "plastic": 2, "inorganic": 1, "chemical": 0},  # 40-50 detik
	]
	# Spawn pertama (30 detik pertama)
	spawn_items(plastic_trash_scene, 4)

func _process(delta):
	elapsed_time += delta

	# Cek jadwal spawn
	for schedule in spawn_schedule:
		if abs(schedule.time - elapsed_time) < delta:  # Ketika waktu terlampaui
			spawn_items(plastic_trash_scene, schedule.plastic)
			spawn_items(inorganic_trash_scene, schedule.inorganic)
	
	# Spawn sampah kimia setiap 45 detik
	if elapsed_time >= next_chemical_spawn_time:
		spawn_items(chemical_trash_scene, 1)
		next_chemical_spawn_time += chemical_spawn_interval

	# Jika waktu habis, hentikan game
	if elapsed_time >= total_game_time:
		print("Game Over")
		get_tree().quit()

func spawn_items(item_scene: PackedScene, count: int):
	for i in range(count):
		var item_instance = item_scene.instantiate()
		
		# Tentukan posisi acak dari area spawn
		var spawn_position = get_random_spawn_position()
		item_instance.position = spawn_position

		# Resize item agar tidak terlalu besar
		item_instance.scale = Vector3(0.5, 0.5, 0.5)  # Sesuaikan skala di sini
		
		# Tambahkan ke scene
		add_child(item_instance)
		print("Spawned item at: ", spawn_position)

func get_random_spawn_position() -> Vector3:
	# Ambil area acak dari daftar spawn_areas
	var base_position = spawn_areas[randi() % spawn_areas.size()]
	var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))  # Offset kecil agar random
	return base_position + offset
