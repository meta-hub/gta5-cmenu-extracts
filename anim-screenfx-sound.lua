--[[

  --------------------------------------------
  -- Usage
  --------------------------------------------
  local ANIM, SCREENFX, SOUND = dofile("GTALua/addons/cmenu/gta5-anim-screenfx-sound.lua")

  -- Or, without local, to offer services globally.

  ANIM, SCREENFX, SOUND = dofile("GTALua/addons/cmenu/gta5-anim-screenfx-sound.lua")

  --------------------------------------------
  -- Function List
  --------------------------------------------

    ANIM:Find(searchString,indexStart,indexLen)
    ANIM:moveEntityRelative(ent,xrel,yrel,zrel,hrel)
    ANIM:resetPedAnim(ent,quiet)

    SCREENFX.Find(ScreenFX,index)
    SCREENFX.Play(ScreenFX)
    SCREENFX.Stop(ScreenFX)

    SOUND.Find(searchString,indexLow,indexHigh)

    SOUND:Play( curSoundInput, curSoundOrigin, curSoundID ) - Returns SoundID
                curSoundInput  = Should be any one of the entries from SOUND.list,  example:  SOUND:Play( SOUND.list[3] )
                curSoundOrigin = Can be string "FRONTEND" , or numeric entity id, or a Vector.
                curSoundID     = Can be nil.  Only required if you need to track the sound (i.e. looping sounds that you can only kill by SoundID )

    UTILS.notify(msg)

  ----------------------------------------------
  -- List List
  ----------------------------------------------

    SCREENFX.list 
    SOUND.list

--]]

--[[
    A note on anims:

    Use with:

    natives.AI.TASK_PLAY_ANIM
    natives.AI.TASK_PLAY_ANIM_FACIAL
    natives.AI.TASK_PLAY_ANIM_NON_INTERRUPTABLE
    natives.AI.TASK_PLAY_ANIM_READY_TO_BE_EXECUTED
    natives.AI.TASK_PLAY_ANIM_SECONDARY
    natives.AI.TASK_PLAY_ANIM_SECONDARY_IN_CAR
    natives.AI.TASK_PLAY_ANIM_SECONDARY_NO_INTERRUPT
    natives.AI.TASK_PLAY_ANIM_SECONDARY_UPPER_BODY
    natives.AI.TASK_PLAY_ANIM_UPPER_BODY
    natives.AI.TASK_PLAY_ANIM_WITH_ADVANCED_FLAGS
    natives.AI.TASK_PLAY_ANIM_WITH_FLAGS
    natives.PED.SET_FACIAL_IDLE_ANIM_OVERRIDE

    -- Sync animations also work for peds and objects! Here's a synced animation of Franklin opening the door to his house.
    -- It works the same way except we need to replace the second ped with the "door " object (door model hash is "520341586") and use PLAY_SYNCHRONIZED_ENTITY_ANIM() native instead:

    streaming.RequestModel(520341586)
    object = natives.OBJECT.CREATE_OBJECT(520341586, playerPosition.x,playerPosition.y,playerPosition.z, true, true, false)
    streaming.RequestAnimDict("misstimelapse@franklinold_home")
    scene = natives.PED.CREATE_SYNCHRONIZED_SCENE(playerPosition.x,playerPosition.y,playerPosition.z, 0.0, 0.0, 180.0, 2)
    natives.AI.TASK_SYNCHRONIZED_SCENE(playerPed, scene, "misstimelapse@franklinold_home", "franklin_enters_old_home", 1000.0, -1000.0, 0, 0, 0x447a0000, 0)
    natives.ENTITY.PLAY_SYNCHRONIZED_ENTITY_ANIM(object, scene, "franklin_enters_old_home_door", "misstimelapse@franklinold_home", 1000.0, -1000.0, 0, 0x447a0000)

    -- I don't know of any natives for that so I use a GTALua timer that clears ped tasks when I want. For example this one stops the animation after 10 seconds:

    timer.Simple(10000, function()  natives.AI.CLEAR_PED_TASKS_IMMEDIATELY(playerPed)  end, "" )

--]]


ANIM     = {}
SCREENFX = {}
SOUND    = {}
SOUND.id = {}

ANIM.queue1     = {}
ANIM.queue3     = {}

SCREENFX.queue  = {}
SCREENFX.silent = false

SCREENFX.list = {
"Cam Push In Franklin",          "Cam Push In Michael",            "Cam Push In Neutral",            "Cam Push In Trevor",
"Chop Vision",                   "DMT_flight",                     "DMT_flight_intro",               "Death Fail MP Dark",
"Death Fail MP In",              "Death Fail Neutral In",          "Death Fail Out",
"Dont_tazeme_bro",               "Drugs Driving In",               "Drugs Driving Out",              "Drugs Michael Aliens Fight",
"Drugs Michael Aliens Fight In", "Drugs Michael Aliens Fight Out", "DrugsTrevorClownsFight",         "Drugs Trevor Clowns Fight In",
"Drugs Trevor Clowns Fight Out", "Explosion Josh3",                "FocusIn",                        "Focus Out",
"Heist Celeb End",               "Heist Celeb Pass",               "HeistCelebPassBW",               "Heist Celeb Toast",
"Heist Locate",                  "Heist Trip Skip Fade",           "MP_Celeb_Lose",                  "MP_Celeb_Lose_Out",
"MP_Celeb_Preload_Fade",         "MP_Celeb_Win",                   "MP_Celeb_Win_Out",               "MP_corona_switch",
"MP_intro_logo",                 "MP_job_load",                    "MP_race_crash",                  "Menu MG Heist In",
"Menu MG Heist Out",             "Menu MG Selection In",           "Menu MG Selection Tint",         "Menu MG Tournament In",
"Minigame End Franklin",         "Minigame End Michael",           "Minigame End Neutral",           "Minigame End Trevor",
"Minigame Transition In",        "Minigame Transition Out",        "Peyote End In",                  "Peyote End Out",
"Peyote In",                     "Peyote Out",                     "Race Turbo",                     "Rampage",
"Rampage Out",                   "Sniper Overlay",                 "Success Franklin",               "Success Michael",
"Success Neutral",               "Success Trevor",                 "Switch HUD Franklin Out",        "Switch HUD In",
"Switch HUD Michael Out",        "Switch HUD Out",                 "Switch HUD Trevor Out",          "Switch Open Franklin In",
"Switch Open Michael In",        "Switch Open Neutral FIB5",       "Switch Open Trevor In",
"Switch Scene Franklin",         "Switch Scene Michael",           "Switch Scene Neutral",           "Switch Scene Trevor",
"Switch Short Franklin In",      "Switch Short Franklin Mid",      "Switch Short Michael In",        "Switch Short Michael Mid",
"Switch Short Neutral In",       "Switch Short Trevor In",         "Switch Short Trevor Mid",
"DeadlineNeon",                  "PPPurple",                       "PPGreen",                        "PPOrange",
"PPPink",
}

table.sort(SCREENFX.list)

for k,v in pairs(SCREENFX.list) do
    local newV = string.gsub(v," ","")
    SCREENFX.list[newV] = v
    SCREENFX.list[v] = v
end


--[[

----------------------
--      Sounds      --
----------------------

Example:
  natives.AUDIO.PLAY_SOUND_FRONTEND(-1, "Pin_Centred", "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", false)

Or, use SOUND:Play()
  SOUND:Play("ASSASSINATIONS_HOTEL_TIMER_COUNTDOWN:ASSASSINATION_MULTI")

--]]

SOUND.queue  = {}

