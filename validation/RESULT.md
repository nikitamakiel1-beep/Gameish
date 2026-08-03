# EDEN//FALL production validation

- Result: **FAIL**
- Source commit: `ba879e962284daeaddb39cf1168811c50de08143`
- Import/parse exit: `0`
- Content contract exit: `1`
- Main-scene boot exit: `0`

## Import/parse tail
```text
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org

ERROR: Non-existing or invalid boot splash at 'res://icon.svg'. The only supported format is PNG. Loading default splash.
   at: setup_boot_logo (main/main.cpp:3855)
ERROR: res://default_bus_layout.tres:1 - Parse Error: Missing 'type' field in 'gd_resource' tag.
   at: _printerr (scene/resources/resource_format_text.cpp:40)
ERROR: Failed loading resource: res://default_bus_layout.tres.
   at: _load (core/io/resource_loader.cpp:343)
[   0% ] [90m[1mfirst_scan_filesystem[22m | Started Project initialization (5 steps)[39m[0m
[   0% ] [90m[1mfirst_scan_filesystem[22m | Scanning file structure...[39m[0m
[  16% ] [90m[1mfirst_scan_filesystem[22m | Loading global class names...[39m[0m
[  33% ] [90m[1mfirst_scan_filesystem[22m | Verifying GDExtensions...[39m[0m
[  50% ] [90m[1mfirst_scan_filesystem[22m | Creating autoload scripts...[39m[0m
[  66% ] [90m[1mfirst_scan_filesystem[22m | Initializing plugins...[39m[0m
[  83% ] [90m[1mfirst_scan_filesystem[22m | Starting file scan...[39m[0m
[92m[ DONE ][39m [1mfirst_scan_filesystem[22m
[0m
ERROR: res://default_bus_layout.tres:1 - Parse Error: Missing 'type' field in 'gd_resource' tag.
   at: _printerr (scene/resources/resource_format_text.cpp:40)
ERROR: res://default_bus_layout.tres:1 - Parse Error: Missing 'type' field in 'gd_resource' tag.
   at: _printerr (scene/resources/resource_format_text.cpp:40)
ERROR: Condition "error != OK" is true.
   at: get_dependencies (scene/resources/resource_format_text.cpp:928)
[   0% ] [90m[1mupdate_scripts_classes[22m | Started Registering global classes... (6 steps)[39m[0m
[   0% ] [90m[1mupdate_scripts_classes[22m | AssetCatalog[39m[0m
[  14% ] [90m[1mupdate_scripts_classes[22m | EdenAudioDirector[39m[0m
[  28% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[  42% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[  57% ] [90m[1mupdate_scripts_classes[22m | GameData[39m[0m
[  71% ] [90m[1mupdate_scripts_classes[22m | [39m[0m
[92m[ DONE ][39m [1mupdate_scripts_classes[22m
[0m
[   0% ] [90m[1mreimport[22m | Started (Re)Importing Assets (1 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Preparing files to reimport...[39m[0m
[   0% ] [90m[1mreimport[22m | Executing pre-reimport operations...[39m[0m
[   0% ] [90m[1mreimport[22m | icon.svg[39m[0m
[  50% ] [90m[1mreimport[22m | Finalizing Asset Import...[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mreimport[22m | Started (Re)Importing Assets (1 steps)[39m[0m
[   0% ] [90m[1mreimport[22m | Executing post-reimport operations...[39m[0m
[92m[ DONE ][39m [1mreimport[22m
[0m
[   0% ] [90m[1mloading_editor_layout[22m | Started Loading editor (5 steps)[39m[0m
[   0% ] [90m[1mloading_editor_layout[22m | Loading editor layout...[39m[0m
[  16% ] [90m[1mloading_editor_layout[22m | Loading docks...[39m[0m
[92m[ DONE ][39m [1mloading_editor_layout[22m
[0m
SCRIPT ERROR: Parse Error: Could not resolve class "res://scripts/game.gd".
          at: GDScript::reload (res://scripts/game_runtime.gd:1)
ERROR: Failed to load script "res://scripts/game_runtime.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript.cpp:2907)
```

## Content validation tail
```text
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org

ERROR: Non-existing or invalid boot splash at 'res://icon.svg'. The only supported format is PNG. Loading default splash.
   at: setup_boot_logo (main/main.cpp:3855)
ERROR: res://default_bus_layout.tres:1 - Parse Error: Missing 'type' field in 'gd_resource' tag.
   at: _printerr (scene/resources/resource_format_text.cpp:40)
ERROR: Failed loading resource: res://default_bus_layout.tres.
   at: _load (core/io/resource_loader.cpp:343)
ERROR: Attempt to open script 'res://tests/content_validation.gd' resulted in error 'File not found'.
   at: load_source_code (modules/gdscript/gdscript.cpp:1127)
ERROR: Failed loading resource: res://tests/content_validation.gd.
   at: _load (core/io/resource_loader.cpp:343)
ERROR: Can't load script: res://tests/content_validation.gd
   at: start (main/main.cpp:4271)
```

## Boot tail
```text
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org

ERROR: Non-existing or invalid boot splash at 'res://icon.svg'. The only supported format is PNG. Loading default splash.
   at: setup_boot_logo (main/main.cpp:3855)
ERROR: res://default_bus_layout.tres:1 - Parse Error: Missing 'type' field in 'gd_resource' tag.
   at: _printerr (scene/resources/resource_format_text.cpp:40)
ERROR: Failed loading resource: res://default_bus_layout.tres.
   at: _load (core/io/resource_loader.cpp:343)
SCRIPT ERROR: Parse Error: Could not resolve class "res://scripts/game.gd".
          at: GDScript::reload (res://scripts/game_runtime.gd:1)
ERROR: Failed to load script "res://scripts/game_runtime.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript.cpp:2907)
```
