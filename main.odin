package sol

import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"
import "core:mem"
import vmem "core:mem/virtual"

FRAME_RATE:i32 : 500
STEP_RATE:i32 : 96

GAME_END_HAND:int : 10
GAME_START_HAND:int : 0
PEOPLE_TARGET:int : 100
WEALTH_TARGET:int : 150
SCORE_TARGET:int : 300

Game_Settings :: struct {
	births:bool
}

Game_State :: enum {
	None,
	Title,
	Rules,
	Running,
	Modal,
	Ended,
	Exited
}

Game_Step :: enum {
	Init,
	Select,
	Play,
	End
}

Game_Mode :: enum {
	People = 0,
	Wealth = 1,
	Score = 2
}

Event_Flags :: enum {
    Shift,
    Cntl,
    Left,
    Right,
    Up,
    Down
}

Event_Type :: enum {
    Click,
    Alt_Click,
    DoubleClick,
	Scroll
}

Event :: struct {
    e_type:Event_Type,
    flags:bit_set[Event_Flags],
    pos:rl.Vector2,
	vals:[]f32
}

game_settings := Game_Settings{
	births = false
}

target_width:f32= 1920
target_height:f32 = 1080
target_ratio:f32 = target_height / target_width

screen_width:f32 = 1920
screen_height:f32 = 1080

active_width:f32 = f32(screen_width)
active_height:f32 = f32(screen_height)
active_x:f32 = 0
active_y:f32 = 0

monitor:i32 = -1

delta:f32 = 0
s_delta:f32 = 0

step:int = 0
step_delta:int = 0

game_state:Game_State = Game_State.Title
game_step:Game_Step = Game_Step.Init
prev_game_step:Game_Step = Game_Step.Init
game_mode:Game_Mode = Game_Mode.People
game_mode_targets := [3]int { PEOPLE_TARGET, WEALTH_TARGET, SCORE_TARGET }
game_level:int = 1
game_hand:int = GAME_START_HAND
events := make([dynamic]Event)

card_info:int = -1

ending_won:bool = false
ending_msg := []string{
	"You Lost.",
	"You did not complete the goal."
}

set_flags:bit_set[Event_Flags]
set_flags_prev := bit_set[Event_Flags]{}

game_log_data := make([dynamic]string)
prev_log_len:int = 0

mouse_pos:rl.Vector2 = { -1, -1 }

log_arena : vmem.Arena
log_alloc := vmem.arena_allocator(&log_arena)

