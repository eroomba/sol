package sol

import "core:fmt"
import "core:math"
import "core:strings"
import "core:math/rand"
import rl "vendor:raylib"


Board_Status :: enum {
    Active,
    Highlighted,
    Hidden
}

Board :: struct {
    width:f32,
    height:f32,

    font_size:f32,
    info_font_size:f32,

    hover_card_idx:int,

    card_dw:f32,
    card_dh:f32,

    help_map_display:bool,
    help_card_display:int,
    modal:rl.Rectangle,

    button_font_size:f32,
    button_padding:f32,
    button_font_spacing:f32,

    logo:rl.Rectangle,

    title:rl.Rectangle,
    rules:rl.Rectangle,
    ending:rl.Rectangle,

    instructions_disp:rl.Rectangle,

    dealer_board:rl.Rectangle,
    dealer_info:rl.Rectangle,

    player_board:rl.Rectangle,
    player_info:rl.Rectangle,

    targets:rl.Rectangle,
    suit_target:rl.Rectangle,
    suit_target_top:rl.Vector2,
    suit_target_bottom:rl.Vector2,
    spell_target:rl.Rectangle,
    spell_target_top:rl.Vector2,
    spell_target_bottom:rl.Vector2,

    player_hand:rl.Rectangle,
    player_hand_start:rl.Vector2,

    player_map:rl.Rectangle,
    island_info:rl.Rectangle,
    island_log:rl.Rectangle,
    island_log_scroll:rl.Vector2,
    island_log_font_size:f32,
    island_log_line_padding:f32,
    
    player_map_stats:[]rl.Rectangle,
    player_map_stats_ids:[]string,

    padding:f32,
    card_padding:f32,

    // buttons

    mode_buttons:[3]rl.Rectangle,
    mode_buttons_status:[3]bit_set[Board_Status],
    mode_buttons_text:[3]cstring,

    level_buttons:[3]rl.Rectangle,
    level_buttons_status:[3]bit_set[Board_Status],
    level_buttons_text:[3]cstring,

    start_button:rl.Rectangle,
    start_button_status:bit_set[Board_Status],
    start_button_text:cstring,
    exit_button:rl.Rectangle,
    exit_button_status:bit_set[Board_Status],
    exit_button_text:cstring,

    rules_button:rl.Rectangle,
    rules_button_status:bit_set[Board_Status],
    rules_button_text:cstring,
    continue_button:rl.Rectangle,
    continue_button_status:bit_set[Board_Status],
    continue_button_text:cstring,

    play_button_pos:rl.Rectangle,
    play_button:rl.Rectangle,
    play_button_status:bit_set[Board_Status],
    settings_button:rl.Rectangle,
    settings_button_status:bit_set[Board_Status],

    ending_exit_button:rl.Rectangle,
    ending_exit_button_status:bit_set[Board_Status],
    ending_exit_button_text:cstring,
    ending_restart_button:rl.Rectangle,
    ending_restart_button_status:bit_set[Board_Status],
    ending_restart_button_text:cstring 
}

Tool_Tip_Status :: enum {
    Opened,
    Follow,
    Relative,
    Static
}

Tool_Tip :: struct {
    id:string,
    pos:rl.Vector2,
    text:string,
    status:bit_set[Tool_Tip_Status]
}

