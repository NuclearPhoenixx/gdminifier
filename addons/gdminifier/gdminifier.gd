@tool
extends EditorPlugin


var export_plugin: GDMinifierExportPlugin


func _enter_tree() -> void:
	print("GD Minifier Plugin: Loaded")
	export_plugin = GDMinifierExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	print("GD Minifier Plugin: Unloaded")
	if export_plugin:
		remove_export_plugin(export_plugin)
		export_plugin = null


# Plugin: Entfernt Kommentare und leere Zeilen aus GDScript- und GDShader-Dateien bei Export
class GDMinifierExportPlugin extends EditorExportPlugin:
	var _is_debug_build: bool = false
	var _file_counter: int = 0
	
	
	func _get_name() -> String:
		return "GD Minifier"
	
	
	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		_is_debug_build = is_debug
		
		if not is_debug:
			prints(_get_name(), ": Minifying files for production build...")
	
	
	func _export_end() -> void:
		prints(_get_name(), ": Minified", _file_counter, "files.")
	
	
	func _export_file(path: String, type: String, features: PackedStringArray) -> void:
		if _is_debug_build: # Only minify production builds
			return
		
		# NOTE .gd files don't currently work, and would only get larger anyways due to the engine
		#	using efficient byte code and I'm just here doing random stuff
		#if path.ends_with(".gd"):
			#var src: FileAccess = FileAccess.open(path, FileAccess.READ)
			#if src:
				#var content: String = src.get_as_text()
				#src.close()
				#content = _strip_gd_comments(content)
				#add_file(path, content.to_utf8_buffer(), false)
				#prints("Stripped:", path)
			#return
		
		# Compressing JSON files
		if path.ends_with(".json"):
			var src: FileAccess = FileAccess.open(path, FileAccess.READ)
			if src:
				var content: String = src.get_as_text()
				src.close()
				content = _minify_json(content)
				skip() # Skip this file, we will write it manually on the next line
				add_file(path, content.to_utf8_buffer(), false)
				#prints("Minified:", path)
				_file_counter += 1
			return
		
		# Stripping from .gdshader works just fine
		if path.ends_with(".gdshader"):
			var src: FileAccess = FileAccess.open(path, FileAccess.READ)
			if src:
				var content: String = src.get_as_text()
				src.close()
				content = _minify_gdshader(content)
				skip() # Skip this file, we will write it manually on the next line
				add_file(path, content.to_utf8_buffer(), false)
				#prints("Minified:", path)
				_file_counter += 1
			return
		
		# Strip empty lines from .tres files.
		# NOTE Stripping from .tscn files actually makes the export larger!
		if path.ends_with(".tres"):
			var src: FileAccess = FileAccess.open(path, FileAccess.READ)
			if src:
				var content: String = src.get_as_text()
				src.close()
				content = _strip_empty_lines(content)
				skip() # Skip this file, we will write it manually on the next line
				add_file(path, content.to_utf8_buffer(), false)
				#prints("Minified:", path)
				_file_counter += 1
			return
		
		# Strip empty lines from media file .import files.
		# NOTE This also doesn't work...
		#if path.ends_with(".ogg") or path.ends_with(".png") or path.ends_with(".mp3") or path.ends_with(".wav"):
			#path += ".import"
			#var src: FileAccess = FileAccess.open(path, FileAccess.READ)
			#if src:
				#var content: String = src.get_as_text()
				#src.close()
				#content = _strip_empty_lines(content)
				##skip() # Skip this file, we will write it manually on the next line
				#add_file(path, content.to_utf8_buffer(), false)
				#prints("Minified:", path)
			#return


	#func _strip_gd_comments(content: String) -> String:
		## Remove comments from GDScript content.
		#var lines: PackedStringArray = content.split("\n")
		#var stripped_lines: Array[String] = []
		#var in_multiline_comment: bool = false
		#
		#for line: String in lines:
			#var stripped_line: String = line
			#
			## Handle multi-line comments (""")
			#if not in_multiline_comment:
				#var start_pos: int = stripped_line.find('"""')
				#if start_pos >= 0:
					#var end_pos: int = stripped_line.find('"""', start_pos + 3)
					#if end_pos >= 0:
						## Comment ends on same line
						#stripped_line = stripped_line.substr(0, start_pos) + stripped_line.substr(end_pos + 3)
					#else:
						## Comment continues to next line
						#stripped_line = stripped_line.substr(0, start_pos)
						#in_multiline_comment = true
			#else:
				#var end_pos: int = stripped_line.find('"""')
				#if end_pos >= 0:
					## Comment ends on this line
					#stripped_line = stripped_line.substr(end_pos + 3)
					#in_multiline_comment = false
				#else:
					## Comment continues, skip this line entirely
					#stripped_line = ""
			#
			## Only process single-line comments if not in multi-line comment
			#if not in_multiline_comment and stripped_line != "":
				## Find # but ignore if it's inside a string
				#var comment_pos: int = -1
				#var in_string: bool = false
				#var i: int = 0
				#
				#while i < stripped_line.length():
					#var char: String = stripped_line[i]
					#if char == '"' and (i == 0 or stripped_line[i - 1] != '\\'):
						#in_string = !in_string
					#elif char == '#' and not in_string:
						#comment_pos = i
						#break
					#i += 1
				#
				#if comment_pos >= 0:
					#stripped_line = stripped_line.substr(0, comment_pos)
			#
			## Remove empty lines
			#if stripped_line.strip_edges() != "":
				#stripped_lines.append(stripped_line.strip_edges())
		#
		#return "\n".join(stripped_lines)


	func _strip_empty_lines(content: String) -> String:
		var lines: Array = content.split("\n")
		var stripped_lines: Array = []
		
		for line in lines:
			if line.strip_edges() != "":
				stripped_lines.append(line.strip_edges())
		
		return "\n".join(stripped_lines)


	func _minify_json(content: String) -> String:
		var json: JSON = JSON.new()
		var result = json.parse(content)
		
		if not result == OK:
			push_error("Invalid JSON!")
			return ""
		
		return json.stringify(json.data)


	func _minify_gdshader(content: String) -> String:
		# Remove all // and /* */ comments and collapse to a single line.
		var in_multiline_comment: bool = false
		var result: String = ""
		var i: int = 0
		
		while i < content.length():
			if in_multiline_comment:
				var end_pos: int = content.find("*/", i)
				if end_pos == -1:
					break  # no end, rest is comment
				i = end_pos + 2
				in_multiline_comment = false
				continue
			
			if i + 1 < content.length() and content.substr(i, 2) == "//":
				# skip to newline
				var newline_pos: int = content.find("\n", i)
				if newline_pos == -1:
					break
				i = newline_pos + 1
				continue
			
			if i + 1 < content.length() and content.substr(i, 2) == "/*":
				in_multiline_comment = true
				i += 2
				continue
			
			var ch: String = content[i]
			# replace newline and tabs by space to flatten
			if ch == '\n' or ch == '\r' or ch == '\t':
				result += " "
			else:
				result += ch
			i += 1
		
		# remove multiple spaces and trim
		result = result.strip_edges()
		while result.find("  ") != -1:
			result = result.replace("  ", " ")
		
		return result