main :: proc() {
	//if 1 == 0 {
		default_allocator := context.allocator
		tracking_allocator: mem.Tracking_Allocator
		mem.tracking_allocator_init(&tracking_allocator, default_allocator)
		context.allocator = mem.tracking_allocator(&tracking_allocator)

		defer {
			if len(tracking_allocator.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(tracking_allocator.allocation_map))
				for _, entry in tracking_allocator.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(tracking_allocator.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(tracking_allocator.bad_free_array))
				for entry in tracking_allocator.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&tracking_allocator)
		}
	//}


    rl.SetTraceLogLevel(rl.TraceLogLevel.NONE)
	rl.SetConfigFlags({ .VSYNC_HINT, .MSAA_4X_HINT, .WINDOW_UNDECORATED, .WINDOW_HIGHDPI })

	start_w:i32 = i32(screen_width)
	start_h:i32 = i32(screen_height)
	go_full:bool = true
	if go_full {
		rl.InitWindow(start_w, start_h, "cards")
		rl.ToggleFullscreen()
		curr_scale := rl.GetWindowScaleDPI()
		curr_width:f32 = f32(rl.GetScreenWidth()) / curr_scale.x
		curr_height:f32 = f32(rl.GetScreenHeight()) / curr_scale.y
		if curr_width != target_width || curr_height != target_height {
			active_width = curr_width
			active_height = curr_width * target_ratio
			active_y = (curr_height - active_height) * 0.5
			active_x = 0
			screen_width = curr_width
			screen_height = curr_height
		}
	} else {
		curr_scale := rl.GetWindowScaleDPI()
		curr_width:f32 = f32(rl.GetScreenWidth()) / curr_scale.x // f32(start_w)
		curr_height:f32 = f32(rl.GetScreenHeight()) / curr_scale.y //f32(start_h)
		rl.InitWindow(i32(curr_width), i32(curr_height), "cards")
		if curr_width != target_width || curr_height != target_height {
			active_width = curr_width
			active_height = active_width * target_ratio
			active_y = (curr_height - active_height) * 0.5
			active_x = 0
			screen_width = curr_width
			screen_height = curr_height
		}
	}

	rl.SetTargetFPS(FRAME_RATE)
	defer rl.CloseWindow()

	init_island()
	defer end_island()

	init_game()
	defer end_game()

    ig:int = init_graphics()
    defer end_graphics()

	init_board()

    for !rl.WindowShouldClose() && game_state != Game_State.Exited {

		// ------------------
		//   Key Modifiers
		// ------------------

		if rl.IsKeyDown(rl.KeyboardKey.LEFT_CONTROL) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_CONTROL) {
			set_flags += { .Cntl }
		} else {
			set_flags -= { .Cntl }
		}

        if rl.IsKeyDown(rl.KeyboardKey.LEFT_SHIFT) || rl.IsKeyDown(rl.KeyboardKey.RIGHT_SHIFT) {
			set_flags += { .Shift }
		} else {
			set_flags -= { .Shift }
		}

		if rl.IsKeyDown(rl.KeyboardKey.LEFT) || rl.IsKeyDown(rl.KeyboardKey.A) {
			set_flags += { .Left }
		} else {
			set_flags -= { .Left }
		}

		if rl.IsKeyDown(rl.KeyboardKey.RIGHT) || rl.IsKeyDown(rl.KeyboardKey.D) {
			set_flags += { .Right }
		} else {
			set_flags -= { .Right }
		}

		if rl.IsKeyDown(rl.KeyboardKey.UP) || rl.IsKeyDown(rl.KeyboardKey.W) {
			set_flags += { .Up }
		} else {
			set_flags -= { .Up }
		}

		if rl.IsKeyDown(rl.KeyboardKey.DOWN) || rl.IsKeyDown(rl.KeyboardKey.S) {
			set_flags += { .Down }
		} else {
			set_flags -= { .Down }
		}

		// ------------------
		// ------------------

		// ------------------
		//       mouse
		// ------------------
		mouse_pos = rl.GetMousePosition()

		if game_state == .Title {
			 if hit(mouse_pos, board.start_button) {
				if !(.Highlighted in board.start_button_status) {
					board.start_button_status += { .Highlighted }
				}
			 } else if .Highlighted in board.start_button_status {
				board.start_button_status -= { .Highlighted }
			 }

			 if hit(mouse_pos, board.exit_button) {
				if !(.Highlighted in board.exit_button_status) {
					board.exit_button_status += { .Highlighted }
				}
			 } else if .Highlighted in board.exit_button_status {
				board.exit_button_status -= { .Highlighted }
			 }

			 for tt in 0..<3 {
				if hit(mouse_pos, board.mode_buttons[tt]) {
					if !(.Opened in tool_tips[tt].status) {
						tool_tips[tt].status += { .Opened }
					}
				} else if .Opened in tool_tips[tt].status {
					tool_tips[tt].status -= { .Opened }
				}
			}

		} else if game_state == .Rules {
			if hit(mouse_pos, board.continue_button) {
				if !(.Highlighted in board.continue_button_status) {
					board.continue_button_status += { .Highlighted }
				}
			 } else if .Highlighted in board.continue_button_status {
				board.continue_button_status -= { .Highlighted }
			 }
		} else if game_state == .Running {

			if hit(mouse_pos, board.play_button) {
				if !(.Highlighted in board.play_button_status) {
					board.play_button_status += { .Highlighted }
				}
			 } else if .Highlighted in board.play_button_status {
				board.play_button_status -= { .Highlighted }
			 }

			if hit(mouse_pos, board.suit_target) {
				if !(.Opened in tool_tips[3].status) {
					tool_tips[3].status += { .Opened }
				}
			} else if .Opened in tool_tips[3].status {
				tool_tips[3].status -= { .Opened }
			}

			if hit(mouse_pos, board.spell_target) {
				if !(.Opened in tool_tips[4].status) {
					tool_tips[4].status += { .Opened }
				} 
			} else if .Opened in tool_tips[4].status {
				tool_tips[4].status -= { .Opened }
			}

			on_card:bool = false
			for c in 0..<len(deck) {
				if hit(mouse_pos, deck[c].hit) && deck[c].owner == player.id {
					on_card = true
					board.hover_card_idx = c
				}
			}
			if on_card {
				if !(.Opened in tool_tips[5].status) {
					tool_tips[5].status += { .Opened }
				} 
			} else if .Opened in tool_tips[5].status {
				tool_tips[5].status -= { .Opened }
			}

			for ss in 0..<3 {
				if hit(mouse_pos, board.player_map_stats[ss]) {
					if !(.Opened in tool_tips[ss + 6].status) {
						tool_tips[ss + 6].status += { .Opened }
					} 
				} else if .Opened in tool_tips[ss + 6].status {
					tool_tips[ss + 6].status -= { .Opened }
				}
			}
		}

		if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
			inject_at(&events, 0, Event{
				e_type = .Click,
				flags = set_flags + {},
				pos = mouse_pos,
				vals = []f32{}
			})
		}

		if rl.IsMouseButtonPressed(rl.MouseButton.RIGHT) {
			inject_at(&events, 0, Event{
				e_type = .Alt_Click,
				flags = set_flags + {},
				pos = mouse_pos,
				vals = []f32{}
			})
		}

		mouseWheelMovement := rl.GetMouseWheelMove()

		if mouseWheelMovement != 0 {
			inject_at(&events, 0, Event{
				e_type = .Scroll,
				flags = set_flags + {},
				pos = mouse_pos,
				vals = []f32{ mouseWheelMovement }
			})
		}

		// ------------------
		// ------------------


        delta += rl.GetFrameTime()
		s_delta += rl.GetFrameTime()
		runStep := false

		if s_delta >= 1 / f32(STEP_RATE) {
			s_delta = 0
			runStep = true
		}

		prev_step:int = step
		if runStep {
			// run game step
			step += 1
			run_step()
		}
		step_delta = step - prev_step

        {
			process_events()

            rl.BeginDrawing()
            rl.ClearBackground(BG_COLOR)
            // draw game step	
            g_draw_game()
    
            rl.EndDrawing()
        }
    }
}

