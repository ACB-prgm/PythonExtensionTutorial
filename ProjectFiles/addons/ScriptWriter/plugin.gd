tool
extends EditorPlugin


# YOU CAN TOUCH
const WAKE = "#/"
const CPM = 1000
const PAUSE_BETWEEN = 0

# NO TOUCHY
var from_script : String  # path
var current_text_edit : TextEdit
var timer : Timer


# VIRTUAL FUNCTIONS ————————————————————————————————————————————————————————————————————————————————
func _enter_tree():
	var editor_interface = get_editor_interface()
	var script_editor = editor_interface.get_script_editor()
	
	script_editor.connect("editor_script_changed", self, "_on_editor_script_changed")
	
	add_timer()


func _exit_tree():
	pass


# SCRIPT PARSING FUNCTIONS —————————————————————————————————————————————————————————————————————————
func _on_editor_script_changed(script):
	var editor_interface = get_editor_interface()
	var script_editor = editor_interface.get_script_editor()
	var textEdit = get_active_text_edit(script_editor)
	
	if !textEdit.is_connected("text_changed", self, "_on_script_text_changed"):
		if is_instance_valid(current_text_edit):
			current_text_edit.disconnect("text_changed", self, "_on_script_text_changed")
		textEdit.connect("text_changed", self, "_on_script_text_changed", [textEdit])
	
	current_text_edit = textEdit


func _on_script_text_changed(textEdit:TextEdit):
	if WAKE + "clear" in textEdit.text:
		textEdit.text = ""
	
	elif WAKE + "from" in textEdit.text:
		textEdit.text = textEdit.text.replace(WAKE + "from", "")
		from_script = textEdit.text
		save_settings()
		print("From script successfully saved")
	
	elif WAKE + "to" in textEdit.text:
		load_settings()
		
		if !from_script:
			print("NO from SCRIPT DETECTED")
			return
		
		textEdit.set_text("") # clear to_script
		write_to(parse_script_text(from_script), textEdit)


func get_prev_block(blocks, idx, current_block):
	if idx < 0:
		return null
	
	var prev_block = blocks[idx - 1]
	if prev_block[0] > current_block:
		return get_prev_block(blocks, idx-1, current_block)
	else:
		return prev_block[1]


func write_to(blocks:Array, textEdit:TextEdit) -> void:
	add_timer()
	timer.set_wait_time(60.0 / CPM) # set time between characrters by chars per minute
	
	var settings = get_editor_interface().get_editor_settings() # "turn off" code suggestions
	var prev_delay = settings.get("text_editor/completion/code_complete_delay")
	settings.set_setting("text_editor/completion/code_complete_delay", 5.0)
	settings.emit_signal("settings_changed")
	yield(get_tree().create_timer(0.5), "timeout")
	
	for block_num in blocks.size(): # writes at least for each block_num
		if PAUSE_BETWEEN:
				timer.set_wait_time(PAUSE_BETWEEN)
				timer.start()
				yield(timer, "timeout")
				timer.set_wait_time(60.0 / CPM)
		
		for idx in blocks.size(): # essentially enumerating the 2D blocks array
			var block = blocks[idx] # get the actual block
			
			if block[0] == block_num: # check if we are writing that block num
				var pos = null # this block adds space to write insertions
				if block[0] > 0:
					if idx == 0: # edge case where block is written before first block
							pos = 0
					elif idx > 0:
						var prev_block = get_prev_block(blocks, idx, block_num)
						pos = textEdit.text.find(prev_block) + prev_block.length()
					
					textEdit.text = textEdit.text.insert(pos, "\n\n")
					pos += block[1].length()
					
				for char_num in block[1].length():
					timer.start()
					yield(timer, "timeout")
					
					var character = block[1][char_num]
					var write_pos : int
					if block_num == 0: # this is the first block
						write_pos = textEdit.text.length()
					else: # block > 0
						if idx == 0: # edge case where block is written before first block
							write_pos = char_num
						elif idx > 0:
							var prev_block = get_prev_block(blocks, idx, block_num)
							write_pos = textEdit.text.find(prev_block) + prev_block.length() + char_num
					
					textEdit.text = textEdit.text.insert(write_pos, character)
					var line_count = textEdit.text.left(write_pos).count("\n") # num lines to current char
					textEdit.cursor_set_line(line_count)
					textEdit.cursor_set_column(textEdit.text.split("\n")[line_count].length()) # num chars on current line
				
				if pos: # cleans up spaces from intertion buffer
					var text = textEdit.text
					text.erase(pos, 2)
					textEdit.text = text

	settings.set_setting("text_editor/completion/code_complete_delay", prev_delay)


func parse_script_text(text:String) -> Array:
	# returns an 2D array of [block_num:int, block_text:String], with the idx corresponding
	# to the order of the blocks in the script.  The minimum block_num will always be 0.
	var blocks := []
	
	var blocks_raw := text.split(WAKE)
	for block in blocks_raw:
		if block and block[0].is_valid_integer():
			var block_num = int(block[0])
			
			block = PoolStringArray(block.split("\n"))
			block.remove(0) # remove line with WAKE word
			block = block.join("\n")
			
			blocks.append([block_num, block])
	
	if blocks: # make 0 the min block_num
		var block_nums := []
		for block in blocks:
			block_nums.append(block[0])
		var min_block_num = block_nums.min()
		
		if min_block_num > 0:
			for block in blocks:
				block[0] -= min_block_num
	else:
		blocks = [[0, text]]
	
	return blocks


# SAVE/LOAD SETTINGS FUNCTIONS —————————————————————————————————————————————————————————————————————
func load_settings():
	var path = get_config_path()
	var dir = Directory.new()
	var config = ConfigFile.new()
	
	if dir.file_exists(path):
		var ERR = config.load(path)
		if ERR == OK:
			from_script = config.get_value("settings", "from_path")
		else:
			push_error("ScriptWriter plugin unable to load settings. ERR = %s" % ERR)
	else:
		dir.make_dir_recursive(path.get_base_dir())
		config.save(path)

func save_settings():
	if from_script:
		var config = ConfigFile.new()
		config.set_value("settings", "from_path", from_script)
		config.save(get_config_path())
	else:
		push_error("ScriptWriter plugin unable to save settings.  from_script == null")

func get_config_path():
	var dir = get_editor_interface().get_editor_settings().get_project_settings_dir()
	var path = dir.plus_file("ScriptWriter/ScriptWriterSave.cfg")
	return path


# GET ACTIVE TEXTEDIT FUNCTIONS ————————————————————————————————————————————————————————————————————
func find_all_nodes_by_name(root, name) -> Array:
	var found_nodes : Array
	if(name in root.get_name()): found_nodes.append(root)
	for child in root.get_children():
		found_nodes.append_array(find_all_nodes_by_name(child, name))
	return found_nodes


func fetch_all_script_text_editors(script_editor) -> Array:
	var found_script_text_editors : Array
	found_script_text_editors = find_all_nodes_by_name(script_editor, "ScriptTextEditor")
	return found_script_text_editors


func get_active_text_edit(script_editor) -> TextEdit:
	for script_text_editor in fetch_all_script_text_editors(script_editor):
		if script_text_editor.is_visible():
			return script_text_editor.get_node("VSplitContainer/CodeTextEditor/TextEdit")
	return null


# MISC FUNCTIONS ———————————————————————————————————————————————————————————————————————————————————
func add_timer() -> void:
	if !timer:
		timer = Timer.new()
		add_child(timer)
		timer.set_one_shot(true)
