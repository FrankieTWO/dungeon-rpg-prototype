extends Node

@onready var floor_layer: TileMapLayer = $floor_layer
@onready var wall_layer: TileMapLayer = $wall_layer
@onready var player_scene = preload("res://scenes/Player.tscn")  # Adjust the path to your Player scene

var player_instance: Node = null
var spawn_point = Vector2(5, 5)  # Adjust this based on where you want the player to spawn
const VERT_WALL_TILE = Vector2i(0, 1)
const MIDDLE_WALL_TILE = Vector2i(2, 3)
const LEFTBOTTOM_WALL_TILE = Vector2i(1, 2)
const RIGHTBOTTOM_WALL_TILE = Vector2i(3, 2)
const RIGHTTOP_WALL_TILE = Vector2i(3, 0)
const LEFTTOP_WALL_TILE = Vector2i(1, 0)
const FLOOR_TILE = Vector2i(1, 0)  # Floor tile constant
# Generate the dungeon when the HUD button is pressed
func _on_hud_new_dungeon() -> void:
	floor_layer.clear()
	wall_layer.clear()
	generate_dungeon()
	add_player()

# Generate a simple room-based dungeon
func generate_dungeon():
	# Generate a simple room or dungeon layout here...
	create_room(Rect2(Vector2(5, 5), Vector2(10, 10)))  # Example of room generation

func create_room(room: Rect2):
	for x in range(room.position.x, room.position.x + room.size.x):
		for y in range(room.position.y, room.position.y + room.size.y):
			floor_layer.set_cell(Vector2i(x, y), 0, FLOOR_TILE)

	# Add walls
	for x in range(room.position.x - 1, room.position.x + room.size.x + 1):
		wall_layer.set_cell(Vector2i(x, room.position.y - 1), 1, MIDDLE_WALL_TILE)
		wall_layer.set_cell(Vector2i(x, room.position.y + room.size.y), 1, MIDDLE_WALL_TILE)

	for y in range(room.position.y - 1, room.position.y + room.size.y + 1):
		wall_layer.set_cell(Vector2i(room.position.x - 1, y), 1, VERT_WALL_TILE)
		wall_layer.set_cell(Vector2i(room.position.x + room.size.x, y), 1, VERT_WALL_TILE)

# Add the player to the scene once the dungeon is generated
func add_player():
	if player_instance != null:
		player_instance.queue_free()  # Remove the old player if it exists

	player_instance = player_scene.instantiate()  # Create a new instance of the player
	player_instance.position = spawn_point  # Set the spawn point for the player
	add_child(player_instance)  # Add the player to the scene