init_game :: proc() {
	init_deck()

	game_mode = Game_Mode.People
	board.mode_buttons_status[int(game_mode)] += { .Active }
	board.level_buttons_status[game_level - 1] += { .Active }

	if game_state == .Running {
		run_game_step()
	}
}

start_game :: proc() {
	game_state = .Running
	set_game_step(.Init)

	ending_won = false
	ending_msg[0] = "You Lost."
	ending_msg[1] = "You did not complete the goal."

	game_hand = GAME_START_HAND

	game_mode_targets = [3]int { PEOPLE_TARGET * game_level, WEALTH_TARGET * game_level, SCORE_TARGET * game_level }

	player.score = INIT_SCORE
    clear(&player.hand)
	clear(&player.play.cards)
	player.play.mode = Card_Mode.Suit
    player.last_roll = 0

    dealer.score = INIT_SCORE
    dealer.hand_size = 1
    clear(&dealer.play.cards)
	dealer.play.mode = Card_Mode.Suit
    dealer.last_roll = roll()

	delete(game_log_data)
	game_log_data = make([dynamic]string)
	g_update_log()

	start_island()

	reset_deck()

	run_game_step()
}

end_game :: proc() {
	delete(player.play.cards)
	delete(player.hand)
	delete(dealer.play.cards)
	delete(dealer.hand)
	delete(game_log_data)

	free_all(log_alloc)
    vmem.arena_destroy(&log_arena)
}

game_log :: proc(msg:string) {
	l_msg:string = strings.clone(msg, allocator = log_alloc)
	append(&game_log_data, l_msg)
	g_update_log()
}

run_step :: proc() {
	if len(animations) > 0 {
		an_run_animations()
	}
}

