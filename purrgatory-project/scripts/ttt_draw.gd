extends Control
var draw_material
var to_draw = []
var to_erase = false
var to_load_mural = false
	
var texture

func _on_draw():
	self.material= CanvasItemMaterial.new()
	if to_draw.size() > 0:
		self.material.set_blend_mode(BLEND_MODE_ADD)
		draw_line(to_draw[0][0], to_draw[to_draw.size() - 1][1], Color(0, 0, 0, 1), 1, false)
		to_draw = []
	
	if to_erase:
		to_erase = false
		self.material.set_blend_mode(BLEND_MODE_MUL)
		draw_rect(Rect2(0,0,1280,720),Color(0,0,0,0),true)
		
	if to_load_mural:
		to_load_mural = false
		self.material.set_blend_mode(BLEND_MODE_ADD)
		if($"../../loaded_texture".texture):
			draw_texture($"../../loaded_texture".texture,Vector2())
		
		
		

	
func _process(delta):
	update()