SOUND.sfx_list = {
        "railgun_boom:0",
        "railgun_boom_l:0",
        "railgun_boom.l:0",
        "assassinations_hotel_timer_countdown"  ..":".. "assassination_multi",
        "pin_button"                            ..":".. "atm_sounds",
        "hooray"                                ..":".. "barry_02_soundset",
        "grab_parachute"                        ..":".. "basejumps_sounds",
        "traffic_control_bg_noise"              ..":".. "big_score_3a_sounds",
        "traffic_control_change_cam"            ..":".. "big_score_3a_sounds",
        "traffic_control_move_crosshair"        ..":".. "big_score_3a_sounds",
        "traffic_control_toggle_light"          ..":".. "big_score_3a_sounds",
        "traffic_control_fail"                  ..":".. "big_score_3a_sounds",
        "traffic_control_fail_blank"            ..":".. "big_score_3a_sounds",
        "traffic_control_light_switch_back"     ..":".. "big_score_3a_sounds",
        "camera_hum"                            ..":".. "big_score_setup_sounds",
        "camera_zoom"                           ..":".. "big_score_setup_sounds",
        "diggerrevoneshot"                      ..":".. "bulldozerdefault",
        "distant_dog_bark"                      ..":".. "car_steal_2_soundset",
        "thermal_off"                           ..":".. "car_steal_2_soundset",
        "thermal_on"                            ..":".. "car_steal_2_soundset",
        "background_loop"                       ..":".. "cb_radio_sfx",
        "end_squelch"                           ..":".. "cb_radio_sfx",
        "start_squelch"                         ..":".. "cb_radio_sfx",
        "round_ending_stinger_custom"           ..":".. "celebration_soundset",
        "screen_flash"                          ..":".. "celebration_soundset",
        "screen_swipe"                          ..":".. "celebration_soundset",
        "cable_snaps"                           ..":".. "construction_accident_1_sounds",
        "pipes_land"                            ..":".. "construction_accident_1_sounds",
        "weaken"                                ..":".. "construction_accident_1_sounds",
        "wind"                                  ..":".. "construction_accident_1_sounds",
        "emp_blast"                             ..":".. "dlc_heists_biolab_finale_sounds",
        "pre_screen_stinger"                    ..":".. "dlc_heists_failed_screen_sounds",
        "pre_screen_stinger"                    ..":".. "dlc_heists_finale_screen_sounds",
        "5_second_timer"                        ..":".. "dlc_heists_general_frontend_sounds",
        "local_plyr_cash_counter_complete"      ..":".. "dlc_heists_general_frontend_sounds",
        "local_plyr_cash_counter_increase"      ..":".. "dlc_heists_general_frontend_sounds",
        "mission_pass_notify"                   ..":".. "dlc_heists_general_frontend_sounds",
        "nav_arrow_ahead"                       ..":".. "dlc_heists_general_frontend_sounds",
        "nav_arrow_behind"                      ..":".. "dlc_heists_general_frontend_sounds",
        "nav_arrow_left"                        ..":".. "dlc_heists_general_frontend_sounds",
        "nav_arrow_right"                       ..":".. "dlc_heists_general_frontend_sounds",
        "on_call_player_join"                   ..":".. "dlc_heists_general_frontend_sounds",
        "out_of_bounds_timer"                   ..":".. "dlc_heists_general_frontend_sounds",
        "remote_plyr_cash_counter_complete"     ..":".. "dlc_heists_general_frontend_sounds",
        "remote_plyr_cash_counter_increase"     ..":".. "dlc_heists_general_frontend_sounds",
        "payment_non_player"                    ..":".. "dlc_heists_generic_sounds",
        "payment_player"                        ..":".. "dlc_heists_generic_sounds",
        "pre_screen_stinger"                    ..":".. "dlc_heists_prep_screen_sounds",
        "hack_failed"                           ..":".. "dlc_heist_biolab_prep_hacking_sounds",
        "hack_success"                          ..":".. "dlc_heist_biolab_prep_hacking_sounds",
        "pin_bad"                               ..":".. "dlc_heist_biolab_prep_hacking_sounds",
        "pin_centred"                           ..":".. "dlc_heist_biolab_prep_hacking_sounds",
        "pin_good"                              ..":".. "dlc_heist_biolab_prep_hacking_sounds",
        "pin_movement"                          ..":".. "dlc_heist_biolab_prep_hacking_sounds",
        "drill_pin_break"                       ..":".. "dlc_heist_fleeca_soundset",
        "background"                            ..":".. "dlc_heist_hacking_snake_sounds",
        "beep_green"                            ..":".. "dlc_heist_hacking_snake_sounds",
        "beep_red"                              ..":".. "dlc_heist_hacking_snake_sounds",
        "click"                                 ..":".. "dlc_heist_hacking_snake_sounds",
        "crash"                                 ..":".. "dlc_heist_hacking_snake_sounds",
        "failure"                               ..":".. "dlc_heist_hacking_snake_sounds",
        "goal"                                  ..":".. "dlc_heist_hacking_snake_sounds",
        "lester_laugh_phone"                    ..":".. "dlc_heist_hacking_snake_sounds",
        "power_down"                            ..":".. "dlc_heist_hacking_snake_sounds",
        "start"                                 ..":".. "dlc_heist_hacking_snake_sounds",
        "success"                               ..":".. "dlc_heist_hacking_snake_sounds",
        "trail_custom"                          ..":".. "dlc_heist_hacking_snake_sounds",
        "turn"                                  ..":".. "dlc_heist_hacking_snake_sounds",
        "continue_accepted"                     ..":".. "dlc_heist_planning_board_sounds",
        "continue_appears"                      ..":".. "dlc_heist_planning_board_sounds",
        "highlight_accept"                      ..":".. "dlc_heist_planning_board_sounds",
        "highlight_cancel"                      ..":".. "dlc_heist_planning_board_sounds",
        "highlight_error"                       ..":".. "dlc_heist_planning_board_sounds",
        "highlight_move"                        ..":".. "dlc_heist_planning_board_sounds",
        "map_roll_down"                         ..":".. "dlc_heist_planning_board_sounds",
        "map_roll_up"                           ..":".. "dlc_heist_planning_board_sounds",
        "paper_shuffle"                         ..":".. "dlc_heist_planning_board_sounds",
        "pen_tick"                              ..":".. "dlc_heist_planning_board_sounds",
        "zoom_in"                               ..":".. "dlc_heist_planning_board_sounds",
        "zoom_left"                             ..":".. "dlc_heist_planning_board_sounds",
        "zoom_out"                              ..":".. "dlc_heist_planning_board_sounds",
        "zoom_right"                            ..":".. "dlc_heist_planning_board_sounds",
        "player_collect"                        ..":".. "dlc_pilot_mp_hud_sounds",
        "bus_schedule_pickup"                   ..":".. "dlc_prison_break_heist_sounds",
        "grab_chute_foley"                      ..":".. "dlc_pilot_chase_parachute_sounds",
        "door_open"                             ..":".. "docks_heist_finale_2b_sounds",
        "opened"                                ..":".. "door_garage",
        "opening"                               ..":".. "door_garage",
        "altitude_warning"                      ..":".. "exile_1",
        "falling_crates"                        ..":".. "exile_1",
        "family_1_car_breakdown"                ..":".. "family1_boat",
        "family_1_car_breakdown_additional"     ..":".. "family1_boat",
        "flying_stream_end_instant"             ..":".. "family_5_sounds",
        "michael_long_scream"                   ..":".. "family_5_sounds",
        "heli_crash"                            ..":".. "fbi_heist_finale_chopper",
        "limit"                                 ..":".. "gtao_apt_door_downstairs_glass_sounds",
        "push"                                  ..":".. "gtao_apt_door_downstairs_glass_sounds",
        "swing_shut"                            ..":".. "gtao_apt_door_downstairs_glass_sounds",
        "lights_on"                             ..":".. "gtao_mugshot_room_sounds",
        "marker_erase"                          ..":".. "heist_bulletin_board_soundset",
        "person_scroll"                         ..":".. "heist_bulletin_board_soundset",
        "person_select"                         ..":".. "heist_bulletin_board_soundset",
        "undo"                                  ..":".. "heist_bulletin_board_soundset",
        "back"                                  ..":".. "hud_ammo_shop_soundset",
        "error"                                 ..":".. "hud_ammo_shop_soundset",
        "nav"                                   ..":".. "hud_ammo_shop_soundset",
        "weapon_ammo_purchase"                  ..":".. "hud_ammo_shop_soundset",
        "weapon_attachment_equip"               ..":".. "hud_ammo_shop_soundset",
        "weapon_attachment_unequip"             ..":".. "hud_ammo_shop_soundset",
        "weapon_purchase"                       ..":".. "hud_ammo_shop_soundset",
        "weapon_select_armor"                   ..":".. "hud_ammo_shop_soundset",
        "weapon_select_baton"                   ..":".. "hud_ammo_shop_soundset",
        "weapon_select_fuel_can"                ..":".. "hud_ammo_shop_soundset",
        "weapon_select_grenade_launcher"        ..":".. "hud_ammo_shop_soundset",
        "weapon_select_handgun"                 ..":".. "hud_ammo_shop_soundset",
        "weapon_select_knife"                   ..":".. "hud_ammo_shop_soundset",
        "weapon_select_other"                   ..":".. "hud_ammo_shop_soundset",
        "weapon_select_parachute"               ..":".. "hud_ammo_shop_soundset",
        "weapon_select_rifle"                   ..":".. "hud_ammo_shop_soundset",
        "weapon_select_rpg_launcher"            ..":".. "hud_ammo_shop_soundset",
        "weapon_select_shotgun"                 ..":".. "hud_ammo_shop_soundset",
        "base_jump_passed"                      ..":".. "hud_awards",
        "challenge_unlocked"                    ..":".. "hud_awards",
        "collected"                             ..":".. "hud_awards",
        "flight_school_lesson_passed"           ..":".. "hud_awards",
        "golf_birdie"                           ..":".. "hud_awards",
        "golf_eagle"                            ..":".. "hud_awards",
        "golf_new_record"                       ..":".. "hud_awards",
        "loser"                                 ..":".. "hud_awards",
        "loser"                                 ..":".. "hud_awards",
        "medal_bronze"                          ..":".. "hud_awards",
        "medal_gold"                            ..":".. "hud_awards",
        "medal_silver"                          ..":".. "hud_awards",
        "other_text"                            ..":".. "hud_awards",
        "peyote_completed"                      ..":".. "hud_awards",
        "property_purchase"                     ..":".. "hud_awards",
        "race_placed"                           ..":".. "hud_awards",
        "rank_up"                               ..":".. "hud_awards",
        "shooting_range_round_over"             ..":".. "hud_awards",
        "sign_destroyed"                        ..":".. "hud_awards",
        "tennis_match_point"                    ..":".. "hud_awards",
        "tennis_point_won"                      ..":".. "hud_awards",
        "under_the_bridge"                      ..":".. "hud_awards",
        "win"                                   ..":".. "hud_awards",
        "delete"                                ..":".. "hud_deathmatch_soundset",
        "edit"                                  ..":".. "hud_deathmatch_soundset",
        "back"                                  ..":".. "hud_freemode_soundset",
        "cancel"                                ..":".. "hud_freemode_soundset",
        "nav_left_right"                        ..":".. "hud_freemode_soundset",
        "nav_up_down"                           ..":".. "hud_freemode_soundset",
        "select"                                ..":".. "hud_freemode_soundset",
        "cancel"                                ..":".. "hud_frontend_clothesshop_soundset",
        "error"                                 ..":".. "hud_frontend_clothesshop_soundset",
        "nav_up_down"                           ..":".. "hud_frontend_clothesshop_soundset",
        "select"                                ..":".. "hud_frontend_clothesshop_soundset",
        "pick_up_weapon"                        ..":".. "hud_frontend_custom_soundset",
        "robbery_money_total"                   ..":".. "hud_frontend_custom_soundset",
        "atm_window"                            ..":".. "hud_frontend_default_soundset",
        "back"                                  ..":".. "hud_frontend_default_soundset",
        "cancel"                                ..":".. "hud_frontend_default_soundset",
        "character_select"                      ..":".. "hud_frontend_default_soundset",
        "continue"                              ..":".. "hud_frontend_default_soundset",
        "continuous_slider"                     ..":".. "hud_frontend_default_soundset",
        "error"                                 ..":".. "hud_frontend_default_soundset",
        "exit"                                  ..":".. "hud_frontend_default_soundset",
        "highlight"                             ..":".. "hud_frontend_default_soundset",
        "highlight_nav_up_down"                 ..":".. "hud_frontend_default_soundset",
        "horde_cool_down_timer"                 ..":".. "hud_frontend_default_soundset",
        "leader_board"                          ..":".. "hud_frontend_default_soundset",
        "mp_5_second_timer"                     ..":".. "hud_frontend_default_soundset",
        "mp_award"                              ..":".. "hud_frontend_default_soundset",
        "mp_idle_kick"                          ..":".. "hud_frontend_default_soundset",
        "mp_idle_timer"                         ..":".. "hud_frontend_default_soundset",
        "mp_rank_up"                            ..":".. "hud_frontend_default_soundset",
        "mp_wave_complete"                      ..":".. "hud_frontend_default_soundset",
        "nav_left_right"                        ..":".. "hud_frontend_default_soundset",
        "nav_up_down"                           ..":".. "hud_frontend_default_soundset",
        "no"                                    ..":".. "hud_frontend_default_soundset",
        "ok"                                    ..":".. "hud_frontend_default_soundset",
        "pick_up"                               ..":".. "hud_frontend_default_soundset",
        "quit"                                  ..":".. "hud_frontend_default_soundset",
        "restart"                               ..":".. "hud_frontend_default_soundset",
        "retry"                                 ..":".. "hud_frontend_default_soundset",
        "select"                                ..":".. "hud_frontend_default_soundset",
        "skip"                                  ..":".. "hud_frontend_default_soundset",
        "timer"                                 ..":".. "hud_frontend_default_soundset",
        "toggle_on"                             ..":".. "hud_frontend_default_soundset",
        "yes"                                   ..":".. "hud_frontend_default_soundset",
        "continue"                              ..":".. "hud_frontend_default_soundset",
        "deliver_pick_up"                       ..":".. "hud_frontend_mp_collectable_sounds",
        "dropped"                               ..":".. "hud_frontend_mp_collectable_sounds",
        "enemy_deliver"                         ..":".. "hud_frontend_mp_collectable_sounds",
        "enemy_pick_up"                         ..":".. "hud_frontend_mp_collectable_sounds",
        "friend_deliver"                        ..":".. "hud_frontend_mp_collectable_sounds",
        "friend_pick_up"                        ..":".. "hud_frontend_mp_collectable_sounds",
        "back"                                  ..":".. "hud_frontend_mp_soundset",
        "select"                                ..":".. "hud_frontend_mp_soundset",
        "back"                                  ..":".. "hud_frontend_tattoo_shop_soundset",
        "error"                                 ..":".. "hud_frontend_tattoo_shop_soundset",
        "nav_up_down"                           ..":".. "hud_frontend_tattoo_shop_soundset",
        "purchase"                              ..":".. "hud_frontend_tattoo_shop_soundset",
        "select"                                ..":".. "hud_frontend_tattoo_shop_soundset",
        "pickup_weapon_ball"                    ..":".. "hud_frontend_weapons_pickups_soundset",
        "pickup_weapon_smokegrenade"            ..":".. "hud_frontend_weapons_pickups_soundset",
        "cancel"                                ..":".. "hud_liquor_store_soundset",
        "error"                                 ..":".. "hud_liquor_store_soundset",
        "nav_up_down"                           ..":".. "hud_liquor_store_soundset",
        "purchase"                              ..":".. "hud_liquor_store_soundset",
        "select"                                ..":".. "hud_liquor_store_soundset",
        "phone_generic_key_02"                  ..":".. "hud_minigame_soundset",
        "phone_generic_key_03"                  ..":".. "hud_minigame_soundset",
        "10_sec_warning"                        ..":".. "hud_mini_game_soundset",
        "3_2_1"                                 ..":".. "hud_mini_game_soundset",
        "3_2_1_non_race"                        ..":".. "hud_mini_game_soundset",
        "5_sec_warning"                         ..":".. "hud_mini_game_soundset",
        "back"                                  ..":".. "hud_mini_game_soundset",
        "cam_pan_darts"                         ..":".. "hud_mini_game_soundset",
        "cancel"                                ..":".. "hud_mini_game_soundset",
        "checkpoint_ahead"                      ..":".. "hud_mini_game_soundset",
        "checkpoint_behind"                     ..":".. "hud_mini_game_soundset",
        "checkpoint_missed"                     ..":".. "hud_mini_game_soundset",
        "checkpoint_normal"                     ..":".. "hud_mini_game_soundset",
        "checkpoint_perfect"                    ..":".. "hud_mini_game_soundset",
        "checkpoint_under_the_bridge"           ..":".. "hud_mini_game_soundset",
        "confirm_beep"                          ..":".. "hud_mini_game_soundset",
        "first_place"                           ..":".. "hud_mini_game_soundset",
        "go"                                    ..":".. "hud_mini_game_soundset",
        "go_non_race"                           ..":".. "hud_mini_game_soundset",
        "leaderboard"                           ..":".. "hud_mini_game_soundset",
        "loose_match"                           ..":".. "hud_mini_game_soundset",
        "medal_up"                              ..":".. "hud_mini_game_soundset",
        "nav_up_down"                           ..":".. "hud_mini_game_soundset",
        "quit_whoosh"                           ..":".. "hud_mini_game_soundset",
        "select"                                ..":".. "hud_mini_game_soundset",
        "timer_stop"                            ..":".. "hud_mini_game_soundset",
        "property_purchase_medium"              ..":".. "hud_property_soundset",
        "focusin"                               ..":".. "hintcamsounds",
        "focusout"                              ..":".. "hintcamsounds",
        "close_window"                          ..":".. "lester1a_sounds",
        "finding_virus"                         ..":".. "lester1a_sounds",
        "open_window"                           ..":".. "lester1a_sounds",
        "hit_1"                                 ..":".. "long_player_switch_sounds",
        "stun_collect"                          ..":".. "minute_man_01_soundset",
        "background"                            ..":".. "mp_cctv_soundset",
        "change_cam"                            ..":".. "mp_cctv_soundset",
        "pan"                                   ..":".. "mp_cctv_soundset",
        "zoom"                                  ..":".. "mp_cctv_soundset",
        "boats_planes_helis_boom"               ..":".. "mp_lobby_sounds",
        "car_bike_whoosh"                       ..":".. "mp_lobby_sounds",
        "whoosh_1s_l_to_r"                      ..":".. "mp_lobby_sounds",
        "whoosh_1s_r_to_l"                      ..":".. "mp_lobby_sounds",
        "10s"                                   ..":".. "mp_mission_countdown_soundset",
        "5s"                                    ..":".. "mp_mission_countdown_soundset",
        "oneshot_final"                         ..":".. "mp_mission_countdown_soundset",
        "door_buzz"                             ..":".. "mp_player_apartment",
        "closed"                                ..":".. "mp_properties_elevator_doors",
        "closing"                               ..":".. "mp_properties_elevator_doors",
        "opened"                                ..":".. "mp_properties_elevator_doors",
        "opening"                               ..":".. "mp_properties_elevator_doors",
        "knuckle_crack_hard_cel"                ..":".. "mp_snacks_soundset",
        "knuckle_crack_slap_cel"                ..":".. "mp_snacks_soundset",
        "slow_clap_cel"                         ..":".. "mp_snacks_soundset",
        "bed"                                   ..":".. "missionfailedsounds",
        "screenflash"                           ..":".. "missionfailedsounds",
        "texthit"                               ..":".. "missionfailedsounds",
        "on"                                    ..":".. "noir_filter_sounds",
        "ps2a_money_lost"                       ..":".. "paleto_score_2a_bank_ss",
        "zoom"                                  ..":".. "paparazzo_02_soundsets",
        "1st_person_transition"                 ..":".. "player_switch_custom_soundset",
        "camera_move_loop"                      ..":".. "player_switch_custom_soundset",
        "hit_out"                               ..":".. "player_switch_custom_soundset",
        "hit_in"                                ..":".. "player_switch_custom_soundset",
        "hit_out"                               ..":".. "player_switch_custom_soundset",
        "hit_out"                               ..":".. "player_switch_custom_soundset",
        "short_transition_in"                   ..":".. "player_switch_custom_soundset",
        "short_transition_out"                  ..":".. "player_switch_custom_soundset",
        "found_target"                          ..":".. "police_chopper_cam_sounds",
        "lost_target"                           ..":".. "police_chopper_cam_sounds",
        "microphone"                            ..":".. "police_chopper_cam_sounds",
        "menu_accept"                           ..":".. "phone_soundset_default",
        "pull_out"                              ..":".. "phone_soundset_franklin",
        "background_sound"                      ..":".. "phone_soundset_glasses_cam",
        "camera_shoot"                          ..":".. "phone_soundset_glasses_cam",
        "camera_zoom"                           ..":".. "phone_soundset_glasses_cam",
        "hang_up"                               ..":".. "phone_soundset_michael",
        "put_away"                              ..":".. "phone_soundset_michael",
        "camera_shoot"                          ..":".. "phone_soundset_franklin",
        "faster_bar_full"                       ..":".. "respawn_online_soundset",
        "faster_click"                          ..":".. "respawn_online_soundset",
        "hit"                                   ..":".. "respawn_online_soundset",
        "hit"                                   ..":".. "respawn_soundset",
        "rope_cut"                              ..":".. "rope_cut_soundset",
        "change_station_loud"                   ..":".. "radio_soundset",
        "safe_door_close"                       ..":".. "safe_crack_soundset",
        "safe_door_open"                        ..":".. "safe_crack_soundset",
        "tumbler_pin_fall"                      ..":".. "safe_crack_soundset",
        "tumbler_pin_fall_final"                ..":".. "safe_crack_soundset",
        "tumbler_reset"                         ..":".. "safe_crack_soundset",
        "tumbler_turn"                          ..":".. "safe_crack_soundset",
        "all"                                   ..":".. "short_player_switch_sound_set",
        "in"                                    ..":".. "short_player_switch_sound_set",
        "all"                                   ..":".. "short_player_switch_sound_set",
        "out"                                   ..":".. "short_player_switch_sound_set",
        "switchredwarning"                      ..":".. "special_ability_soundset",
        "switchwhitewarning"                    ..":".. "special_ability_soundset",
        "tattooing_oneshot"                     ..":".. "tattooist_sounds",
        "tattooing_oneshot_remove"              ..":".. "tattooist_sounds",
        "ramp_down"                             ..":".. "truck_ramp_down",
        "ramp_up"                               ..":".. "truck_ramp_down",
        "click_back"                            ..":".. "web_navigation_sounds_phone",
        "click_fail"                            ..":".. "web_navigation_sounds_phone",
        "click_special"                         ..":".. "web_navigation_sounds_phone",
        "bed"                                   ..":".. "wastedsounds",
        "mp_flash"                              ..":".. "wastedsounds",
        "mp_impact"                             ..":".. "wastedsounds",
        "screenflash"                           ..":".. "wastedsounds",
        "texthit"                               ..":".. "wastedsounds",
        "click_special"                         ..":".. "web_navigation_sounds_phone",

        ["navopen"]           = "nav_up_down:hud_frontend_default_soundset",
        ["navclose"]          = "nav_up_down:hud_frontend_default_soundset",
        ["navback"]           = "back"..":".."hud_ammo_shop_soundset",
        ["navselect"]         = "nav_up_down:hud_frontend_default_soundset",  -- "pick_up_weapon:hud_frontend_custom_soundset",
        ["navup"]             = "nav_up_down:hud_frontend_default_soundset",
        ["navdown"]           = "nav_up_down:hud_frontend_default_soundset",
        ["navleft"]           = "nav_up_down:hud_frontend_default_soundset",
        ["navright"]          = "nav_up_down:hud_frontend_default_soundset",
        ["painttarget"]       = "hack_success:dlc_heist_biolab_prep_hacking_sounds",
        ["painttargetnext"]   = "hack_success:dlc_heist_biolab_prep_hacking_sounds",
        ["digizoomin"]        = "mp_5_second_timer"..":".. "hud_frontend_default_soundset",
        ["digizoomout"]       = "10_sec_warning"..":".. "hud_mini_game_soundset",
        ["digiscanner"]       = "hack_success:dlc_heist_biolab_prep_hacking_sounds",
        ["gravitygunpickup"]  = "hack_success:dlc_heist_biolab_prep_hacking_sounds",
        ["gravitygunputdown"] = "confirm_beep:hud_mini_game_soundset",
        ["gravitygunthrow"]   = "golf_birdie:hud_awards",
        ["switchseat"]        = "nav:hud_ammo_shop_soundset",
        ["bit1"]              = "thermal_on"..":".."car_steal_2_soundset",
        ["bit2"]              = "thermal_off"..":".."car_steal_2_soundset",
        ["bit3"]              = "pin_bad:dlc_heist_biolab_prep_hacking_sounds",
        ["bit4"]              = "pin_good:dlc_heist_biolab_prep_hacking_sounds",
        ["bit5"]              = "close_window:lester1a_sounds",
        ["bit6"]              = "open_window:lester1a_sounds",
        ["zoomin"]            = "zoom_in:dlc_heist_planning_board_sounds",
        ["zoomout"]           = "zoom_out:dlc_heist_planning_board_sounds",
}