set_mode :: proc(mode:Game_Mode) {
	game_mode = mode
	m_idx:int = int(mode)
	for i in 0..<3 {
		if i != m_idx && .Active in board.mode_buttons_status[i] {
			board.mode_buttons_status[i] -= { .Active }
		} else if i == m_idx && !(.Active in board.mode_buttons_status[i]) {
			board.mode_buttons_status[i] += { .Active }
		}
	}
}

set_level :: proc(level:int) {
	game_level = level
	lv_idx:int = level - 1
	for i in 0..<3 {
		if i != lv_idx && .Active in board.level_buttons_status[i] {
			board.level_buttons_status[i] -= { .Active }
		} else if i == lv_idx && !(.Active in board.level_buttons_status[i]) {
			board.level_buttons_status[i] += { .Active }
		}
	}
}

dealer_roll :: proc() {
	for len(dealer.play.cards) > 0 {
		dc:int = pop(&dealer.play.cards)
		discard(dc)
	}
	dealer.last_roll = roll()
	if dealer.last_roll <= 3 {
		dealer.hand_size = dealer.last_roll
		dealer.play.mode = .Suit
	} else {
		i_roll2:int = dealer.last_roll - 3
		dealer.hand_size = i_roll2
		dealer.play.mode = .Spell
	}
	dealer_dice_rot = rand.float32() * 360
}

process_events :: proc() {
	for len(events) > 0 {
		event:Event = pop(&events)

		switch (event.e_type) {
			case .Click:
				if game_state == .Title {
					if hit(event.pos, board.exit_button) {
						game_state = .Exited
					} else if hit(event.pos, board.start_button) {
						game_state = .Running
						start_game()
					} else if hit(event.pos, board.rules_button) {
						game_state = .Rules
					}

					if hit(event.pos, board.mode_buttons[int(Game_Mode.People)]) {
						set_mode(.People)
					} else if hit(event.pos, board.mode_buttons[int(Game_Mode.Wealth)]) {
						set_mode(.Wealth)
					} else if hit(event.pos, board.mode_buttons[int(Game_Mode.Score)]) {
						set_mode(.Score)
					}

					if hit(event.pos, board.level_buttons[0]) {
						set_level(1)
					} else if hit(event.pos, board.level_buttons[1]) {
						set_level(2)
					} else if hit(event.pos, board.level_buttons[2]) {
						set_level(3)
					}
				} else if game_state == .Rules {
					if hit(event.pos, board.continue_button) {
						game_state = .Title
					}
				} else if game_state == .Modal {
					if !hit(event.pos, board.modal) {
						game_state = .Running
						board.help_card_display = -1
						board.help_map_display = false
					}	
				} else if game_state == .Ended {
					if hit(event.pos, board.ending_exit_button) {
						game_state = .Exited
					} else if hit(event.pos, board.ending_restart_button) {
						game_state = .Title
					}
				} else {

					if hit(event.pos, board.settings_button) {
						game_state = .Exited
					} else {
						
						if game_step == .Select {
							for c in 0..<len(deck) {
								if hit(event.pos, deck[c].hit) && deck[c].owner == player.id {
									if .Selected in deck[c].status {
										deck[c].status -= { .Selected }
										deck[c].display.y += board.card_padding
										deck[c].hit.y += board.card_padding
										for i := len(player.play.cards) - 1; i >= 0; i -= 1 {
											if player.play.cards[i] == c {
												ordered_remove(&player.play.cards, i) 
											}
										}
									} else if len(player.play.cards) < 3 {
										deck[c].status += { .Selected }
										deck[c].display.y -= board.card_padding
										deck[c].hit.y -= board.card_padding
										append(&player.play.cards, c)
									}
								}
							}
							
							if hit(event.pos, board.suit_target) {
								set_player_mode(.Suit)
							}
							if hit(event.pos, board.spell_target) {
								set_player_mode(.Spell)
							} 
						}
	
						if hit(event.pos, board.play_button) {
							run_game_step()
						}
					}
				}
			case .Alt_Click:

					has_action:bool = false
					for c in 0..<len(deck) {
						if hit (event.pos, deck[c].hit) && deck[c].owner == player.id {
							if board.help_card_display < 0 {
								board.help_card_display = c
								has_action = true
							}
						}
					} 
					
					if !has_action && hit(event.pos, board.player_map) {
						board.help_map_display = true
						has_action = true
					}

					if has_action {
						game_state = .Modal
						for tt in 0..<len(tool_tips) {
							if .Opened in tool_tips[tt].status {
								tool_tips[tt].status -= { .Opened }
							}
						}
					}

			case .DoubleClick:

			case .Scroll:

				if game_state == .Running {
					if hit(event.pos, board.island_log) {
						board.island_log_scroll.y += (-1 * event.vals[0]) * board.island_log_scroll.x
						if board.island_log_scroll.y < 0 {
							board.island_log_scroll.y = 0
						}
					}
				} else if game_state == .Rules {
					if hit(event.pos, board.instructions_disp) {
						instructions_scroll += (-1 * event.vals[0]) * instructions_lh
						if instructions_scroll < 0 {
							instructions_scroll = 0
						} else if instructions_scroll_max > 0 && instructions_scroll > instructions_scroll_max {
							instructions_scroll = instructions_scroll_max
						}
					}
				}
		}
	}
}

