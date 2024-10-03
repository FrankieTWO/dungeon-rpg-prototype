extends Node

@onready var floor_layer: TileMapLayer = $floor_layer
@onready var wall_layer: TileMapLayer = $wall_layer

const VERT_WALL_TILE = Vector2i(0, 1)
const MIDDLE_WALL_TILE = Vector2i(2, 3)
const LEFTBOTTOM_WALL_TILE = Vector2i(1, 2)
const RIGHTBOTTOM_WALL_TILE = Vector2i(3, 2)
const RIGHTTOP_WALL_TILE = Vector2i(3, 0)
const LEFTTOP_WALL_TILE = Vector2i(1, 0)

var map_width = 50
var map_height = 50
var min_room_size = 4
var max_room_size = 8
var max_rooms = 10

var rooms = []
var corridors = []  # Store corridors to avoid overlaps

func _ready() -> void:
	pass

func _on_hud_new_dungeon() -> void:
	rooms.clear()
	floor_layer.clear()
	wall_layer.clear()
	generate_dungeon()

func generate_dungeon():
	for i in range(max_rooms):
		var room_width = randi_range(min_room_size, max_room_size)
		var room_height = randi_range(min_room_size, max_room_size)
		var room_x = randi_range(1, map_width - room_width - 1)
		var room_y = randi_range(1, map_height - room_height - 1)
		var room = Rect2(Vector2(room_x, room_y), Vector2(room_width, room_height))

		var overlaps = false
		for other_room in rooms:
			if room.intersects(other_room):
				overlaps = true
				break

		if not overlaps:
			rooms.append(room)
			create_room(room)

	# Connect each room to only one other room
	for i in range(1, rooms.size()):
		var closest_room = find_closest_room(rooms[i])
		if closest_room != null:
			connect_rooms(rooms[i], closest_room)

func create_room(room: Rect2):
	for x in range(room.position.x, room.position.x + room.size.x):
		for y in range(room.position.y, room.position.y + room.size.y):
			floor_layer.set_cell(Vector2i(x, y), 0 , Vector2i(1,0))

	for x in range(room.position.x - 1, room.position.x + room.size.x + 1):
		wall_layer.set_cell(Vector2i(x, room.position.y - 1), 1 , MIDDLE_WALL_TILE)
		wall_layer.set_cell(Vector2i(x, room.position.y + room.size.y), 1 , MIDDLE_WALL_TILE)

	for y in range(room.position.y - 1, room.position.y + room.size.y + 1):
		wall_layer.set_cell(Vector2i(room.position.x - 1, y), 1 , VERT_WALL_TILE)
		wall_layer.set_cell(Vector2i(room.position.x + room.size.x, y), 1 , VERT_WALL_TILE)

func connect_rooms(room1: Rect2, room2: Rect2):
	var center1 = room1.position + room1.size / 2
	var center2 = room2.position + room2.size / 2

	var corridor_points = []  # To store the points of the corridor

	# Create a straight horizontal corridor
	if abs(center1.x - center2.x) > abs(center1.y - center2.y):
		for x in range(int(center1.x), int(center2.x) + 1):
			var point = Vector2i(x, int(center1.y))
			if not point_in_corridor(point):
				corridor_points.append(point)
				floor_layer.set_cell(point, 0, Vector2i(1, 0))

	# Create a vertical corridor
	else:
		for y in range(int(center1.y), int(center2.y) + 1):
			var point = Vector2i(int(center2.x), y)
			if not point_in_corridor(point):
				corridor_points.append(point)
				floor_layer.set_cell(point, 0, Vector2i(1, 0))

	corridors.append_array(corridor_points)

func point_in_corridor(point: Vector2i) -> bool:
	for corridor in corridors:
		if corridor == point:
			return true
	return false

func find_closest_room(room: Rect2) -> Rect2:
	var closest_room = null
	var closest_distance = INF

	for other_room in rooms:
		if other_room == room:
			continue
		var distance = room.position.distance_to(other_room.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_room = other_room

	return closest_room
