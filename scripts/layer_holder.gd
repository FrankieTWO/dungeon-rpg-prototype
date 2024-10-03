extends Node

@onready var floor_layer: TileMapLayer = $floor_layer
@onready var wall_layer: TileMapLayer = $wall_layer
@onready var button: Button = $"../CanvasLayer/Control/Button"
@onready var player_scene = preload("res://scenes/player.tscn")

const VERT_WALL_TILE = Vector2i(0, 1)
const MIDDLE_WALL_TILE = Vector2i(2, 3)
const LEFTBOTTOM_WALL_TILE = Vector2i(1, 2)
const RIGHTBOTTOM_WALL_TILE = Vector2i(3, 2)
const RIGHTTOP_WALL_TILE = Vector2i(3, 0)
const LEFTTOP_WALL_TILE = Vector2i(1, 0)
const FLOOR_TILE = Vector2i(1, 0)  # Floor tile constant

var map_width = 70  # Width of the map in tiles
var map_height = 70  # Height of the map in tiles
var min_room_size = 8  # Minimum size of the rooms
var max_room_size = 16  # Maximum size of the rooms
var max_rooms = 10  # Maximum number of rooms
var spawn_point = null
var player_instance: Node = null

var rooms = []  # Stores the generated rooms
var floor_tiles = []

func _on_hud_new_dungeon() -> void:
	rooms.clear()
	floor_layer.clear()
	wall_layer.clear()
	generate_dungeon()
	place_walls()
	add_player()
	
func _ready() -> void:
	pass

# Step 1: Create rooms and connect them with floor tiles
func generate_dungeon():
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
			connect_rooms(rooms[rooms.size() - 2], room)

# Create room floors
func create_room(room: Rect2):
	#print("Creating room at: ", room.position, " with size: ", room.size)
	# Fill the room with floor tiles
	for x in range(room.position.x, room.position.x + room.size.x):
		for y in range(room.position.y, room.position.y + room.size.y):
			floor_layer.set_cell(Vector2i(x, y), 0, FLOOR_TILE)  # Use floor tile

# Connect rooms with 2-tile-wide corridors
func connect_rooms(room1: Rect2, room2: Rect2):
	var center1 = room1.position + room1.size / 2
	var center2 = room2.position + room2.size / 2


	# Horizontal corridor
	if center1.x < center2.x:
		for x in range(center1.x, center2.x + 1):
			floor_layer.set_cell(Vector2i(x, center1.y), 0, FLOOR_TILE)
			floor_layer.set_cell(Vector2i(x, center1.y + 1), 0, FLOOR_TILE)
			floor_layer.set_cell(Vector2i(x, center1.y + 2), 0, FLOOR_TILE)  # 2-tile-wide corridor
	else:
		for x in range(center2.x, center1.x + 1):
			floor_layer.set_cell(Vector2i(x, center1.y), 0, FLOOR_TILE)
			floor_layer.set_cell(Vector2i(x, center1.y + 1), 0, FLOOR_TILE)
			floor_layer.set_cell(Vector2i(x, center1.y + 2), 0, FLOOR_TILE)

	# Vertical corridor
	if center1.y < center2.y:
		for y in range(center1.y, center2.y + 1):
			floor_layer.set_cell(Vector2i(center2.x, y), 0, FLOOR_TILE)
			floor_layer.set_cell(Vector2i(center2.x + 1, y), 0, FLOOR_TILE)
			floor_layer.set_cell(Vector2i(center2.x + 2, y), 0, FLOOR_TILE)  # 2-tile-wide corridor
	else:
		for y in range(center2.y, center1.y + 1):
			floor_layer.set_cell(Vector2i(center2.x, y), 0, FLOOR_TILE)
			floor_layer.set_cell(Vector2i(center2.x + 1, y), 0, FLOOR_TILE)
			floor_layer.set_cell(Vector2i(center2.x + 2, y), 0, FLOOR_TILE)