board := Board{
    width = active_width,
    height = active_height,

    font_size = 10,
    info_font_size = 12,

    hover_card_idx = -1,
    card_dw = active_width * 0.07,
    card_dh = math.floor((f32(350) / f32(250)) * (active_width * 0.07)),

    help_map_display = false,
    help_card_display = -1,
    modal = { 0, 0, 0, 0 },

    logo = { 0, 0, 0, 0 },

    button_font_size = 12,
    button_padding = 8,
    button_font_spacing = 2,

    title = { 0, 0, 0, 0 },
    rules = { 0, 0, 0, 0 },
    ending = { 0, 0, 0, 0 },

    instructions_disp = { 0, 0, 0, 0 },

    dealer_board = { 0, 0, 0, 0 },
    dealer_info = { 0, 0, 0, 0 },

    player_board = { 0, 0, 0, 0 },
    player_info = { 0, 0, 0, 0 },

    targets = { 0, 0, 0, 0 },
    suit_target = { 0, 0, 0, 0 },
    suit_target_top = { 0, 0 },
    suit_target_bottom = { 0, 0 },
    spell_target = { 0, 0, 0, 0 },
    spell_target_top = { 0, 0 },
    spell_target_bottom = { 0, 0 },

    player_hand = { 0, 0, 0, 0 },
    player_hand_start = { 0, 0 },

    player_map = { 0, 0, 0, 0 },
    island_info = { 0, 0, 0, 0 },
    island_log = { 0, 0, 0, 0 },
    island_log_scroll = { 0, 0 },
    island_log_font_size = 10,
    island_log_line_padding = 3,

    player_map_stats = []rl.Rectangle{
        rl.Rectangle{ 0, 0, 0, 0 },
        rl.Rectangle{ 0, 0, 0, 0 },
        rl.Rectangle{ 0, 0, 0, 0 }
    },
    player_map_stats_ids = []string { "MapPopulation", "MapFood", "MapMoney" },

    padding = 10,
    card_padding = 8,

    // buttons

    mode_buttons = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    },
    mode_buttons_status = [3]bit_set[Board_Status]{ bit_set[Board_Status]{}, bit_set[Board_Status]{}, bit_set[Board_Status]{}},
    mode_buttons_text = [3]cstring{ "People", "Wealth", "Score" },
    
    level_buttons = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    },
    level_buttons_status = [3]bit_set[Board_Status]{ bit_set[Board_Status]{}, bit_set[Board_Status]{}, bit_set[Board_Status]{}},
    level_buttons_text = [3]cstring{ "Easy", "Medium", "Hard" },

    start_button = { 0, 0, 0, 0 },
    start_button_status = bit_set[Board_Status]{}, 
    start_button_text = "START",
    exit_button = { 0, 0, 0, 0 },
    exit_button_status = bit_set[Board_Status]{},
    exit_button_text = "EXIT",

    rules_button = { 0, 0, 0, 0 },
    rules_button_status = bit_set[Board_Status]{},
    rules_button_text = "HOW TO PLAY",
    continue_button = { 0, 0, 0, 0 },
    continue_button_status = bit_set[Board_Status]{},
    continue_button_text = "BACK",

    play_button_pos = { 0, 0, 0, 0 },
    play_button = { 0, 0, 0, 0 },
    play_button_status = bit_set[Board_Status]{},
    settings_button = { 0, 0, 0, 0 },
    settings_button_status = bit_set[Board_Status]{},

    ending_exit_button = { 0, 0, 0, 0 },
    ending_exit_button_status = bit_set[Board_Status]{},
    ending_exit_button_text = "EXIT",
    ending_restart_button = { 0, 0, 0, 0 },
    ending_restart_button_status = bit_set[Board_Status]{},
    ending_restart_button_text = "MAIN MENU"

}