for k,v in ipairs(SOUND.sfx_list) do
    if   not string.find(v,"[:].*[:].*")
  --and  not string.find(tostring(k),"[:]")
  --and  not k == v:sub(1,#k)
    then
        local vlow = string.lower(v)
        if SOUND.sfx_list[k] ~= vlow then SOUND.sfx_list[k] = vlow ; end
        local newKey = string.gsub(vlow,":.*","")
        SOUND.sfx_list[newKey] = vlow
        -- newKey = vlow
        -- if not SOUND.sfx_list[newKey] then SOUND.sfx_list[newKey] = vlow ; end
    end
end


SOUND.speech_list = {
  --[[  AUDIO::_PLAY_AMBIENT_SPEECH1(PLAYER.PLAYER_PED_ID(), "HOOKER_DECLINED_TREVOR", "SPEECH_PARAMS_FORCE_SHOUTED_CLEAR", 1); --]]
    "APOLOGY_NO_TROUBLE",
    "ARRESTED",
    "BASEJUMP_ABOUT_TO_JUMP",
    "BLOCKED_GENERIC",
    "BUMP",
    "CALL_CHOP",
    "CAR_HIT_PED",
    "CHAT_RESP",
    "CHAT_STATE",
    "COVER_ME",
    "COVER_YOU",
    "CRASH_CAR",
    "CRASH_GENERIC",
    "CULT_TALK",
    "DARTS_140",
    "DARTS_180",
    "DARTS_1_DART_AWAY",
    "DARTS_BOAST",
    "DARTS_BORED",
    "DARTS_BULLSEYE",
    "DARTS_BUST",
    "DARTS_HAPPY",
    "DARTS_LOSE",
    "DARTS_LOSING_BADLY",
    "DARTS_MISS_BOARD",
    "DARTS_PLAYING_WELL",
    "DARTS_REQUEST_GAME",
    "DARTS_WIN",
    "DODGE",
    "DRAW_GUN",
    "DYING_HELP",
    "DYING_MOAN",
    "FALL_BACK",
    "FIGHT",
    "GAME_BAD_OTHER",
    "GAME_BAD_SELF",
    "GAME_GOOD_OTHER",
    "GAME_GOOD_SELF",
    "GAME_HECKLE",
    "GAME_LOSE_SELF",
    "GAME_QUIT_EARLY",
    "GAME_WIN_SELF",
    "GENERIC_BUY",
    "GENERIC_BYE",
    "GENERIC_CURSE_HIGH",
    "GENERIC_CURSE_MED",
    "GENERIC_FUCK_YOU",
    "GENERIC_FRIGHTENED_HIGH",
    "GENERIC_FRIGHTENED_MED",
    "GENERIC_HI",
    "GENERIC_HOWS_IT_GOING",
    "GENERIC_INSULT_HIGH",
    "GENERIC_INSULT_MED",
    "GENERIC_SHOCKED_HIGH",
    "GENERIC_SHOCKED_MED",
    "GENERIC_THANKS",
    "GENERIC_WAR_CRY",
    "GENERIC_YES",
    "GET_WANTED_LEVEL",
    "GET_DOWN",
    "GUN_BEG",
    "GUN_COOL",
    "HOOKER_CAR_INCORRECT",
    "HOOKER_DECLINED",
    "HOOKER_DECLINED_TREVOR",
    "HOOKER_DECLINE_SERVICE",
    "HOOKER_HAD_ENOUGH",
    "HOOKER_LEAVES_ANGRY",
    "HOOKER_OFFER_AGAIN",
    "HOOKER_OFFER_SERVICE",
    "HOOKER_REQUEST",
    "HOOKER_SECLUDED",
    "HOOKER_STORY_REVULSION_RESP",
    "HOOKER_STORY_SARCASTIC_RESP",
    "HOOKER_STORY_SYMPATHETIC_RESP",
    "HUNTING_KILL",
    "HUNTING_SPOT_ANIMAL",
    "HUNTING_SPOT_COUGAR",
    "JACKED_CAR",
    "JACKED_GENERIC",
    "JACKING_BIKE",
    "JACKING_CAR_MALE",
    "JACKING_GENERIC",
    "JACKING_ORDER",
    "KIFFLOM_GREET",
    "KIFFLOM_RUNNING",
    "KIFFLOM_SPRINTING",
    "KILLED_ALL",
    "KNOCK_OVER_PED",
    "MELEE_KNOCK_DOWN",
    "MELEE_LARGE_GRUNT",
    "NEED_A_BIGGER_VEHICLE",
    "PHONE_CALL_NOT_CONNECTED",
    "POST_STONED",
    "PROVOKE_TRESPASS",
    "PURCHASE_ONLINE",
    "RELOADING",
    "ROBBERY_FRIEND_WITNESS",
    "ROLLERCOASTER_CHAT_EXCITED",
    "ROLLERCOASTER_CHAT_NORMAL",
    "SEX_CLIMAX",
    "SEX_FINISHED",
    "SEX_GENERIC",
    "SEX_GENERIC_FEM",
    "SEX_ORAL",
    "SEX_ORAL_FEM",
    "SHOOT",
    "SHOP_BANTER",
    "SHOP_BANTER_FRANKLIN",
    "SHOP_BANTER_TREVOR",
    "SHOP_BROWSE",
    "SHOP_BROWSE_ARMOUR",
    "SHOP_BROWSE_BIG",
    "SHOP_BROWSE_FRANKLIN",
    "SHOP_BROWSE_GUN",
    "SHOP_BROWSE_MELEE",
    "SHOP_BROWSE_TATTOO_MENU",
    "SHOP_BROWSE_THROWN",
    "SHOP_BROWSE_TREVOR",
    "SHOP_CUTTING_HAIR",
    "SHOP_GIVE_FOR_FREE",
    "SHOP_GOODBYE",
    "SHOP_GREET",
    "SHOP_GREET_FRANKLIN",
    "SHOP_GREET_MICHAEL",
    "SHOP_GREET_SPECIAL",
    "SHOP_GREET_TREVOR",
    "SHOP_GREET_UNUSUAL",
    "SHOP_HAIR_WHAT_WANT",
    "SHOP_NICE_VEHICLE",
    "SHOP_NO_COPS",
    "SHOP_NO_MESSING",
    "SHOP_NO_WEAPON",
    "SHOP_OUT_OF_STOCK",
    "SHOP_REMOVE_VEHICLE",
    "SHOP_SELL",
    "SHOP_SELL_ARMOUR",
    "SHOP_SELL_BRAKES",
    "SHOP_SELL_BULLETPROOF_TYRES",
    "SHOP_SELL_COSMETICS",
    "SHOP_SELL_ENGINE_UPGRADE",
    "SHOP_SELL_EXHAUST",
    "SHOP_SELL_HORN",
    "SHOP_SELL_REPAIR",
    "SHOP_SELL_SUSPENSION",
    "SHOP_SELL_TRANS_UPGRADE",
    "SHOP_SELL_TURBO",
    "SHOP_SHOOTING",
    "SHOP_SPECIAL_DISCOUNT",
    "SHOP_TATTOO_APPLIED",
    "SHOP_TRY_ON_ITEM",
    "SHOUT_THREATEN_GANG",
    "SHOUT_THREATEN_PED",
    "SOLICIT_FRANKLIN",
    "SOLICIT_FRANKLIN_RETURN",
    "SOLICIT_MICHAEL",
    "SOLICIT_MICHAEL_RETURN",
    "SOLICIT_TREVOR",
    "SOLICIT_TREVOR_RETURN",
    "SPOT_POLICE",
    "START_CAR_PANIC",
    "STAY_DOWN",
    "TAKE_COVER",
}

SOUND.speech_params = {
  "SPEECH_PARAMS_STANDARD",
  "SPEECH_PARAMS_ALLOW_REPEAT",
  "SPEECH_PARAMS_BEAT",
  "SPEECH_PARAMS_FORCE",
  "SPEECH_PARAMS_FORCE_FRONTEND",
  "SPEECH_PARAMS_FORCE_NO_REPEAT_FRONTEND",
  "SPEECH_PARAMS_FORCE_NORMAL",
  "SPEECH_PARAMS_FORCE_NORMAL_CLEAR",
  "SPEECH_PARAMS_FORCE_NORMAL_CRITICAL",
  "SPEECH_PARAMS_FORCE_SHOUTED",
  "SPEECH_PARAMS_FORCE_SHOUTED_CLEAR",
  "SPEECH_PARAMS_FORCE_SHOUTED_CRITICAL",
  "SPEECH_PARAMS_FORCE_PRELOAD_ONLY",
  "SPEECH_PARAMS_MEGAPHONE",
  "SPEECH_PARAMS_HELI",
  "SPEECH_PARAMS_FORCE_MEGAPHONE",
  "SPEECH_PARAMS_FORCE_HELI",
  "SPEECH_PARAMS_INTERRUPT",
  "SPEECH_PARAMS_INTERRUPT_SHOUTED",
  "SPEECH_PARAMS_INTERRUPT_SHOUTED_CLEAR",
  "SPEECH_PARAMS_INTERRUPT_SHOUTED_CRITICAL",
  "SPEECH_PARAMS_INTERRUPT_NO_FORCE",
  "SPEECH_PARAMS_INTERRUPT_FRONTEND",
  "SPEECH_PARAMS_INTERRUPT_NO_FORCE_FRONTEND",
  "SPEECH_PARAMS_ADD_BLIP",
  "SPEECH_PARAMS_ADD_BLIP_ALLOW_REPEAT",
  "SPEECH_PARAMS_ADD_BLIP_FORCE",
  "SPEECH_PARAMS_ADD_BLIP_SHOUTED",
  "SPEECH_PARAMS_ADD_BLIP_SHOUTED_FORCE",
  "SPEECH_PARAMS_ADD_BLIP_INTERRUPT",
  "SPEECH_PARAMS_ADD_BLIP_INTERRUPT_FORCE",
  "SPEECH_PARAMS_FORCE_PRELOAD_ONLY_SHOUTED",
  "SPEECH_PARAMS_FORCE_PRELOAD_ONLY_SHOUTED_CLEAR",
  "SPEECH_PARAMS_FORCE_PRELOAD_ONLY_SHOUTED_CRITICAL",
  "SPEECH_PARAMS_SHOUTED",
  "SPEECH_PARAMS_SHOUTED_CLEAR",
  "SPEECH_PARAMS_SHOUTED_CRITICAL",
}

for k,v in pairs(SOUND.speech_list)   do SOUND.speech_list[string.lower(v)]   = k ; end
for k,v in pairs(SOUND.speech_params) do SOUND.speech_params[string.lower(v)] = k ; end

if ( UTILS == nil ) then UTILS = {} ; end

function UTILS.notify(msg)
  --print( "Notify : " .. string.gsub( tostring( msg ), "~.~", "" ) )
  natives.UI._SET_NOTIFICATION_TEXT_ENTRY("STRING")
  natives.UI.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(tostring(msg or ""))
  natives.UI._DRAW_NOTIFICATION(false, true)
end


function SOUND:Find(searchString,indexLow,indexHigh,printList)

    if not self.sfx_list  or  not self.speech_list then return ; end
    searchString            =  tostring(searchString or "") or ""
    local searchStringLower =  string.lower(searchString)
    if not indexLow  then indexLow  = 1 ; end
    if not indexHigh then indexHigh = 0 ; end
    if  indexHigh < indexLow then
        if indexHigh > 0 then indexHigh = indexLow + indexHigh - 1 ; else indexHigh = indexLow ; end
    end

    local matchingSounds = {}
    local searchTab      = {}
    local searchTabKeys  = {}
    local searchCount    = 0

    local searchSound = string.gsub(searchStringLower,":.*","")
    local searchSet   = string.gsub(searchStringLower,".*:","")
    if searchSound == searchSet then searchSet = "" ; end

    if      searchString ~= ""  and  self.sfx_list[searchString]
    then
            local sound = string.gsub(self.sfx_list[searchString],":.*","")
            local set   = string.gsub(self.sfx_list[searchString],".*:","")
            local soundfull = sound..":"..set
            matchingSounds[1] = { name = searchString, sound = sound, set = set, soundfull = soundfull, soundtype = "SFX", }
            searchCount = 1

    elseif  searchStringLower ~= ""  and  self.sfx_list[searchStringLower]
    then
            local sound     = string.gsub(self.sfx_list[searchStringLower],":.*","")
            local set       = string.gsub(self.sfx_list[searchStringLower],".*:","")
            local soundfull = sound..":"..set
            matchingSounds[1] = { name = searchStringLower, sound = sound, set = set, soundfull = soundfull, soundtype = "SFX", }
            searchCount = 1

    elseif  searchString ~= ""  and  self.speech_list[searchSound]
    then
            local sound = searchSound
            local set   = searchSet
            if    not self.speech_params[set]
            then  set = "SPEECH_PARAMS_FORCE_SHOUTED_CLEAR"
            end
            local soundfull = sound..":"..set
            matchingSounds[1] = { name = searchSound, sound = sound, set = set, soundfull = soundfull, soundtype = "SPEECH", }
            searchCount = 1

    elseif  searchString ~= ""  and  self.speech_list[searchStringLower]
    then
            local sound = searchSound
            local set   = searchSet
            if    not self.speech_params[set]
            then  set = "SPEECH_PARAMS_FORCE_SHOUTED_CLEAR"
            end
            local soundfull = sound..":"..set
            matchingSounds[1] = { name = searchStringLower, sound = sound, set = set, soundfull = soundfull, soundtype = "SPEECH", }
            searchCount = 1

    else
            self.deepfindcount = (tonumber(self.deepfindcount or 0) or 0) + 1
            for k,v in pairs(self.sfx_list) do if (type(k) == "string") and not searchTabKeys[k] then searchTabKeys[k] = true ; searchTab[#searchTab+1] = k..":"..tostring(v) ;  end ; end
            table.sort(searchTab)
            for k,v in pairs(searchTab) do
                if      ( searchString == "" or string.find(string.lower(v),searchStringLower) )
                then
                        searchCount = searchCount + 1
                        if  (  searchCount >= indexLow  and  searchCount <= indexHigh )
                        then
                            local curName   = string.gsub( v, ":.*","" )
                            local curSound  = string.gsub( v, "^[^:][^:]*:", "" )
                                  curSound  = string.gsub( curSound, ":.*", "" )
                            local curSet    = string.gsub( v, ".*:", "" )
                            local soundfull = curSound..":"..curSet
                            matchingSounds[#matchingSounds+1] = { name = curName, sound = curSound, set = curSet, soundfull = soundfull, soundtype = "SFX", }
                        end
                end
            end
    end

    if    printList
    then  for k,v in pairs(matchingSounds) do
              print( string.format(
                                    "%6s = %-6s %-35s %-35s %-40s %s",
                                    "["..tostring(k).."]",
                                    "\""..v.soundtype.."\",",
                                    "\""..v.name.."\",",
                                    "\""..v.sound.."\",",
                                    "\""..v.set.."\"",
                                    "\""..v.soundfull.."\""
                                  )
                   )
          end
    end

    return matchingSounds,searchCount

end


function SOUND:Stop( curSoundID )

    curSoundID = (tonumber(curSoundID or 0) or 0)

    -- if    type(curSoundID) ~= "number" or curSoundID < 1 or curSoundID > self.soundID
    -- then  curSoundID = self.soundID
    -- end

    if    curSoundID == 0
    then
        if    self.id
        then  for k,v in pairs(self.id) do if k ~= 0 then  natives.AUDIO.STOP_SOUND(k) ; end ; end
        else  return
        end
    end

    natives.AUDIO.STOP_SOUND(curSoundID)

end


function SOUND:Play( curSoundInput, curSoundOrigin, curSoundID, selfCall )

-------------------------------------------------------------------------------------------------
--  natives.AUDIO.PLAY_SOUND_FRONTEND( soundId(int), audioName(char), audioRef(char), p3(bool) ) 
-------------------------------------------------------------------------------------------------

    if  #self.id == 0 and natives and natives.AUDIO and natives.AUDIO.GET_SOUND_ID
    then
        for i = 0,64 do natives.AUDIO.STOP_SOUND(i) ; natives.AUDIO.RELEASE_SOUND_ID(i) ; if i < 16 then local soundID = natives.AUDIO.GET_SOUND_ID() ; if i == 0 then self.soundID = soundID ; end ; self.id[#self.id+1] = soundID ; end ; end
    end

    if  curSoundInput and not selfCall
    then
        curSoundInput  = tostring(curSoundInput or "") or ""
        curSoundOrigin = curSoundOrigin or "FRONTEND"

        if      ( type(curSoundID) ~= "number" )
        then    curSoundID = self.id[((self.soundID)%#self.id)+1]
        end

        self.queue[#self.queue+1] = { curSoundInput, curSoundOrigin, curSoundID }

        return curSoundID
    end

    if not selfCall  or  #self.queue == 0 then return -2 ; end

    curSoundInput  = self.queue[1][1]
    curSoundOrigin = self.queue[1][2]
    curSoundID     = self.queue[1][3]

    if      curSoundID ~= -1
    and     not natives.AUDIO.HAS_SOUND_FINISHED(curSoundID)
    then    natives.AUDIO.STOP_SOUND(curSoundID)
    end

    local   curSoundName,curSound,curSoundSet,curSoundType,curSoundCoords,curSoundEntity = "","","","",Vector(0,0,0),0

    if      curSoundInput
    then    local retTab = self:Find(curSoundInput,1,1,false) ; if retTab and retTab[1] then curSoundName,curSound,curSoundSet,curSoundType = retTab[1].name,retTab[1].sound,retTab[1].set,retTab[1].soundtype ; end
    end

    local   curSoundCoords = Vector(0,0,0)

    if      curSoundType == "SFX"
    then
            if      type(curSoundOrigin) == "number"
            then
                    if      curSoundOrigin == -1
                    then
                            curSoundOrigin = "FRONTEND"

                    elseif  curSoundOrigin > 0 and natives.ENTITY.DOES_ENTITY_EXIST(curSoundOrigin)
                    then
                            curSoundEntity = curSoundOrigin
                            curSoundCoords = natives.ENTITY.GET_ENTITY_COORDS(curSoundOrigin,false)
                            curSoundOrigin = "ENTITY"
                    else
                            curSoundOrigin = "FRONTEND"
                    end

            elseif  type(curSoundOrigin) == "Vector"
            then
                    curSoundCoords = curSoundOrigin
                    curSoundOrigin = "COORDS"
            end

            if      curSoundOrigin == "FRONTEND"
            then
                    natives.AUDIO.PLAY_SOUND_FRONTEND(    curSoundID, curSound,  curSoundSet,  true )

            elseif  curSoundOrigin == "COORDS"
            then
                    natives.AUDIO.PLAY_SOUND_FROM_COORD(  curSoundID, curSound, curSoundCoords.x, curSoundCoords.y, curSoundCoords.z, curSoundSet, false, 0, false )

            elseif  curSoundOrigin == "ENTITY"
            then
                    natives.AUDIO.PLAY_SOUND_FROM_ENTITY( curSoundID, curSound, curSoundEntity, curSoundSet, false, 0 )
            end

    elseif  curSoundType == "SPEECH"
    then
            if curSoundEntity == 0 then curSoundEntity = natives.PLAYER.PLAYER_PED_ID() ; end
            if    math.random(1,2) == 1
            then  natives.AUDIO._PLAY_AMBIENT_SPEECH1(curSoundEntity, curSound, curSoundSet, 1)
            else  natives.AUDIO._PLAY_AMBIENT_SPEECH2(curSoundEntity, curSound, curSoundSet, 1)
            end
    end

    table.remove(self.queue,1)

    return curSoundID
end


function ANIM:distanceBetweenCoords(x1,y1,z1,x2,y2,z2)
  if    ( type(x1) ~= "number" )  or    ( type(y1) ~= "number" )  or    ( type(z1) ~= "number" )
  or    ( type(x2) ~= "number" )  or    ( type(y2) ~= "number" )  or    ( type(z2) ~= "number" )
  then  return 10000
  end
  return math.sqrt(  (x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)+(z1-z2)*(z1-z2)  )
end


function ANIM:distanceBetweenVectors(v1,v2)
  if    ( ( type(v1) ~= "table" )  and    ( type(v1) ~= "Vector" ) )
  or    ( ( type(v2) ~= "table" )  and    ( type(v2) ~= "Vector" ) )
  then  return Vector(0,0,0)
  end
  return self:distanceBetweenCoords( v1.x, v1.y, v1.z, v2.x, v2.y, v2.z )
end


-- Function to find distance between two entities
function ANIM:distanceBetween( pOne, pTwo )

  local distance = 0

  if    ( pOne == nil ) and ( pTwo == nil )
  then  return 10000.0
  end

  if ( pOne == nil ) then  pOne = natives.PLAYER.PLAYER_PED_ID() ; end

  if ( pTwo == nil ) then  pTwo = natives.PLAYER.PLAYER_PED_ID() ; end

  if    ( type(pOne) == "number" )         and ( type(pTwo) == "number" )
  and   (      pOne  == natives.PLAYER.PLAYER_PED_ID() ) and (      pTwo  == natives.PLAYER.PLAYER_PED_ID() )
  then  return 0.0
  end

  local c1,c2 = {},{}

  if      ( ( type(pOne) == "Vector" ) or ( type(pOne) == "table" ) ) and ( pOne.x ~= nil ) and ( pOne.y ~= nil ) and ( pOne.z ~= nil )
  then    c1.x = pOne.x ; c1.y = pOne.y ; c1.z = pOne.z
  elseif  (   type(pOne) == "table" )
  then    c1.x,c1.y,c1.z = tonumber(pOne[1] or 0) or 0,tonumber(pOne[2] or 0) or 0,tonumber(pOne[3] or 0) or 0
  elseif  (  ( type(pOne) == "number" ) and ( natives.ENTITY.DOES_ENTITY_EXIST(pOne) == true )  )
  then    c1 = natives.ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pOne, 0.0, 0.0, 0.0)
  else    return 10000.0
  end

  if      ( ( type(pTwo) == "Vector" ) or ( type(pTwo) == "table" ) ) and ( pTwo.x ~= nil ) and ( pTwo.y ~= nil ) and ( pTwo.z ~= nil )
  then    c2.x = pTwo.x ; c2.y = pTwo.y ; c2.z = pTwo.z
  elseif  (   type(pTwo) == "table" )
  then    c2.x,c2.y,c2.z = tonumber(pTwo[1] or 0) or 0, tonumber(pTwo[2] or 0) or 0, tonumber(pTwo[3] or 0) or 0
  elseif  (  ( type(pTwo) == "number" ) and ( natives.ENTITY.DOES_ENTITY_EXIST(pTwo) == true )  )
  then    c2 = natives.ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pTwo, 0.0, 0.0, 0.0)
  else    return 10000.0
  end

  distance = math.sqrt(  (c1.x-c2.x)*(c1.x-c2.x)+(c1.y-c2.y)*(c1.y-c2.y)+(c1.z-c2.z)*(c1.z-c2.z)  )
 
  if ( type(distance) ~= "number" ) then distance = 100000.0 ; end

  return distance

end

------------------------------------------------------------------------------------------------------------

function  ANIM:string_split2( str, separators )
    --[[
        Use like:
          for k in string.split2("asdf  ,  , fdsa , , , dsaf") do print(k) ; end

        Output is:
          asdf
          fdsa
          dsaf
    --]]
    if ( type(str) ~= "string" ) then  str = tostring(str or "") ; end
    separators = tostring( separators or "" )
    if    ( separators == "" ) then separators = "[\", ][\", ]*"
    else                            separators = "["..separators.."]["..separators.."]*"
    end
    local st, g = 1, str:gmatch("()("..separators..")")
    local function getter(segs, seps, sep, cap1, ...) st = sep and seps + #sep ; return str:sub(segs, (seps or 0) - 1), cap1 or sep, ... ; end
    return function() if st then return getter(st, g()) end end

end
--for k in string.split2("asdf,fdsa") do print(k) ; end
------------------------------------------------------------------------------------------------------------

function  ANIM:lines2table(source,searchString,separators)
    --[[
        
        Use like:
          local args = lines2table("test.txt","ab",", ") ; print(dumptable(args))

        test.txt was:
          123,456, 789,abc
          123,456,789
          abc,def,ghi

        Output is:
        {
            [1]                             = {
                [1]                         = '123' ,
                [2]                         = '456' ,
                [3]                         = '789' ,
                [4]                         = 'abc' ,
            } ,
            [2]                             = {
                [1]                         = '123' ,
                [2]                         = '456' ,
                [3]                         = '789' ,
            } ,
            [3]                             = {
                [1]                         = 'abc' ,
                [2]                         = 'def' ,
                [3]                         = 'ghi' ,
            } ,
        }
    --]]

    local outTable = {}

    source       = tostring( source       or ""   )
    searchString = tostring( searchString or ""   )
    separators   = tostring( separators   or " ," )

    if ( source == "" ) then  return outTable ; end

    local infile = io.open( source , "r" )

    if ( infile == nil ) then print("line2table : ERROR : could not open source "..source) ; return outTable ; end

    local k,kk = 0,0

    local lines = self:string_split( infile:read("*a"), "\n" )

    for line in lines do

        if ( line:sub( -1,1) == "\n" ) then line=line:sub(1,#line - 1) ; end
        if ( line:sub( -1,1) == "\r" ) then line=line:sub(1,#line - 1) ; end

        if ( line ~= line:gsub(searchString,"X") )
        then
            k = #outTable+1

            outTable[k] = {}

            for v in self.string_split2(line)
            do
                table.insert(outTable[k],v)
            end
        end
    end
    infile:close()
    return outTable

end


function ANIM:Find(searchString,indexStart,indexEnd)

    searchString = tostring(searchString or "") or ""
    searchString = string.lower(searchString)
    indexStart   = tonumber(indexStart or 1) or 1
    indexEnd     = tonumber(indexEnd or indexStart ) or indexStart
    if indexStart < 1          then indexStart = 1          ; end
    if indexEnd   < indexStart then indexEnd   = indexStart ; end

    local animList = dofile("GTALua/addons/cmenu/settings.Animations.lua")
    local findCount = 0

    local matchingAnims,matchingAnimsKeys = {},{}
    for k,v in pairs( animList ) do
    for k2,v2  in pairs( v ) do
       local curAnim = k..":"..v2
       if  string.find(curAnim,searchString)
       then
              matchingAnims[curAnim] = { [1] = k, [2] = v2, [3] = curAnim, }
              matchingAnimsKeys[#matchingAnimsKeys+1] = curAnim
       end
    end
    end

    table.sort(matchingAnimsKeys)

    local matchingAnimsNew = {}

    for i = 1,#matchingAnimsKeys
    do
        findCount = findCount + 1
        if    findCount >= indexStart and findCount <= indexEnd
        then  matchingAnimsNew[#matchingAnimsNew+1] = matchingAnims[matchingAnimsKeys[i]]
        end
    end

    return matchingAnimsNew,#matchingAnimsKeys

end



function ANIM:moveEntityRelative(ent,xrel,yrel,zrel,hrel)

  if ( ent == nil ) or ( natives.ENTITY.DOES_ENTITY_EXIST(ent) == false )
  then  return false
  end

  xrel = tonumber( xrel or 0 ) or 0
  yrel = tonumber( yrel or 0 ) or 0
  zrel = tonumber( zrel or 0 ) or 0
  hrel = tonumber( hrel or 0 ) or 0
  hrel = ( natives.ENTITY.GET_ENTITY_HEADING(ent) + hrel ) % 360
  
  local coords = natives.ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS( ent, xrel, yrel, zrel )

  natives.ENTITY.SET_ENTITY_COORDS(  ent, coords.x, coords.y, coords.z, false,false,false,false )
  natives.ENTITY.SET_ENTITY_HEADING( ent, hrel )

  return true

end


function ANIM:resetPedAnim(ent,quiet)

    if    ( type(quiet) ~= "boolean" )
    then  quiet = false
    end

    if    ( ent == nil ) or ( natives.ENTITY.DOES_ENTITY_EXIST(ent) == false )
    then  return false
    end

    self:moveEntityRelative(ent,0,0.5,-0.5)

    if    ( quiet == false )
    then  UTILS.notify("~s~Reset Anim For: "..tostring(ent))
    end
end


function ANIM:SpawnPed()
    local coords = LocalPlayer():GetOffsetVector(Vector(0,0,0))
    coords.x = coords.x + math.random(1500,3000)*0.001*(1-math.random(0,1)*2)
    coords.y = coords.y + math.random(1500,3000)*0.001*(1-math.random(0,1)*2)
    coords.z = coords.z + math.random(1000,2000)*0.0001*(1-math.random(0,1)*2)
    local ped = natives.PED.CREATE_RANDOM_PED(coords.x, coords.y, coords.z)
    spawnedPeds[#spawnedPeds+1] = ped
end



function ANIM:PlaySync1QueueProcess()

    if  self.queue1 and #self.queue1 ~= 0
    then
        local curItem = {}
        for k,v in pairs(self.queue1[1]) do curItem[k] = v ; end
        self:PlaySync1(unpack(curItem))
        table.remove(self.queue1,1)
    end

end


function ANIM:PlaySync1Queue(...)

    self.queue1[#self.queue1+1] = {...}

end

function ANIM:PlaySync3QueueProcess()

    if  self.queue3 and #self.queue3 ~= 0
    then
        local curItem = {}
        for k,v in pairs(self.queue3[1]) do curItem[k] = v ; end
        self:PlaySync3(unpack(curItem))
        table.remove(self.queue3,1)
    end

end


function ANIM:PlaySync3Queue(...)

    self.queue3[#self.queue3+1] = {...}

end


function ANIM:PlaySync3(ped1,dict1,anim1,ped2,dict2,anim2,ped3,dict3,anim3,entrel,xrel,yrel,zrel)

    --  natives.ENTITY.SET_ENTITY_ANIM_SPEED
    --  natives.ENTITY._GET_ENTITY_ANIM_DURATION(anim_dict_ped_1,anim_ped_1)

    if ( cFUN ~= nil ) and ( type(cFUN.spawnPed) == "function" ) then  self.curSpawnPed = cFUN.spawnPed  ; else self.curSpawnPed = self.SpawnPed ; end

    local rndGroup,rndElement,tmpVal = 0,0,0
    local rndModel = {}
    local ped1_model,ped2_model,ped3_model = "","",""
    local relDefault = false

    if    ( type(ped1) ~= "number" ) or ( natives.ENTITY.DOES_ENTITY_EXIST(ped1) == false ) or ( natives.ENTITY.IS_ENTITY_A_PED(ped1) == false )
    then  ped1 = natives.PLAYER.PLAYER_PED_ID()
    end
    if    ( type(ped2) ~= "number" ) or ( natives.ENTITY.DOES_ENTITY_EXIST(ped2) == false ) or ( natives.ENTITY.IS_ENTITY_A_PED(ped2) == false )
    then  ped2 = self.curSpawnPed()
    end
    if    ( type(ped3) ~= "number" ) or ( natives.ENTITY.DOES_ENTITY_EXIST(ped3) == false ) or ( natives.ENTITY.IS_ENTITY_A_PED(ped3) == false )
    then  ped3 = self.curSpawnPed()
    end

    if ( type(xrel)   ~= "number" ) then xrel =  0   ; relDefault = true ; end
    if ( type(yrel)   ~= "number" ) then yrel =  2   ; end
    if ( type(zrel)   ~= "number" ) then zrel = -1   ; end
    if ( type(entrel) ~= "number" ) or ( natives.ENTITY.DOES_ENTITY_EXIST(entrel) == false ) then entrel = ped1 ; end

    local anim_coords = natives.ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS( entrel, xrel, yrel, zrel )

    if  not dict1  then  dict1,anim1  =  self:Find("2g_p1:.*_m")     ; end
    if  not dict2  then  dict2,anim2  =  self:Find("2g_p1:.*p1_s1$") ; end
    if  not dict3  then  dict3,anim3  =  self:Find("2g_p1:.*p1_s2$") ; end

    if    not natives.STREAMING.DOES_ANIM_DICT_EXIST(dict1)
    or    not natives.STREAMING.DOES_ANIM_DICT_EXIST(dict2)
    or    not natives.STREAMING.DOES_ANIM_DICT_EXIST(dict3)
    then  return
    end

    natives.STREAMING.REQUEST_ANIM_DICT(dict1)
    natives.STREAMING.REQUEST_ANIM_DICT(dict2)
    natives.STREAMING.REQUEST_ANIM_DICT(dict3)

    if    not natives.STREAMING.HAS_ANIM_DICT_LOADED(dict1)
    or    not natives.STREAMING.HAS_ANIM_DICT_LOADED(dict2)
    or    not natives.STREAMING.HAS_ANIM_DICT_LOADED(dict3)
    then  self:PlaySync3Queue(ped1,dict1,anim1,ped2,dict2,anim2,ped3,dict3,anim3,entrel,xrel,yrel,zrel) ; return
    end

  --streaming.RequestAnimDict(dict1)

    -- if dict2 ~= dict1 then streaming.RequestAnimDict(dict2) ; end
    -- if dict3 ~= dict2 and dict3 ~= dict1 then streaming.RequestAnimDict(dict3) ; end

    self:resetPedAnim(ped1,true)
    self:resetPedAnim(ped2,true)
    self:resetPedAnim(ped3,true)

    local animDuration1 = natives.ENTITY._GET_ENTITY_ANIM_DURATION(dict1,anim1)
    local animDuration2 = natives.ENTITY._GET_ENTITY_ANIM_DURATION(dict2,anim2)
    local animDuration3 = natives.ENTITY._GET_ENTITY_ANIM_DURATION(dict3,anim3)

    local scene1 = natives.PED.CREATE_SYNCHRONIZED_SCENE(anim_coords.x,anim_coords.y,anim_coords.z, 0.0, 0.0, 0.0, 0)
    natives.PED.SET_SYNCHRONIZED_SCENE_LOOPED(scene1, true)
    natives.AI.TASK_SYNCHRONIZED_SCENE(ped1, scene1, dict1, anim1, animDuration1, -4.0, 64, 0, 0x447a0000, 0)
    natives.AI.TASK_SYNCHRONIZED_SCENE(ped2, scene1, dict2, anim2, animDuration2, -4.0, 1,  0, 0x447a0000, 0)
    natives.AI.TASK_SYNCHRONIZED_SCENE(ped3, scene1, dict3, anim3, animDuration3, -4.0, 1,  0, 0x447a0000, 0)
    natives.PED.SET_SYNCHRONIZED_SCENE_PHASE(scene1, 0.0)

    --timer.Simple(animDuration1*1000, function()  if natives.ENTITY.IS_ENTITY_PLAYING_ANIM(ped1,dict1,anim1,3) then self:resetPedAnim(ped1) ; end ; end, "" )
    --timer.Simple(animDuration2*1000, function()  if natives.ENTITY.IS_ENTITY_PLAYING_ANIM(ped2,dict2,anim2,3) then self:resetPedAnim(ped2) ; end ; end, "" )
    --timer.Simple(animDuration3*1000, function()  if natives.ENTITY.IS_ENTITY_PLAYING_ANIM(ped3,dict3,anim3,3) then self:resetPedAnim(ped3) ; end ; end, "" )

    natives.STREAMING.REMOVE_ANIM_DICT(dict1)
    natives.STREAMING.REMOVE_ANIM_DICT(dict2)
    natives.STREAMING.REMOVE_ANIM_DICT(dict3)
end


function ANIM:SetCurrentTime(ent,animdict,newTime)
  if type(ent) ~= "number" or type(animdict) ~= "string" or type(newTime) ~= "number" then natives.ENTITY.SET_ENTITY_ANIM_CURRENT_TIME(ent,animdict,newTime) ; end
end


function ANIM:PlaySync1(ped1,dict1,anim1,entrel,xrel,yrel,zrel)

    if ( cFUN ~= nil ) and ( type(cFUN.spawnPed) == "function" ) then  self.curSpawnPed = cFUN.spawnPed  ; else self.curSpawnPed = self.SpawnPed ; end

    local rndGroup,rndElement,tmpVal = 0,0,0
    local rndModel = {}
    local ped1_model = ""
    local relDefault = false

    if    ( type(ped1) ~= "number" ) or ( natives.ENTITY.DOES_ENTITY_EXIST(ped1) == false ) or ( natives.ENTITY.IS_ENTITY_A_PED(ped1) == false )
    then  ped1 = self.curSpawnPed()
    end

    if ( type(xrel)   ~= "number" ) then xrel =  0   ; relDefault = true ; end
    if ( type(yrel)   ~= "number" ) then yrel =  2   ; end
    if ( type(zrel)   ~= "number" ) then zrel = -0.5 ; end
    if ( type(entrel) ~= "number" ) or ( natives.ENTITY.DOES_ENTITY_EXIST(entrel) == false ) then entrel = ped1 ; end
    local anim_coords = natives.ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS( entrel, xrel, yrel, zrel )
    local anim_dict_ped_1,anim_ped_1  =  self:Find("2g_p1:.*_m")
    if ( type(dict1)  == "string" ) then anim_dict_ped_1 = self:Find(dict1..".*:") ; end
    if ( type(anim1)  == "string" ) then anim_anim_ped_1 = anim1 ; end
    
    natives.STREAMING.REQUEST_ANIM_DICT(dict1)

    if    not natives.STREAMING.HAS_ANIM_DICT_LOADED(dict1)
    then  self:PlaySync1Queue(ped1,dict1,anim1,entrel,xrel,yrel,zrel) ; return
    end

    self:resetPedAnim(ped1,true)

    local animDuration1 = natives.ENTITY._GET_ENTITY_ANIM_DURATION(anim_dict_ped_1,anim_ped_1)

    local scene1 = natives.PED.CREATE_SYNCHRONIZED_SCENE(anim_coords.x,anim_coords.y,anim_coords.z, 0.0, 0.0, 0.0, 2)
    natives.PED.SET_SYNCHRONIZED_SCENE_LOOPED(scene1, true)
    natives.AI.TASK_SYNCHRONIZED_SCENE(ped1, scene1, anim_dict_ped_1, anim_ped_1, animDuration1, -4.0, 64, 0, 0x447a0000, 0)
    natives.PED.SET_SYNCHRONIZED_SCENE_PHASE(scene1, 0.0)

    natives.STREAMING.REMOVE_ANIM_DICT(dict1)

end


function SCREENFX.List(...)
    SCREENFX.Find(...)
end

function SCREENFX.Find(ScreenFX,index)

    local   curList    = {}
    local   curListStr = ""
    index = tonumber(index or -1) or -1

    if      (   ( type(ScreenFX) == "number" ) or ( type(ScreenFX) == "string" )   )
    then
            if      ( SCREENFX.list[ScreenFX] ~= nil )
            then    curList[1] = SCREENFX.list[ScreenFX]
            elseif  ( type(ScreenFX) == "string" )
            then    for k,v in pairs(SCREENFX.list) do if ( string.lower(v) ~=  string.gsub( string.lower(v),string.lower(ScreenFX),"" ) ) then curList[#curList+1] = v ; curListStr = curListStr .. " " .. v ; end ; end
            end
            if ( #curList == 0 )
            then  curList[1] = SCREENFX.list[math.random(1,#SCREENFX.list)]
            end
    else
            curList[1] = SCREENFX.list[math.random(1,#SCREENFX.list)]
    end

    if      ( #curList == 0 )
    then    for k,v in pairs(SCREENFX.list) do  if ( type(k) == "number" ) and ( type(v) == "string" ) then  curList[#curList+1] = v ; curListStr = curListStr .. " " .. v ; end ; end
    end

    --print( string.format( "%30s %30s %s\n", curListStr ) )

    for i = 1,#curList do curList[i] = string.gsub(curList[i]," ","") ; end

    if      ( #curList == 0 )
    then
        curList[1] = string.gsub( SCREENFX.list[math.random(1,#SCREENFX.list)], " ","" )
        return(unpack(curList))

    elseif  ( index == -1 )
    then
        return curList

    else
        return curList[(index-1)%#curList+1]
    end        

end


function SCREENFX:Play(ScreenFX,silent)

    if    type(silent) == "boolean" then self.silent = silent ; end

    if    ( self.queue == nil )
    then  self.queue = {}
    end

    if  not ScreenFX
    then
        if ( #self.queue ~= 0 )
        then
            natives.GRAPHICS._START_SCREEN_EFFECT( self.queue[#self.queue], 0, false )
            if not  self.silent  then  UTILS.notify("~s~Start Screen FX: ~b~"..tostring( self.queue[#self.queue] ) )  ; end
            table.remove(self.queue,#self.queue)
        end
        return true
    end

    if      type(ScreenFX) == "string"  then  ScreenFX = string.gsub(ScreenFX," ","") ; end

    if      ( type(ScreenFX) == "string" ) and ( ( ScreenFX == "random" ) or ( ScreenFX == "" )  )
    then    ScreenFX = self.list[math.random(1,#self.list)]

    elseif  ( type(ScreenFX) == "string" ) and ( self.list[ScreenFX] == nil )
    then    ScreenFX = self.Find(ScreenFX,1)

    elseif  ( type(ScreenFX) == "table"  ) and ( #ScreenFX > 0 )
    then    ScreenFX = ScreenFX[math.random(1,#ScreenFX)]

    elseif  ( type(ScreenFX) == "table" )
    then    ScreenFX = self.list[math.random(1,#self.list)]

    elseif  ( type(ScreenFX) == "number" )  and ( self.list[ScreenFX] ~= nil )
    then    local tmpScreenFX = self.list[ScreenFX] ; ScreenFX = tmpScreenFX

    elseif  ( type(ScreenFX) == "string" )  and ( self.Find(ScreenFX,1) ~= nil )
    then    local tmpScreenFX = self.Find(ScreenFX,1) ; ScreenFX = tmpScreenFX

    else    local tmpScreenFX = self.list[math.random(1,#self.list)] ; ScreenFX = tmpScreenFX
    end

    if    ( type(ScreenFX) ~= "string" )
    then  return false
    end

    if      ( self.list[ScreenFX] == nil )
    then    ScreenFX = self.list[math.random(1,#self.list)]
    end

    self.queue[#self.queue+1] = ScreenFX

    return true

end


function SCREENFX:Stop(ScreenFX,silent)

    if      type(silent) == "boolean" then self.silent = silent ; end

    if      ( type(ScreenFX) == "nil" )
    then    natives.GRAPHICS._STOP_ALL_SCREEN_EFFECTS()
    elseif  ( type(ScreenFX) == "number" ) and ( self.list[ScreenFX] ~= nil )
    then    local tmpScreenFX = self.list[ScreenFX] ; ScreenFX = tmpScreenFX  
    elseif  ( type(ScreenFX) == "string" ) and ( self.list[ScreenFX] ~= nil )
    then    -- Do nothing to ScreenFX, if it matches a current screenfx
    elseif  ( type(ScreenFX) == "string" ) and ( self.list[ScreenFX] == nil ) and ( self.Find(ScreenFX)[1] ~= nil )
    then    local tmpScreenFX = self.Find(ScreenFX)[1] ; ScreenFX = tmpScreenFX
    else    ScreenFX = self.list[math.random(1,#self.list)]
    end

    if    ( type(ScreenFX) == "string" ) and ( ScreenFX ~= "" )
    then  natives.GRAPHICS._STOP_SCREEN_EFFECT( ScreenFX )
    end

end

return  ANIM, SCREENFX, SOUND
