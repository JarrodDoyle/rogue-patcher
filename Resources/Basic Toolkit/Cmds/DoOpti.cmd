set_lighting_mode 2
compress_br_ids
clear_surface_cache
set no_auto_relight 1
set_lighting_mode 0
optimize
run .\Cmds\DoLight.cmd
save_mission Done.mis
ai_build_path_database
rooms_build
build_ai_room_database
save_mission Done.mis
play_schema camto3