tt_mouse_off:f32 = active_height * 0.02
tool_tips := []Tool_Tip{
    Tool_Tip{ // 0
        id = "ModePeople",
        pos = { tt_mouse_off, tt_mouse_off },
        text = "End with at lease %d people <br> in the population.",
        status = bit_set[Tool_Tip_Status]{ .Follow }
    },
    Tool_Tip{ // 1
        id = "ModeWealth",
        pos = { tt_mouse_off, tt_mouse_off },
        text = "End with at least %d coin.",
        status = bit_set[Tool_Tip_Status]{ .Follow }
    },
    Tool_Tip{ // 2
        id = "ModeScore",
        pos = { tt_mouse_off, tt_mouse_off },
        text = "End with your sum of population, <br> food, and coin at %d or higher.",
        status = bit_set[Tool_Tip_Status]{ .Follow }
    },
    Tool_Tip{ // 3
        id = "TargetSuit",
        pos = { tt_mouse_off, tt_mouse_off },
        text = "Click to play card(s) <br> in SUIT mode.",
        status = bit_set[Tool_Tip_Status]{ .Follow }
    },
    Tool_Tip{ // 4
        id = "TargetSpell",
        pos = { tt_mouse_off, tt_mouse_off },
        text = "Click to play card(s) <br> in SPELL mode.",
        status = bit_set[Tool_Tip_Status]{ .Follow }
    },
    Tool_Tip{ // 5
        id = "CardHover",
        pos = { 0, -0.5},
        text = "%d of %s <br> %s",
        status = bit_set[Tool_Tip_Status]{ .Relative }
    },
    Tool_Tip{ // 6
        id = "MapPopulation",
        pos = { tt_mouse_off, tt_mouse_off },
        text = "Population",
        status = bit_set[Tool_Tip_Status]{ .Follow }
    },
    Tool_Tip{ // 7
        id = "MapFood",
        pos = { tt_mouse_off, tt_mouse_off },
        text = "Food",
        status = bit_set[Tool_Tip_Status]{ .Follow }
    },
    Tool_Tip{ // 8
        id = "MapMoney",
        pos = { tt_mouse_off, tt_mouse_off },
        text = "Coin",
        status = bit_set[Tool_Tip_Status]{ .Follow }
    }
}

init_board :: proc() {
    calculate_board()
}

end_board :: proc() {

}