hit :: proc(pos:rl.Vector2, check:rl.Rectangle) -> bool {
	if pos.x <= check.x + check.width && pos.x >= check.x && pos.y <= check.y + check.height && pos.y >= check.y {
		return true
	}

	return false
}

roll :: proc() -> int {
	return int(math.ceil(rand.float32() * 6))
}

set_game_step :: proc(new_step:Game_Step) {
	prev_game_step = game_step
	game_step = new_step
}

run_game_step :: proc() {
	if game_state == .Running {
		switch game_step {
			case .Select:

				if len(player.play.cards) <= 0 {
					game_log("You must play at least one card.")
				} else {
					play_round()
				}
			
			case .Init, .Play:

				setup_round()

			case .End:
		}
	}

}

end_this_game :: proc() {

	clear_animations()

	switch game_mode {
		case .People:
			if island.population >= game_mode_targets[int(Game_Mode.People)] {
				ending_won = true
				ending_msg[0] = "You Won!"
				e_msg := fmt.aprintf("You ended with a population of %d or greater!", game_mode_targets[int(Game_Mode.People)], allocator = log_alloc)
				defer delete(e_msg, allocator = log_alloc)
				ending_msg[1] = e_msg
			} else {
				ending_won = false
				ending_msg[0] = "You Lost!"
				e_msg := fmt.aprintf("You ended with a population under %d.", game_mode_targets[int(Game_Mode.People)], allocator = log_alloc)
				defer delete(e_msg, allocator = log_alloc)
				ending_msg[1] = e_msg
			}
		case .Wealth:
			if island.money >= game_mode_targets[int(Game_Mode.Wealth)] {
				ending_won = true
				ending_msg[0] = "You Won!"
				e_msg := fmt.aprintf("You ended with %d or more coin!", game_mode_targets[int(Game_Mode.Wealth)], allocator = log_alloc)
				defer delete(e_msg, allocator = log_alloc)
				ending_msg[1] = e_msg
			} else {
				ending_won = false
				ending_msg[0] = "You Lost!"
				e_msg := fmt.aprintf("You ended with less than %d coin.", game_mode_targets[int(Game_Mode.Wealth)], allocator = log_alloc)
				defer delete(e_msg, allocator = log_alloc)
				ending_msg[1] = e_msg
			}
		case .Score:
			total_score:int = island.population + island.food + island.money
			if total_score >= game_mode_targets[int(Game_Mode.Score)] {
				ending_won = true
				ending_msg[0] = "You Won!"
				e_msg := fmt.aprintf("You ended with a total score (Population + Food + Coin) of %d or greater!", game_mode_targets[int(Game_Mode.Score)], allocator = log_alloc)
				defer delete(e_msg, allocator = log_alloc)
				ending_msg[1] = e_msg
			} else {
				ending_won = false
				ending_msg[0] = "You Lost!"
				e_msg := fmt.aprintf("You ended with a total score (Population + Food + Coint) under %d.", game_mode_targets[int(Game_Mode.Score)], allocator = log_alloc)
				defer delete(e_msg, allocator = log_alloc)
				ending_msg[1] = e_msg
			}
	}

	game_state = .Ended
}

