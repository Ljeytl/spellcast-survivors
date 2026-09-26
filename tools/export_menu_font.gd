extends SceneTree

func _initialize():
	var glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_/\\+=[]{}',?.:;!~`$#@%^&*()<>|\""
	var atlas = Image.create(384, 192, false, Image.FORMAT_RGBA8)
	var locations = {}
	for i in range(glyphs.length()):
		var glyph = glyphs[i]
		var name = glyph if i < 26 else "u%04x" % glyph.unicode_at(0)
		var source = Image.load_from_file("res://assets/typecast/Keys/" + name + ".png")
		var position = Vector2i((i % 12) * 32, (i / 12) * 32)
		atlas.blit_rect(source, Rect2i(0, 0, 32, 32), position)
		locations[glyph] = position
	atlas.save_png("res://assets/typecast/Keys/menu-font.png")
	var data = "info face=\"Stone Keys\" size=32 bold=0 italic=0 charset=\"\" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=2,4\n"
	data += "common lineHeight=36 base=32 scaleW=384 scaleH=192 pages=1 packed=0\npage id=0 file=\"menu-font.png\"\nchars count=95\n"
	for code in range(32, 127):
		var glyph = String.chr(code).to_upper()
		var position = locations.get(glyph, Vector2i.ZERO)
		var width = 0 if code == 32 else 32
		data += "char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15\n" % [code, position.x, position.y, width, width, 16 if code == 32 else 34]
	var file = FileAccess.open("res://assets/typecast/Keys/menu-font.fnt", FileAccess.WRITE)
	file.store_string(data)
	quit()