calculate_board :: proc() {    

    board.font_size = math.ceil(active_height * 0.025)
    board.info_font_size = active_height * 0.03

    board.button_font_size = active_height * 0.045
    board.button_padding = active_height * 0.02
    board.button_font_spacing = 0

    board.island_log_font_size = active_height * 0.02 < 10 ? 10 : active_height * 0.02
    board.island_log_line_padding = board.island_log_font_size * 0.25 < 3 ? 3 : board.island_log_font_size * 0.25

    board.padding = math.floor(active_width * 0.02)
    board.card_padding = math.floor(active_width * 0.01)

    board.card_dw = active_width * 0.07
    board.card_dh = math.floor((f32(350) / f32(250)) * (active_width * 0.07))

    cx:f32 = active_x + board.padding
    cy:f32 = active_y + board.padding

    sb_w:f32 = active_width * 0.02
    sb_p:f32 = active_width * 0.005

    sb_x:f32 = active_x + (active_width - sb_w - sb_p)
    sb_y:f32 = active_y + sb_p

    board.settings_button = { sb_x, sb_y, sb_w, sb_w }

    // -------

    board.title = { active_x + (board.padding * 2), active_y + (board.padding), active_width - (board.padding * 4), active_height - (board.padding * 2)}
    s_button_size := rl.MeasureTextEx(button_font, board.start_button_text, board.button_font_size, board.button_font_spacing)
    board.start_button.width = s_button_size.x + (6 * board.button_padding)
    board.start_button.height = s_button_size.y + (2 * board.button_padding)

    e_button_size := rl.MeasureTextEx(button_font, board.exit_button_text, board.button_font_size, board.button_font_spacing)
    board.exit_button.width = e_button_size.x + (6 * board.button_padding)
    board.exit_button.height = e_button_size.y + (2 * board.button_padding)

    b1_w:f32 = board.start_button.width + board.exit_button.width + board.padding
    b1_x:f32 = (active_width * 0.5) - (b1_w * 0.5)

    board.start_button.x = b1_x
    board.start_button.y = board.title.y + board.title.height - board.button_font_size - board.start_button.height

    board.exit_button.x = b1_x + board.start_button.width + board.padding
    board.exit_button.y = board.start_button.y

    r_button_size := rl.MeasureTextEx(button_font, board.rules_button_text, board.button_font_size, board.button_font_spacing)
    board.rules_button.width = r_button_size.x + (4 * board.button_padding)
    board.rules_button.height = r_button_size.y + (2 * board.button_padding)
    board.rules_button.x = (active_width * 0.5) - (board.rules_button.width * 0.5)
    board.rules_button.y = board.start_button.y - board.button_font_size - board.rules_button.height

    lv_button_w:f32 = board.title.width * 0.1
    lv_button_h:f32 = board.button_font_size * 2
    lv_button_pad:f32 = board.title.width * 0.015

    lv_buttons_w:f32 = (3 * lv_button_w) + (2 * lv_button_pad)
    lv_buttons_x:f32 = active_x + (active_width * 0.5) - (lv_buttons_w * 0.5)
    lv_buttons_y:f32 = board.rules_button.y  - lv_button_h - (board.padding * 1.5)

    board.level_buttons[0] = { lv_buttons_x, lv_buttons_y, lv_button_w, lv_button_h}
    board.level_buttons[1] = { lv_buttons_x + (1 * lv_button_w) + (1 * lv_button_pad), lv_buttons_y, lv_button_w, lv_button_h}
    board.level_buttons[2] = { lv_buttons_x + (2 * lv_button_w) + (2 * lv_button_pad), lv_buttons_y, lv_button_w, lv_button_h}

    m_button_w:f32 = board.title.width * 0.2
    m_button_h:f32 = board.button_font_size * 2
    m_button_pad:f32 = board.title.width * 0.02

    m_buttons_w:f32 = (3 * m_button_w) + (2 * m_button_pad)
    m_buttons_x:f32 = (active_width * 0.5) - (m_buttons_w * 0.5)
    m_buttons_y:f32 = lv_buttons_y - m_button_h - board.padding

    board.mode_buttons[0] = { m_buttons_x, m_buttons_y, m_button_w, m_button_h}
    board.mode_buttons[1] = { m_buttons_x + (1 * m_button_w) + (1 * m_button_pad), m_buttons_y, m_button_w, m_button_h}
    board.mode_buttons[2] = { m_buttons_x + (2 * m_button_w) + (2 * m_button_pad), m_buttons_y, m_button_w, m_button_h}

    board.logo.height = m_buttons_y - board.title.y - (3 * board.padding)
    board.logo.width = (f32(textures[txt_logo].width) / f32(textures[txt_logo].height)) * board.logo.height
    board.logo.x = active_x + ((active_width * 0.5) - (board.logo.width * 0.5))
    board.logo.y = board.title.y + board.padding

    // -------

    board.rules = { active_x + (board.padding * 4), active_y + (board.padding * 2), active_width - (board.padding * 8), active_height - (board.padding * 4)}
    c_button_size := rl.MeasureTextEx(button_font, board.continue_button_text, board.button_font_size, board.button_font_spacing)
    board.continue_button.width = c_button_size.x + (4 * board.button_padding)
    board.continue_button.height = c_button_size.y + (2 * board.button_padding)
    board.continue_button.x = active_x + ((active_width * 0.5) - (board.start_button.width * 0.5))
    board.continue_button.y = board.rules.y + board.rules.height - board.padding- board.continue_button.height

    board.instructions_disp = { board.rules.x + (2 * board.padding), board.rules.y + board.padding, board.rules.width - (4 * board.padding), board.rules.height - board.continue_button.height - (3.5 * board.padding) }

    // -------

    board.ending = { active_x + (board.padding * 4), active_y + (board.padding * 4), active_width - (board.padding * 8), active_height - (board.padding * 8)}

    ee_button_size := rl.MeasureTextEx(button_font, board.ending_exit_button_text, board.button_font_size, board.button_font_spacing)
    board.ending_exit_button.width = ee_button_size.x + (4 * board.button_padding)
    board.ending_exit_button.height = ee_button_size.y + (2 * board.button_padding)

    er_button_size := rl.MeasureTextEx(button_font, board.ending_restart_button_text, board.button_font_size, board.button_font_spacing)
    board.ending_restart_button.width = er_button_size.x + (4 * board.button_padding)
    board.ending_restart_button.height = er_button_size.y + (2 * board.button_padding)

    eb1_w:f32 = board.ending_exit_button.width + board.ending_restart_button.width + board.padding
    eb1_x:f32 = (active_width * 0.5) - (eb1_w * 0.5)

    board.ending_exit_button.x = b1_x
    board.ending_exit_button.y = board.ending.y + board.ending.height - board.button_font_size - board.ending_exit_button.height

    board.ending_restart_button.x = b1_x + board.ending_exit_button.width + board.padding
    board.ending_restart_button.y = board.ending_exit_button.y

    // -------

    board.dealer_board.x = cx
    board.dealer_board.y = cy
    board.dealer_board.width = active_width * 0.3
    board.dealer_board.height = active_width * 0.04

    board.dealer_info.x = board.dealer_board.x + board.card_padding
    board.dealer_info.y = board.dealer_board.y + board.card_padding
    board.dealer_info.height = board.dealer_board.height - (2 * board.card_padding)
    board.dealer_info.width = board.dealer_board.width - (2 * board.card_padding)

    cy += board.dealer_board.height + board.card_padding

    board.targets.x = cx
    board.targets.y = cy
    board.targets.height = (3 * board.card_padding) + (2 * board.card_dh)

    board.suit_target.x = active_x + cx
    board.suit_target.y = cy
    board.suit_target.width = (8 * board.card_padding) + (3 * board.card_dw)
    board.suit_target.height = (3 * board.card_padding) + (2 * board.card_dh)
    board.suit_target_top.x = board.suit_target.x + (4 * board.card_padding)
    board.suit_target_top.y = board.suit_target.y + board.card_padding
    board.suit_target_bottom.x = board.suit_target_top.x
    board.suit_target_bottom.y = board.suit_target_top.y + board.card_dh + board.card_padding

    board.spell_target.x = board.suit_target.x + board.suit_target.width + board.padding
    board.spell_target.y = board.suit_target.y
    board.spell_target.width = board.suit_target.width
    board.spell_target.height = board.suit_target.height
    board.spell_target_top.x = board.spell_target.x + (4 * board.card_padding)
    board.spell_target_top.y = board.spell_target.y + board.card_padding
    board.spell_target_bottom.x = board.spell_target_top.x
    board.spell_target_bottom.y = board.spell_target_top.y + board.card_dh + board.card_padding

    board.targets.width = board.suit_target.width + board.spell_target.width + board.card_padding

    board.player_hand.width = (5 * board.card_dw) + (8 * board.card_padding)
    board.player_hand.height = board.card_dh + (4 * board.card_padding)

    if board.player_hand.width < board.targets.width {
        board.player_hand.x = board.targets.x + ((board.targets.width - board.player_hand.width) * 0.5)
    } else {
        board.player_hand.x = board.targets.x
    }
    board.player_hand.y = board.targets.y + board.targets.height + board.padding

    board.play_button_pos.y = board.player_hand.y + board.player_hand.height + board.padding
    board.play_button_pos.x = board.player_hand.x + (board.player_hand.width * 0.5)
    board.play_button_pos.width = active_width * 0.05
    board.play_button_pos.height = active_height * 0.02

    board.player_hand_start.x = board.player_hand.x + (2 * board.card_padding)
    board.player_hand_start.y = board.player_hand.y + (2 * board.card_padding) 

    board.player_map.x = board.targets.x + board.targets.width + (1.5 * board.padding)
    board.player_map.width = active_width - board.player_map.x - board.padding
    board.player_map.height = board.player_map.width
    board.player_map.y = board.targets.y

    board.island_info.x = board.player_map.x + (board.player_map.width * 0.5)
    board.island_info.y = board.player_map.y + (board.player_map.height * 0.08)

    board.island_log.x = board.player_map.x
    board.island_log.y = board.player_map.y + board.player_map.height + board.card_padding
    board.island_log.width = board.player_map.width

    log_font_size:f32 = board.island_log_font_size
    log_line_pad:f32 = board.island_log_line_padding
    log_line_h:f32 = log_font_size + log_line_pad
    log_padding:f32 = board.island_log_font_size * 0.5

    max_log_h:f32 = active_height - board.island_log.y - board.padding
    board.island_log.height = 3 * log_line_h
    for board.island_log.height + log_line_h < max_log_h {
        board.island_log.height += log_line_h
    }

    board.player_info.x = board.island_log.x
    board.player_info.width = board.island_log.width
    board.player_info.y = board.player_map.y - board.card_padding
    board.player_info.height = 0 
}
