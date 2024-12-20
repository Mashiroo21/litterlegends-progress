extends Node3D

@onready var items = [
	$Item1,
	$Item2,
	$Item3,
	$Item4,
	$Item5
]

# Menyimpan transform awal dari setiap item
var initial_transforms = []

# Jadwal waktu spawn
var spawn_schedule = [
	{"time": 0, "index": [2]},      # Item3 muncul di awal
	{"time": 0, "index": [3]},      # Item3 muncul di awal
	{"time": 10, "index": [0]},      # Item1 muncul setelah 10 detik
	{"time": 30, "index": [1]},     # Item2 muncul setelah 30 detik
	{"time": 10, "index": [4]},      # Item3 muncul setelah 10 detik
]

# Waktu berjalan
var elapsed_time = 0.0
var schedule_index = 0

func _ready():
	# Simpan transform awal setiap item
	for item in items:
		initial_transforms.append(item.global_transform)
		item.visible = false  # Sembunyikan item di awal

func _process(delta):
	# Hitung waktu berjalan
	elapsed_time += delta

	# Cek jadwal spawn item
	if schedule_index < spawn_schedule.size():
		var current_schedule = spawn_schedule[schedule_index]
		if elapsed_time >= current_schedule.time:
			for idx in current_schedule.index:
				respawn_item(idx)
			schedule_index += 1

func respawn_item(index):
	# Respawn item menggunakan posisi awalnya
	if index >= 0 and index < items.size():
		var item = items[index]
		item.global_transform = initial_transforms[index]  # Gunakan transform awal
		item.visible = true
		print("Item respawned: ", item.name)

func on_item_collected(item):
	# Ketika item diambil, sembunyikan item tersebut
	item.visible = false
	print("Item collected: ", item.name)