play_round :: proc() {
	if game_step == .Select {

		for c in 0..<len(player.play.cards) {
			t_pos := g_get_card_pos(player.play.mode, c, 1)
			t_pos.x += board.card_dw * 0.5
			t_pos.y += board.card_dh * 0.5
			if .Selected in deck[player.play.cards[c]].status {
				deck[player.play.cards[c]].status -= { .Selected }
			}
			s_x:f32 = deck[player.play.cards[c]].display.x
			s_y:f32 = .Selected in deck[player.play.cards[c]].status ? deck[player.play.cards[c]].display.y - board.card_padding : deck[player.play.cards[c]].display.y
			an_move_card(player.play.cards[c], { s_x, s_y }, t_pos, A_LEN_CARD_PLAY, c * 5)
		}
		for c in 0..<len(dealer.play.cards) {
			an_flip_card(dealer.play.cards[c], c * 5)
		}

		if game_hand > 1 {
			game_log("---")
		}

		if game_hand > 0 {
			lg_line := fmt.aprintf("Hand %d...", game_hand, allocator = log_alloc)
			defer delete(lg_line, allocator = log_alloc)
			game_log(lg_line)
		}

		score_round()

		prev_log_len = len(game_log_data)

		board.island_log_scroll.y = -1

		set_game_step(.Play)
	} 
}

setup_round :: proc() {
	if game_step == .Play {
		for c:int = len(player.hand) - 1; c >= 0; c -= 1 {
			if .Played in deck[player.hand[c]].status {
				rm_idx:int = player.hand[c]
				an_discard_card(rm_idx, 0)
				discard(rm_idx)
				ordered_remove(&player.hand, c)
			}
		}

		clear(&player.play.cards)
	
		for len(dealer.play.cards) > 0 {
			dc_idx:int = pop(&dealer.play.cards)
			an_discard_card(dc_idx, 0)
			discard(dc_idx)
		}
	}

	dealer_roll()

	deal()

	if game_step == .Init {
		g_update_card_display(true)
	} else {
		g_update_card_display(false)

		dd_pos := g_get_card_pos(dealer.play.mode, 0, -1)
		dd_x := dd_pos.x + (board.card_dw * 0.5)
		dd_y := dd_pos.y + (board.card_dh * 0.5)
		for c in 0..<len(dealer.play.cards) {
			dc_idx := dealer.play.cards[c]
			if deck[dc_idx].display.width == 0 && deck[dc_idx].display.width == 0 {
				s_x:f32 = dd_x
				s_y:f32 = active_y - board.card_dh * 0.6
				e_x:f32 = s_x
				e_y:f32 = dd_y
				an_move_card(dc_idx, { s_x, s_y }, { e_x, e_y }, 16, c * 5)
			}
			dd_x += board.card_dw + board.card_padding
		}

		h_pos := board.player_hand_start
		pp_x:f32 = h_pos.x + (board.card_dw * 0.5)
		pp_y:f32 = h_pos.y + (board.card_dh * 0.5)
		for c in 0..<len(player.hand) {
			hc_idx := player.hand[c]
			if deck[hc_idx].display.width == 0 && deck[hc_idx].display.width == 0 {
				s_x:f32 = pp_x
				s_y:f32 = (active_y + active_height) + board.card_dh * 0.6
				e_x:f32 = s_x
				e_y:f32 = pp_y
				an_move_card(hc_idx, { s_x, s_y }, { e_x, e_y }, 16, c * 5)
			} else if deck[hc_idx].display.x != pp_x {
				an_move_card(hc_idx, { deck[hc_idx].display.x, deck[hc_idx].display.y }, { pp_x, deck[hc_idx].display.y }, A_LEN_CARD_DEAL, c * 5)
			}
			pp_x += board.card_dw + board.card_padding
		}
	}

	if game_hand > 0 {
		game_log("---")
	}

	run_island()

	log_change:int = len(game_log_data) - prev_log_len

	prev_log_len = len(game_log_data)

	game_hand += 1

	if game_hand > GAME_END_HAND {
		set_game_step(.End)
		end_this_game()
	} else {
		set_game_step(.Select)
	} 

	board.island_log_scroll.y = -1
}

