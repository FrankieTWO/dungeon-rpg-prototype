extends Node

@onready var floor_layer: TileMapLayer = $floor_layer
@onready var wall_layer: TileMapLayer = $wall_layer
@onready var button: Button = $"../CanvasLayer/Control/Button"

const VERT_WALL_TILE = Vector2i(0, 1)
const MIDDLE_WALL_TILE = Vector2i(2, 3)
const LEFTBOTTOM_WALL_TILE = Vector2i(1, 2)
const RIGHTBOTTOM_WALL_TILE = Vector2i(3, 2)
const RIGHTTOP_WALL_TILE = Vector2i(3, 0)
const LEFTTOP_WALL_TILE = Vector2i(1, 0)
const FLOOR_TILE = Vector2i(1, 0)  # Added the constant for the floor tile

var map_width = 50  # Width of the map in tiles
var map_height = 50  # Height of the map in tiles
var min_room_size = 4  # Minimum size of the rooms
var max_room_size = 8  # Maximum size of the rooms
var max_rooms = 10  # Maximum number of rooms

var rooms = []  # Stores the generated rooms


func _on_hud_new_dungeon() -> void:
	rooms.clear()
	floor_layer.clear()
	wall_layer.clear()
	generate_dungeon()


func _ready() -> void:
	pass


func generate_dungeon():
	# Step 1: Generate rooms
	for i in range(max_rooms):
		var room_width = randi_range(min_room_size, max_room_size)
		var room_height = randi_range(min_room_size, max_room_size)
		var room_x = randi_range(1, map_width - room_width - 1)
		var room_y = randi_range(1, map_height - room_height - 1)
		var room = Rect2(Vector2(room_x, room_y), Vector2(room_width, room_height))

		# Check if the room overlaps with other rooms
		var overlaps = false
		for other_room in rooms:
			if room.intersects(other_room):
				overlaps = true
				break

		if not overlaps:
			rooms.append(room)
			create_room(room)

		if rooms.size() > 1:
			# Connect the new room to the previous one with a corridor
			connect_rooms(rooms[rooms.size() - 2], room)

	# Step 2: Add borders around the map
	#create_borders()

func create_room(room: Rect2):
	# DEBUG: Printing the room coordinates to ensure it's being generated correctly
	print("Creating room at: ", room.position, " with size: ", room.size)

	# Fill the room with floor tiles in FloorLayer
	for x in range(room.position.x, room.position.x + room.size.x):
		for y in range(room.position.y, room.position.y + room.size.y):
			floor_layer.set_cell(Vector2i(x, y), 0, FLOOR_TILE)  # Use the correct floor tile ID

	# Add walls around the room in WallLayer
	for x in range(room.position.x - 1, room.position.x + room.size.x + 1):
		wall_layer.set_cell(Vector2i(x, room.position.y - 1), 1, MIDDLE_WALL_TILE)  # Top wall
		wall_layer.set_cell(Vector2i(x, room.position.y + room.size.y), 1, MIDDLE_WALL_TILE)  # Bottom wall

	for y in range(room.position.y - 1, room.position.y + room.size.y + 1):
		wall_layer.set_cell(Vector2i(room.position.x - 1, y), 1, VERT_WALL_TILE)  # Left wall
		wall_layer.set_cell(Vector2i(room.position.x + room.size.x, y), 1, VERT_WALL_TILE)  # Right wall

	# Add corner walls
	wall_layer.set_cell(Vector2i(room.position.x - 1, room.position.y - 1), 1, LEFTTOP_WALL_TILE)
	wall_layer.set_cell(Vector2i(room.position.x + room.size.x, room.position.y - 1), 1, RIGHTTOP_WALL_TILE)
	wall_layer.set_cell(Vector2i(room.position.x - 1, room.position.y + room.size.y), 1, LEFTBOTTOM_WALL_TILE)
	wall_layer.set_cell(Vector2i(room.position.x + room.size.x, room.position.y + room.size.y), 1, RIGHTBOTTOM_WALL_TILE)


func connect_rooms(room1: Rect2, room2: Rect2):
	# Create a corridor between two rooms
	var center1 = room1.position + room1.size / 2
	var center2 = room2.position + room2.size / 2
	print("Connecting room1 at: ", center1, " to room2 at: ", center2)

	# Horizontal corridor
	if center1.x < center2.x:
		for x in range(center1.x, center2.x + 1):
			floor_layer.set_cell(Vector2i(x, center1.y), 0, FLOOR_TILE)  # Use the correct floor tile ID
	else:
		for x in range(center2.x, center1.x + 1):
			floor_layer.set_cell(Vector2i(x, center1.y), 0, FLOOR_TILE)

	# Vertical corridor
	if center1.y < center2.y:
		for y in range(center1.y, center2.y + 1):
			floor_layer.set_cell(Vector2i(center2.x, y), 0, FLOOR_TILE)  # Use the correct floor tile ID
	else:
		for y in range(center2.y, center1.y + 1):
			floor_layer.set_cell(Vector2i(center2.x, y), 0, FLOOR_TILE)

	# Add corner walls when corridors turn
	if abs(center1.x - center2.x) > 1 and abs(center1.y - center2.y) > 1:
		wall_layer.set_cell(Vector2i(center2.x - 1, center2.y - 1), 1, LEFTTOP_WALL_TILE)  # Example for corner walls
