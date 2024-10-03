extends CanvasLayer

signal new_dungeon



func _on_button_pressed() -> void:
	new_dungeon.emit()
