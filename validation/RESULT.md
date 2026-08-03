# EDEN//FALL production validation

- Result: **FAIL**
- Source commit: `0b445e7a7a00acd40aa3173ec64d2d008cce2b80`
- Import/parse exit: `0`
- Content contract exit: `1`
- Main-scene boot exit: `0`

## Import/parse tail
```text
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org

ERROR: Error opening file 'res://assets/generated/ui/boot_splash.png'.
   at: load_image (core/io/image_loader.cpp:89)
ERROR: Non-existing or invalid boot splash at 'res://assets/generated/ui/boot_splash.png'.  Loading default splash.
   at: setup_boot_logo (main/main.cpp:3855)
[   0% ] [90m[1mfirst_scan_filesystem[22m | Started Project initialization (5 steps)[39m[0m
[   0% ] [90m[1mfirst_scan_filesystem[22m | Scanning file structure...[39m[0m
[  16% ] [90m[1mfirst_scan_filesystem[22m | Loading global class names...[39m[0m
[  33% ] [90m[1mfirst_scan_filesystem[22m | Verifying GDExtensions...[39m[0m
[  50% ] [90m[1mfirst_scan_filesystem[22m | Creating autoload scripts...[39m[0m
[  66% ] [90m[1mfirst_scan_filesystem[22m | Initializing plugins...[39m[0m
[  83% ] [90m[1mfirst_scan_filesystem[22m | Starting file scan...[39m[0m
[92m[ DONE ][39m [1mfirst_scan_filesystem[22m
[0m
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
SCRIPT ERROR: Parse Error: Invalid argument for "draw_texture_rect_region()" function: argument 1 should be "Texture2D" but is "Rect2".
          at: GDScript::reload (res://scripts/game_runtime.gd:206)
SCRIPT ERROR: Parse Error: Invalid argument for "draw_texture_rect_region()" function: argument 2 should be "Rect2" but is "Texture2D".
          at: GDScript::reload (res://scripts/game_runtime.gd:206)
SCRIPT ERROR: Parse Error: Cannot infer the type of "fps" variable because the value doesn't have a set type.
          at: GDScript::reload (res://scripts/game_runtime.gd:226)
SCRIPT ERROR: Parse Error: Cannot infer the type of "flip" variable because the value doesn't have a set type.
          at: GDScript::reload (res://scripts/game_runtime.gd:277)
SCRIPT ERROR: Parse Error: Invalid argument for "draw_texture_rect_region()" function: argument 1 should be "Texture2D" but is "Rect2".
          at: GDScript::reload (res://scripts/game_runtime.gd:333)
SCRIPT ERROR: Parse Error: Invalid argument for "draw_texture_rect_region()" function: argument 2 should be "Rect2" but is "Texture2D".
          at: GDScript::reload (res://scripts/game_runtime.gd:333)
ERROR: Failed to load script "res://scripts/game_runtime.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript.cpp:2907)
```

## Content validation tail
```text
Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org

ERROR: Error opening file 'res://assets/generated/ui/boot_splash.png'.
   at: load_image (core/io/image_loader.cpp:89)
ERROR: Non-existing or invalid boot splash at 'res://assets/generated/ui/boot_splash.png'.  Loading default splash.
   at: setup_boot_logo (main/main.cpp:3855)
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

ERROR: Error opening file 'res://assets/generated/ui/boot_splash.png'.
   at: load_image (core/io/image_loader.cpp:89)
ERROR: Non-existing or invalid boot splash at 'res://assets/generated/ui/boot_splash.png'.  Loading default splash.
   at: setup_boot_logo (main/main.cpp:3855)
SCRIPT ERROR: Parse Error: Could not resolve class "res://scripts/game.gd".
          at: GDScript::reload (res://scripts/game_runtime.gd:1)
SCRIPT ERROR: Parse Error: Invalid argument for "draw_texture_rect_region()" function: argument 1 should be "Texture2D" but is "Rect2".
          at: GDScript::reload (res://scripts/game_runtime.gd:206)
SCRIPT ERROR: Parse Error: Invalid argument for "draw_texture_rect_region()" function: argument 2 should be "Rect2" but is "Texture2D".
          at: GDScript::reload (res://scripts/game_runtime.gd:206)
SCRIPT ERROR: Parse Error: Cannot infer the type of "fps" variable because the value doesn't have a set type.
          at: GDScript::reload (res://scripts/game_runtime.gd:226)
SCRIPT ERROR: Parse Error: Cannot infer the type of "flip" variable because the value doesn't have a set type.
          at: GDScript::reload (res://scripts/game_runtime.gd:277)
SCRIPT ERROR: Parse Error: Invalid argument for "draw_texture_rect_region()" function: argument 1 should be "Texture2D" but is "Rect2".
          at: GDScript::reload (res://scripts/game_runtime.gd:333)
SCRIPT ERROR: Parse Error: Invalid argument for "draw_texture_rect_region()" function: argument 2 should be "Rect2" but is "Texture2D".
          at: GDScript::reload (res://scripts/game_runtime.gd:333)
ERROR: Failed to load script "res://scripts/game_runtime.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript.cpp:2907)
```