score_round :: proc() {

	pre_tally:int = player.score

	if dealer.play.mode == .Spell {
		res := cast_play(&dealer.play, -1)
		sp_x:f32 = board.spell_target_top.x + (board.card_dw * 0.5)
		sp_y:f32 = board.spell_target_top.y + (board.card_dh * 0.5)
		for c in 0..<len(dealer.play.cards) {
			if len(res[c]) > 0 {
				an_score_display(res[c], { sp_x, sp_y }, A_LEN_SUIT_PLAY, A_LEN_CARD_PLAY, board.font_size, [3]u8{ 255, 255, 255 }, false, true)
			}
			sp_x += board.card_dw + board.card_padding
		}
	} else {
		d_score, d_play := score_play(&dealer.play)
		player.score -= d_score
		if d_score == 0 {
			game_log("The deck's play resulted in no changes.")
		} else {
			lg_line := fmt.aprintf("The deck's %s removed %d from your tally.", d_play, d_score, allocator = log_alloc)
			defer delete(lg_line, allocator = log_alloc)
			game_log(lg_line)

			disp_line := fmt.aprintf("%s: %d", d_play, d_score, allocator = log_alloc)
			defer delete(disp_line, allocator = log_alloc)
			an_play_display(disp_line, Card_Mode.Suit, 0, A_LEN_SUIT_PLAY, A_LEN_CARD_PLAY)
		}
	}

	if player.play.mode == .Spell {
		res := cast_play(&player.play, 1)
		sp_x:f32 = board.spell_target_bottom.x + (board.card_dw * 0.5)
		sp_y:f32 = board.spell_target_bottom.y + (board.card_dh * 0.5)
		for c in 0..<len(player.play.cards) {
			if len(res[c]) > 0 {
				an_score_display(res[c], { sp_x, sp_y }, A_LEN_SUIT_PLAY, A_LEN_CARD_PLAY, board.font_size, [3]u8{ 255, 255, 255 }, false, true)
			}
			sp_x += board.card_dw + board.card_padding
		}
	} else {
		d_score, d_play := score_play(&player.play)
		player.score += d_score
		if d_score == 0 {
			game_log("Your play resulted in no changes.")
		} else {
			lg_line := fmt.aprintf("Your %s added %d to your tally.", d_play, d_score, allocator = log_alloc)
			defer delete(lg_line, allocator = log_alloc)
			game_log(lg_line)

			disp_line := fmt.aprintf("%s: %d", d_play, d_score, allocator = log_alloc)
			defer delete(disp_line, allocator = log_alloc)
			an_play_display(disp_line, Card_Mode.Suit, 1, A_LEN_SUIT_PLAY, A_LEN_CARD_PLAY)
		}
	}

	for c in 0..<len(dealer.play.cards) {
		deck[dealer.play.cards[c]].status -= { .Flipped }
		deck[dealer.play.cards[c]].status += { .Played }
	}

	for c in 0..<len(player.play.cards) {
		deck[player.play.cards[c]].status += { .Played }
		if .Selected in deck[player.play.cards[c]].status {
			deck[player.play.cards[c]].status -= { .Selected }
		}
	}

	tally_change:int = player.score - pre_tally
	if tally_change != 0 {
		disp_color:[3]u8 = [3]u8{ 255, 255, 255 }
		t_fs:f32 = board.info_font_size
		t_x:f32 = board.player_info.x + board.player_info.width + (board.card_padding)
		t_y:f32 = board.player_info.y + (board.player_info.height * 0.5) - (t_fs * 0.5)
		if tally_change < 0 {
			disp_color = [3]u8{220, 0, 0}
		} else {
			disp_color = [3]u8{0, 220, 0}
		}
		sign_str:string = tally_change < 0 ? "-" : "+"
		s_txt:string = fmt.aprintf("%s%d", sign_str, math.abs(tally_change), allocator = graph_alloc)
		defer delete(s_txt, allocator = graph_alloc)
		an_score_display(s_txt, { t_x, t_y }, A_LEN_TALLY_DISP, A_LEN_CARD_PLAY, t_fs, disp_color, true)
	}

}