# Step 2: Place walls around rooms and corridors
func place_walls():
	var floor_positions = []  # List to track all floor positions

	# Gather all floor tile positions
	for x in range(map_width):
		for y in range(map_height):
			if floor_layer.get_cell_source_id(Vector2i(x, y)) != -1:  # If there is a floor tile
				floor_positions.append(Vector2i(x, y))

	# Place walls around each floor tile
	for pos in floor_positions:
		# Check all 4 directions around the floor tile for placing walls
		for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var neighbor_pos = pos + offset
			if floor_layer.get_cell_source_id(neighbor_pos) == -1:  # If there is no floor tile
				if offset == Vector2i(-1, 0):  # Left
					wall_layer.set_cell(neighbor_pos, 1, VERT_WALL_TILE)
					floor_layer.set_cell(neighbor_pos, 0, FLOOR_TILE)
				elif offset == Vector2i(1, 0):  # Right
					wall_layer.set_cell(neighbor_pos, 1, VERT_WALL_TILE)
					floor_layer.set_cell(neighbor_pos, 0, FLOOR_TILE)
				elif offset == Vector2i(0, -1):  # Top
					wall_layer.set_cell(neighbor_pos, 1, MIDDLE_WALL_TILE)
				elif offset == Vector2i(0, 1):  # Bottom
					wall_layer.set_cell(neighbor_pos, 1, MIDDLE_WALL_TILE)

		# Add corner walls if necessary
		add_corner_walls(pos)

# Add corner walls based on the room-to-corridor junctions
func add_corner_walls(pos: Vector2i):
	# Check the four corner directions
	var corner_offsets = [
		Vector2i(-1, -1), Vector2i(1, -1),  # Top-left, top-right
		Vector2i(-1, 1), Vector2i(1, 1)  # Bottom-left, bottom-right
	]

	for offset in corner_offsets:
		var corner_pos = pos + offset
		var x_offset_empty = floor_layer.get_cell_source_id(Vector2i(pos.x + offset.x, pos.y)) == -1
		var y_offset_empty = floor_layer.get_cell_source_id(Vector2i(pos.x, pos.y + offset.y)) == -1

		if x_offset_empty and y_offset_empty:  # Both adjacent sides are empty
			if offset == Vector2i(-1, -1):  # Top-left corner
				wall_layer.set_cell(corner_pos, 1, LEFTTOP_WALL_TILE)
			elif offset == Vector2i(1, -1):  # Top-right corner
				wall_layer.set_cell(corner_pos, 1, RIGHTTOP_WALL_TILE)
			elif offset == Vector2i(-1, 1):  # Bottom-left corner
				wall_layer.set_cell(corner_pos, 1, LEFTBOTTOM_WALL_TILE)
			elif offset == Vector2i(1, 1):  # Bottom-right corner
				wall_layer.set_cell(corner_pos, 1, RIGHTBOTTOM_WALL_TILE)

	# Handle the case where corridors meet rooms
	handle_corridor_to_room_junction(pos)

# Ensure corners are properly placed when corridors meet rooms
func handle_corridor_to_room_junction(pos: Vector2i):
	var directions = [
		Vector2i(-1, 0), Vector2i(1, 0),  # Left, right
		Vector2i(0, -1), Vector2i(0, 1)   # Top, bottom
	]

	for direction in directions:
		var neighbor = pos + direction
		if floor_layer.get_cell_source_id(neighbor) != -1:  # If there is a floor tile
			# Remove the wall tile from the corridor-room connection point
			wall_layer.set_cell(pos, -1)



var room_centers = []  # To store the center points of each room

func add_player():
	if player_instance != null:
		player_instance.queue_free()  # Remove the old player if it exists

	player_instance = player_scene.instantiate()  # Create a new instance of the player

	# Define the tile size manually (adjust this to your actual tile size)
	var tile_size = Vector2(16, 16)  # Example: assuming each tile is 32x32 pixels

	# Select a random room
	var random_room = rooms[randi_range(0, rooms.size() - 1)]
	
	# Choose a random position inside that room
	var room_x = randi_range(random_room.position.x, random_room.position.x + random_room.size.x - 1)
	var room_y = randi_range(random_room.position.y, random_room.position.y + random_room.size.y - 1)
	
	# Convert the tile position to world position manually
	spawn_point = Vector2(room_x * tile_size.x, room_y * tile_size.y)

	print("Spawn point set to: ", spawn_point)

	# Now, set the player's position to the calculated spawn point
	add_child(player_instance)  # Add the player to the scene tree first
	player_instance.position = spawn_point  # Then set the spawn position







	
