extends RefCounted
class_name UIIconLibrary

static var _content_db: ContentDB
static var _texture_cache: Dictionary = {}


static func get_icon_spec(entry_id: String) -> Dictionary:
	if _content_db == null:
		_content_db = ContentDB.new()
	return _content_db.get_icon_spec(entry_id)


static func get_icon_texture(entry_id: String) -> Texture2D:
	return texture_from_spec(get_icon_spec(entry_id))


static func texture_from_spec(icon_spec: Dictionary) -> Texture2D:
	var path: String = String(icon_spec.get("path", ""))
	if path.is_empty():
		return null

	var raw_region: Variant = icon_spec.get("region", [])
	var cache_key: String = "%s|%s" % [path, str(raw_region)]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D

	var base_texture: Texture2D = load(path) as Texture2D
	if base_texture == null:
		return null

	var result: Texture2D = base_texture
	if raw_region is Array and (raw_region as Array).size() == 4:
		var region: Array = raw_region as Array
		var atlas := AtlasTexture.new()
		atlas.atlas = base_texture
		atlas.region = Rect2(
			float(region[0]),
			float(region[1]),
			float(region[2]),
			float(region[3])
		)
		result = atlas

	_texture_cache[cache_key] = result
	return result
