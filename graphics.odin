package sol

import "core:fmt"
import utf8 "core:unicode/utf8"
import vmem "core:mem/virtual"
import "core:math"
import "core:strings"
import "core:strconv"
import "core:math/rand"
import rl "vendor:raylib"


BG_COLOR:rl.Color : { 0, 0, 0, 255 }
CLEAR_COLOR:rl.Color : { 255, 255, 255, 0 }
CARD_WIDTH:f32 : 250
CARD_HEIGHT:f32 : 350

font:rl.Font
button_font:rl.Font
main_filter:rl.TextureFilter

textures := make([dynamic]rl.Texture2D)
images := make([dynamic]rl.Image)
card_textures := make([dynamic]rl.Texture2D)
instructions_texture:rl.Texture2D
text_textures := make([dynamic]rl.Texture2D)
back_idx:int = 0

g_arena : vmem.Arena
graph_alloc := vmem.arena_allocator(&g_arena)

img_dice:int = -1
img_card_layout:int = -1
img_spells:int = -1
img_i_log:int = -1
img_icons:int = -1

txt_logo:int = -1
txt_bg:int = -1
txt_dl_board:int = -1
txt_suit_label:int = -1
txt_spell_label:int = -1
txt_icons:int = -1
txt_map:int = -1
txt_i_log:int = -1
txt_map_count:int = -1

dealer_dice_rot:f32 = 0

src_card_width:f32 = 500
src_card_height:f32 = 700

load_images:bool = false

board_space_color:rl.Color = { 100, 100, 100, 120 }

button_colors := []rl.Color{
    { 100, 100, 200, 200 },
    { 80, 80, 180, 200 },
    { 100, 100, 100, 200 },
    { 100, 200, 100, 200 }
}

suit_colors := [6]rl.Color{
    { 0, 0, 0, 255 },
    { 212, 0, 0, 255 },         // Blood
    { 102, 0, 128, 255 },       // Banner
    { 212, 170, 0, 255 },       // Bones
    { 55, 113, 200, 255 },      // Fishheads
    { 68, 170, 0, 255 }         // Arrowheads
}

init_graphics :: proc() -> int {

    img_loader:[]u8
	data_size:i32

    ret_val:int = 0
    font = rl.LoadFont("./CharcuterieSerif.ttf")
    button_font = rl.LoadFont("./CharcuterieContrast.ttf")
    main_filter = rl.TextureFilter.BILINEAR

    append(&images, rl.LoadImage("./images/cards_layout.png"))
    img_card_layout = len(images) - 1

    append(&images, rl.LoadImage("./images/spells_layout.png"))
    img_spells = len(images) - 1

    c_img:rl.Image = rl.GenImageColor(i32(board.card_dw), i32(board.card_dh), { 255, 255, 255, 0})

    for i in 0..<len(deck) {

        rl.ImageClearBackground(&c_img, { 255, 255, 255, 0 })

        rl.ImageDraw(&c_img, images[img_card_layout], { 0, 0, src_card_width, src_card_height}, { 0, 0, board.card_dw, board.card_dh }, rl.WHITE)

        suit:int = deck[i].suit
        power:int = deck[i].power
        spell:int = deck[i].spell

        n_x:f32 = f32(power - 1) * src_card_width
        n_y:f32 = src_card_height * 2

        s_x:f32 = f32(suit - 1) * src_card_width
        s_y:f32 = src_card_height

        sp_x:f32 = f32(spell - 1) * src_card_width
        sp_y:f32 = 0

        rl.ImageDraw(&c_img, images[img_card_layout], { n_x, n_y, src_card_width, src_card_height}, { 0, 0, board.card_dw, board.card_dh }, suit_colors[suit])
        rl.ImageDraw(&c_img, images[img_card_layout], { s_x, s_y, src_card_width, src_card_height}, { 0, 0, board.card_dw, board.card_dh }, suit_colors[suit])
        rl.ImageDraw(&c_img, images[img_spells], { sp_x, sp_y, src_card_width, src_card_height}, { 0, 0, board.card_dw, board.card_dh }, rl.WHITE)

        append(&card_textures, rl.LoadTextureFromImage(c_img))
        rl.GenTextureMipmaps(&card_textures[i])
	    rl.SetTextureFilter(card_textures[i], main_filter)
    }

    ld_img:rl.Image

    append(&textures, rl.LoadTexture("./images/logo.png"))
    txt_logo = len(textures) - 1
    rl.GenTextureMipmaps(&textures[txt_logo])
	rl.SetTextureFilter(textures[txt_logo], main_filter)

    append(&textures, rl.LoadTexture("./images/maps/map001.png"))
    txt_map = len(textures) - 1
    rl.GenTextureMipmaps(&textures[txt_map])
	rl.SetTextureFilter(textures[txt_map], main_filter)

    append(&images, rl.LoadImage("./images/icons.png"))
    img_icons = len(images) - 1
    append(&textures, rl.LoadTextureFromImage(images[img_icons]))
    txt_icons = len(textures) - 1
    rl.GenTextureMipmaps(&textures[txt_icons])
	rl.SetTextureFilter(textures[txt_icons], main_filter)

    rl.ImageClearBackground(&c_img, { 255, 255, 255, 0 })
    rl.ImageDraw(&c_img, images[img_card_layout], { src_card_width, 0, src_card_width, src_card_height}, { 0, 0, board.card_dw, board.card_dh }, rl.WHITE)
    append(&card_textures, rl.LoadTextureFromImage(c_img))
    back_idx = len(card_textures) - 1
    rl.GenTextureMipmaps(&card_textures[back_idx])
	rl.SetTextureFilter(card_textures[back_idx], main_filter)

    append(&textures, rl.LoadTexture("./images/parchment.jpg"))
    txt_bg = len(textures) - 1
    rl.GenTextureMipmaps(&textures[txt_bg])
	rl.SetTextureFilter(textures[txt_bg], main_filter)

    rl.UnloadImage(c_img)
    c_img = rl.LoadImage("./images/target_labels.png")
    c_img2 := rl.ImageFromImage(c_img, {0, 0, f32(c_img.width) * 0.5, f32(c_img.height) })

    append(&textures, rl.LoadTextureFromImage(c_img2))
    txt_suit_label = len(textures) - 1
    rl.GenTextureMipmaps(&textures[txt_suit_label])
	rl.SetTextureFilter(textures[txt_suit_label], main_filter)
    
    rl.UnloadImage(c_img2)
    c_img2 = rl.ImageFromImage(c_img, {f32(c_img.width) * 0.5, 0, f32(c_img.width) * 0.5, f32(c_img.height) })

    append(&textures, rl.LoadTextureFromImage(c_img2))
    txt_spell_label = len(textures) - 1
    rl.GenTextureMipmaps(&textures[txt_spell_label])
	rl.SetTextureFilter(textures[txt_spell_label], main_filter)

    rl.UnloadImage(c_img2)
    rl.UnloadImage(c_img)

    tmp_i:rl.Image = rl.GenImageColor(1,1, { 255, 255, 255, 0 })
    append(&textures, rl.LoadTextureFromImage(tmp_i))
    txt_dl_board = len(textures) - 1
    rl.GenTextureMipmaps(&textures[txt_dl_board])
	rl.SetTextureFilter(textures[txt_dl_board], main_filter)

    append(&images, rl.ImageCopy(tmp_i))
    img_i_log = len(images) - 1

    append(&textures, rl.LoadTextureFromImage(tmp_i))
    txt_i_log = len(textures) - 1
    rl.GenTextureMipmaps(&textures[txt_i_log])
	rl.SetTextureFilter(textures[txt_i_log], main_filter)

    append(&textures, rl.LoadTextureFromImage(tmp_i))
    txt_map_count = len(textures) - 1
    rl.GenTextureMipmaps(&textures[txt_map_count])
	rl.SetTextureFilter(textures[txt_map_count], main_filter)

    rl.UnloadImage(tmp_i)

    append(&images, rl.LoadImage("./images/dice.png"))
    img_dice = len(images) - 1

    g_update_log()
    
    free_all(graph_alloc)

    init_animations()

    return ret_val
}

end_graphics :: proc() {

    end_animations()

    for i in 0..<len(images) {
        rl.UnloadImage(images[i])
    }
    delete(images)

    for i in 0..<len(textures) {
        rl.UnloadTexture(textures[i])
    }
    delete(textures)

    for i in 0..<len(card_textures) {
        rl.UnloadTexture(card_textures[i])
    }
    delete(card_textures)

    if instructions_built {
        rl.UnloadTexture(instructions_texture)
    }

    for len(text_textures) > 0 {
        rm_txt := pop(&text_textures)
        rl.UnloadTexture(rm_txt)
    }
    delete(text_textures)

    rl.UnloadFont(font)
    rl.UnloadFont(button_font)
	free_all(graph_alloc)
    vmem.arena_destroy(&g_arena)
}


g_draw_text :: proc(font:rl.Font, text:string, pos:rl.Vector2, font_size:f32, font_spacing:f32, color:rl.Color) {
    t_cstr:cstring = strings.clone_to_cstring(text, allocator = graph_alloc)

    t_size := rl.MeasureTextEx(font, t_cstr, font_size, font_spacing)
    t_img := rl.GenImageColor(i32(math.ceil(t_size.x)), i32(math.ceil(t_size.y)), { 255, 255, 255, 0 })
    rl.ImageDrawTextEx(&t_img, font, t_cstr, { 0, 0 }, font_size, font_spacing, color)
    append(&text_textures, rl.LoadTextureFromImage(t_img))
    t_idx:int = len(text_textures) - 1
    rl.UnloadImage(t_img)

    rl.GenTextureMipmaps(&textures[txt_icons])
	rl.SetTextureFilter(textures[txt_icons], main_filter)
    rl.DrawTexturePro(text_textures[t_idx], { 0, 0, f32(text_textures[t_idx].width), f32(text_textures[t_idx].height) }, { pos.x, pos.y, t_size.x, t_size.y }, { 0, 0 }, 0, rl.WHITE)

    delete(t_cstr, allocator = graph_alloc)
}

g_draw_game :: proc() {

    for len(text_textures) > 0 {
        rm_txt := pop(&text_textures)
        rl.UnloadTexture(rm_txt)
    }

    if game_state == .Title {
        g_draw_title()
    } else if game_state == .Rules {
        g_draw_rules()  
    } else if game_state == .Ended {
        g_draw_background()
        g_draw_ending()
    } else if game_state == .Running || game_state == .Modal {
        g_draw_background()
        g_draw_board()
        if game_state == .Modal {
            g_draw_modal()
        }
    }

    an_run_animations()

    g_draw_tooltips()

    g_draw_bars()

    free_all(graph_alloc)
}

g_draw_tooltips :: proc() {
    tt_f_size:f32 = board.font_size * 0.75

    for i in 0..<len(tool_tips) {
        if .Opened in tool_tips[i].status {
            fill_str := fmt.aprintf(tool_tips[i].text, allocator = graph_alloc)
            defer delete (fill_str, allocator = graph_alloc)
            rel_x:f32 = 0
            rel_y:f32 = 0
            rel_w:f32 = 0
            rel_h:f32 = 0
            switch tool_tips[i].id {
                case "ModePeople", "ModeWealth", "ModeScore":
                    fill_str = fmt.aprintf(tool_tips[i].text, game_mode_targets[int(game_mode)], allocator = graph_alloc)
                case "CardHover":
                    rel_x = deck[board.hover_card_idx].display.x
                    rel_y = deck[board.hover_card_idx].display.y
                    rel_w = deck[board.hover_card_idx].display.width
                    rel_h = deck[board.hover_card_idx].display.height
                    fill_str = fmt.aprintf(tool_tips[i].text, deck[board.hover_card_idx].power, suit_name(board.hover_card_idx), spell_name(board.hover_card_idx), allocator = graph_alloc)

            }
            tt_lines := wrap_lines(fill_str, -1, tt_f_size)
            tt_w:f32 = 0
            tt_h:f32 = tt_f_size
            tt_lh:f32 = tt_f_size 
            for j in 0..<len(tt_lines) {
                c_txt := strings.clone_to_cstring(tt_lines[j], allocator = graph_alloc)
                defer delete(c_txt, allocator = graph_alloc)
                sz := rl.MeasureTextEx(font, c_txt, tt_f_size, 0)
                if sz.x > tt_w {
                    tt_w = sz.x
                }
                tt_h += sz.y
                tt_lh = sz.y
            }
            tt_w += tt_f_size
            tt_x:f32 = tool_tips[i].pos.x
            tt_y:f32 = tool_tips[i].pos.y
            if .Follow in tool_tips[i].status {
                tt_x = mouse_pos.x + tool_tips[i].pos.x
                tt_y = mouse_pos.y + tool_tips[i].pos.y
            } else if .Relative in tool_tips[i].status {
                tt_x = rel_x + tool_tips[i].pos.x
                tt_y = rel_y + tool_tips[i].pos.y
                if tool_tips[i].id == "CardHover" {
                    tt_x -= tt_w * 0.5
                    tt_y = rel_y - (board.card_dh * 0.55)
                }
                tt_y -= tt_h
            }
            rl.DrawRectangleRounded({ tt_x, tt_y, tt_w, tt_h}, 0.1, 3, { 30, 30, 30, 220 })
            c_x:f32 = tt_x + (tt_f_size * 0.5)
            c_y:f32 = tt_y + (tt_f_size * 0.5)
            for j in 0..<len(tt_lines) {
                c_txt := strings.clone_to_cstring(tt_lines[j], allocator = graph_alloc)
                defer delete(c_txt, allocator = graph_alloc)
                sz := rl.MeasureTextEx(font, c_txt, tt_f_size, 0)
                cc_x:f32 = c_x
                if tool_tips[i].id == "CardHover" {
                    cc_x = tt_x + (tt_w * 0.5) - (sz.x * 0.5)
                }
                //rl.DrawTextEx(font, c_txt, { cc_x, c_y }, tt_f_size, 0, rl.WHITE)
                g_draw_text(font, tt_lines[j], { cc_x, c_y }, tt_f_size, 0, rl.WHITE)
                c_y += tt_lh
            }
        }
    }
}

g_draw_background :: proc() {
    rl.DrawTexturePro(textures[txt_bg], { 0, 0, f32(textures[txt_bg].width), f32(textures[txt_bg].height) }, { active_x, active_y, active_width, active_height }, { 0, 0 }, 0, rl.WHITE)
}

g_draw_bars :: proc() {
    if screen_height > active_height {
        b_h:f32 = (screen_height - active_height) * 0.5
        rl.DrawRectangleRec({ 0, 0, screen_width, b_h }, rl.BLACK)
        rl.DrawRectangleRec({ 0, active_y + active_height, screen_width, b_h }, rl.BLACK)
    }
}

g_draw_board :: proc() {

    if board.targets.width > board.dealer_board.width {
        board.dealer_board.x += (board.targets.width - board.dealer_board.width) * 0.5
    }

    dl_img:rl.Image = rl.GenImageColor(i32(board.dealer_board.width), i32(board.dealer_board.height), { 255, 255, 255, 0 })
    dl_img_w:f32 = (2 * board.card_padding)
    dl_img_h:f32 = board.dealer_board.height
    dl_img_x:f32 = board.card_padding
    dc_img:rl.Image

    board.dealer_info.x = board.dealer_board.x + board.card_padding
    board.dealer_info.y = board.dealer_board.y + board.card_padding
    board.dealer_info.height = board.dealer_board.height - (2 * board.card_padding)

    n_s:f32 = board.dealer_info.height
    n_off:f32 = 0

    if dealer.last_roll > 0 {
        dc_s:f32 = board.dealer_info.height
        dc_hs:f32 = dc_s * 0.5
        dc_off:f32 = 200 * f32(dealer.last_roll - 1)
        dc_rot:f32 = dealer_dice_rot
        dc_x:f32 = board.dealer_board.x + board.card_padding + dc_hs
        dc_y:f32 = board.dealer_board.y + board.card_padding + dc_hs
        dc_img = rl.ImageFromImage(images[img_dice], { dc_off, 0, 200, 200 })

        rl.ImageRotate(&dc_img, i32(dc_rot))
        r_w:f32 = f32(dc_img.width)
        r_h:f32 = f32(dc_img.height)
        r_rt:f32 = dc_s / 200
        n_s:f32 = r_w * r_rt
        n_off:f32 = (n_s - dc_s) * 0.5

        board.dealer_info.x += dc_s + board.card_padding
        board.dealer_info.width -= dc_s + board.card_padding
        
        rl.ImageDraw(&dl_img, dc_img, { 0, 0, f32(dc_img.width), f32(dc_img.height) }, { board.card_padding - n_off, board.card_padding - n_off, n_s, n_s }, rl.WHITE)
        rl.UnloadImage(dc_img)
        dl_img_w += n_s + board.card_padding
        dl_img_x += n_s + board.card_padding
    }

    dealer_str:cstring = "Deck did not roll"
    f_size:f32 = board.dealer_info.height * 0.75
    {
        if dealer.last_roll > 0 {

            roll_disp:int = dealer.last_roll > 3 ? dealer.last_roll - 3 : dealer.last_roll
            suit_disp:string = dealer.play.mode == .Spell ? "Spell" : "Suit"
            defer delete(suit_disp, allocator = graph_alloc)
            roll_str := fmt.aprintf("Deck rolled %d to %s", roll_disp, suit_disp, allocator = graph_alloc)
            defer delete(roll_str, allocator = graph_alloc)
            dealer_str = strings.clone_to_cstring(roll_str, allocator = graph_alloc) 
            defer delete(dealer_str, allocator = graph_alloc)

            txt_size := rl.MeasureTextEx(font, dealer_str, f_size, 0)
            f_y:f32 = (dl_img_h * 0.5) - (f_size * 0.5)
            rl.ImageDrawTextEx(&dl_img, font, dealer_str, { dl_img_x, f_y }, f_size, 0, rl.WHITE)
            dl_img_w += txt_size.x
            board.dealer_info.width = txt_size.x
        }
    }

    board.dealer_board.width = dl_img_w
    board.dealer_board.x = (board.targets.x + (board.targets.width * 0.5)) - (board.dealer_board.width * 0.5)

    rl.DrawRectangleRounded(board.dealer_board, 0.1, 3, board_space_color)

    rl.UnloadTexture(textures[txt_dl_board])
    textures[txt_dl_board] = rl.LoadTextureFromImage(dl_img)
    rl.UnloadImage(dl_img)
    rl.DrawTexturePro(textures[txt_dl_board], { 0, 0, dl_img_w, f32(textures[txt_dl_board].height) }, { board.dealer_board.x, board.dealer_board.y, dl_img_w, dl_img_h }, { 0, 0 }, 0, rl.WHITE)

    rl.DrawRectangleRounded(board.suit_target, 0.1, 3, board_space_color)
    rl.DrawRectangleRounded(board.spell_target, 0.1, 3, board_space_color)

    if player.play.mode == .Spell {
        rl.DrawRectangleRoundedLinesEx(board.spell_target, 0.1, 3, 4, { 255, 255, 255, 180 })
    } else {
        rl.DrawRectangleRoundedLinesEx(board.suit_target, 0.1, 3, 4, { 255, 255, 255, 180 })
    }

    lbl_xp:f32 = board.card_padding * 0.25
    lbl_yp:f32 = lbl_xp
    lbl_w:f32 = board.card_padding * 3
    lbl_h:f32 = (f32(textures[txt_suit_label].height) / f32(textures[txt_suit_label].width)) * lbl_w
    rl.DrawTexturePro(textures[txt_suit_label], { 0, 0, f32(textures[txt_suit_label].width), f32(textures[txt_suit_label].height) }, { board.suit_target.x + lbl_xp, board.suit_target.y + lbl_yp, lbl_w, lbl_h }, { 0, 0 }, 0, rl.WHITE)

    rl.DrawTexturePro(textures[txt_spell_label], { 0, 0, f32(textures[txt_spell_label].width), f32(textures[txt_spell_label].height) }, { board.spell_target.x + lbl_xp, board.spell_target.y + lbl_yp, lbl_w, lbl_h }, { 0, 0 }, 0, rl.WHITE)

    p_board_w:f32 = (2 * board.card_padding)

    for c in 0..<len(player.hand) {
        if player.hand[c] >= 0 {
            p_board_w += board.card_dw + board.card_padding
        }
    }
    board.player_hand.width = p_board_w + board.card_padding

    rl.DrawRectangleRounded(board.player_hand, 0.1, 3, board_space_color)

    c_x:f32 = board.player_hand_start.x
    c_y:f32 = board.player_hand_start.y

    for c in 0..<len(player.hand) {
        if player.hand[c] >= 0 {
            g_draw_card(player.hand[c])
            c_x += board.card_dw + board.card_padding      
        }
    }

    cp_x:f32 = board.suit_target_bottom.x
    cp_y:f32 = board.suit_target_bottom.y

    if player.play.mode == .Spell {
        cp_x = board.spell_target_bottom.x
        cp_y = board.spell_target_bottom.y
    }

    for c in 0..<len(player.play.cards) {
        if player.play.cards[c] >= 0 {
            g_draw_card(player.play.cards[c])
            cp_x += board.card_dw + board.card_padding      
        }
    }

    for c in 0..<len(deck) {
        if .Animating in deck[c].status && .Discarded in deck[c].status {
            g_draw_card(c)
        }
    }

    cd_x:f32 = board.suit_target_top.x
    cd_y:f32 = board.suit_target_top.y

    if dealer.play.mode == .Spell {
        cd_x = board.spell_target_top.x
        cd_y = board.spell_target_top.y
    }

    for c in 0..<len(dealer.play.cards) {
        g_draw_card(dealer.play.cards[c])
        cd_x += board.card_dw + board.card_padding  
    }

    p_button_f_size:f32 = board.button_font_size
    p_button_txt:cstring = strings.clone_to_cstring("PLAY", allocator = graph_alloc)
    if game_step == .Play {
        p_button_txt = "CONTINUE"
    }
    p_button_size := rl.MeasureTextEx(button_font, p_button_txt, p_button_f_size, board.button_font_spacing)
    pb_w:f32 = (p_button_size.x * 2) + (2 * board.button_padding)
    pb_h:f32 = p_button_size.y + (2 * board.button_padding)
    pb_x:f32 = board.play_button_pos.x - (pb_w * 0.5)
    pb_y:f32 = board.play_button_pos.y

    pbt_x:f32 = pb_x + (pb_w * 0.5) - (p_button_size.x * 0.5)
    pbt_y:f32 = pb_y + board.button_padding
    
    bc_idx:int = .Highlighted in board.play_button_status ? 1 : 0

    rl.DrawRectangleRounded({ pb_x, pb_y, pb_w, pb_h }, 0.3, 5, button_colors[bc_idx])
    //rl.DrawTextEx(button_font, p_button_txt, { pbt_x, pbt_y }, p_button_f_size, board.button_font_spacing, rl.WHITE)
    g_draw_text(button_font, string(p_button_txt), { pbt_x, pbt_y }, p_button_f_size, board.button_font_spacing, rl.WHITE)

    board.play_button = { pb_x, pb_y, pb_w, pb_h }

    m_rat:f32 = f32(board.player_map.width) / 1500

    rl.DrawTexturePro(textures[txt_map], { 0, 0, f32(textures[txt_map].width), f32(textures[txt_map].height) }, board.player_map, { 0, 0 }, 0, rl.WHITE)
    for a in 0..<4 {
        m_x:f32 = board.player_map.x
        m_y:f32 = board.player_map.y

        for eff in Area_Effects {
            if eff in island.areas[a] {
                e_int:int = int(eff) - 1
                src_x:f32 = f32(e_int * 100)
                src_y:f32 = 0
                src_w:f32 = 100
                src_h:f32 = 100

                t_x:f32 = m_x + (island.area_eff_coords[a][e_int].x * m_rat)
                t_y:f32 = m_y + (island.area_eff_coords[a][e_int].y * m_rat)
                t_s:f32 = board.player_map.width * 0.07

                rl.DrawTexturePro(textures[txt_icons], { src_x, src_y, src_w, src_h }, { t_x, t_y, t_s, t_s }, { t_s * 0.5, t_s * 0.5 }, 0, rl.WHITE)
            }
        }
    }

    map_click:cstring = "Right-click map for more info"
    map_click_fs:f32 = board.font_size * 0.8
    map_click_sz := rl.MeasureTextEx(font, map_click, map_click_fs, 0)
    map_click_x:f32 = board.player_map.x + (board.player_map.width * 0.97) - map_click_sz.x
    map_click_y:f32 = board.player_map.y + (board.player_map.height * 0.97) - map_click_sz.y
    //rl.DrawTextEx(font, map_click, { map_click_x, map_click_y }, map_click_fs, 0, rl.WHITE)
    g_draw_text(font, string(map_click), { map_click_x, map_click_y }, map_click_fs, 0, rl.WHITE)

    g_draw_map_tally()
    
    p_tally:string = fmt.aprintf("Hand %d/%d   Player tally: %d", game_hand, GAME_END_HAND, player.score, allocator = graph_alloc)
    defer delete(p_tally, allocator = graph_alloc)
    p_info_f_size:f32 = board.info_font_size
    p_info := strings.clone_to_cstring(p_tally, allocator = graph_alloc)
    defer delete(p_info, allocator = graph_alloc)
    p_info_size := rl.MeasureTextEx(font, p_info, p_info_f_size, 0)
    p_info_x:f32 = board.player_map.x + (board.player_map.width * 0.5) - (p_info_size.x * 0.5)
    p_info_y:f32 = (board.player_map.y - board.card_padding) - p_info_size.y - (board.card_padding * 0.5)

    board.player_info.x = p_info_x - board.card_padding
    board.player_info.y = p_info_y - (board.card_padding * 0.5)
    board.player_info.width = p_info_size.x + (2 * board.card_padding)
    board.player_info.height = p_info_size.y + board.card_padding

    rl.DrawRectangleRounded(board.player_info, 0.2, 3, board_space_color)    
    //rl.DrawTextEx(font, p_info, { p_info_x, p_info_y }, p_info_f_size, 0, rl.WHITE)
    g_draw_text(font, p_tally, { p_info_x, p_info_y }, p_info_f_size, 0, rl.WHITE)

    border_size:f32 = 4
    rl.DrawRectangleRounded({board.island_log.x - border_size, board.island_log.y - border_size, board.island_log.width + (2 * border_size), board.island_log.height + (2 * border_size) }, 0.2, 3, { 16, 16, 16, 100 })
    rl.DrawRectangleRounded(board.island_log, 0.2, 3, { 16, 16, 16, 255 })

    lg_f_size:f32 = board.island_log_font_size
    lg_ln_pad:f32 = board.island_log_line_padding
    lg_ln_h:f32 = lg_f_size + lg_ln_pad
    lg_pad:f32 = board.island_log_font_size * 0.5
    lg_disp_h := f32(textures[txt_i_log].height)
    lg_disp_w := f32(textures[txt_i_log].width)
    lg_disp_x:f32 = board.island_log.x + (board.island_log.width * 0.5) - (f32(textures[txt_i_log].width) * 0.5)
    lg_disp_y:f32 = board.island_log.y + lg_pad
    board.island_log_scroll.x = lg_ln_h

    lg_disp_crop_h:f32 = board.island_log.height - (2 * lg_pad)
    lg_disp_crop_y:f32 = 0
    draw_sb:bool = true
    if lg_disp_h < lg_disp_crop_h {
        lg_disp_crop_h = lg_disp_h
        lg_disp_crop_y = 0
        draw_sb = false
    } else {
        lg_disp_crop_h = math.floor(lg_disp_crop_h / lg_ln_h) * lg_ln_h

        scroll_h:f32 = board.island_log_scroll.y
        if scroll_h < 0 || scroll_h + lg_disp_crop_h >= lg_disp_h {
            lg_disp_crop_y = lg_disp_h - lg_disp_crop_h
            board.island_log_scroll.y = lg_disp_crop_y
        } else {
            lg_disp_crop_y = scroll_h
        }
    }

    rl.DrawTexturePro(textures[txt_i_log], { 0, lg_disp_crop_y, lg_disp_w, lg_disp_crop_h }, { lg_disp_x, lg_disp_y, lg_disp_w, lg_disp_crop_h }, { 0, 0 }, 0, rl.WHITE)
    //rl.DrawTexturePro(textures[txt_i_log], { 0, 0, lg_disp_w, lg_disp_h }, { active_x, active_y, lg_disp_w, lg_disp_h }, { 0, 0 }, 0, rl.WHITE)

    if draw_sb {
        sb_x:f32 = board.island_log.x + board.island_log.width - (lg_pad * 0.9)
        sb_y:f32 = lg_disp_y
        sb_w2:f32 = lg_pad * 0.35
        sb_w:f32 = sb_w2 * 2
        sb_h:f32 = lg_disp_crop_h
        sb_c:rl.Color = { board_space_color[0] - 20, board_space_color[1] - 20, board_space_color[2] - 20, board_space_color[3] - 50 }
        rl.DrawRectangleRounded({ sb_x, sb_y, sb_w, sb_h }, 1, 3, sb_c)

        sb_ball_rad:f32 = (sb_w2 * 1.2)

        sb_ball_h:f32 = sb_h - sb_w
        scr_percent:f32 = board.island_log_scroll.y / (lg_disp_h - lg_disp_crop_h)
        sb_ball_x:f32 = sb_x + sb_w2
        sb_ball_y:f32 = sb_y + sb_w2 + (sb_ball_h * scr_percent)
        sb_ball_c:rl.Color = { sb_c[0], sb_c[1], sb_c[2], board_space_color[3] + 20 }
        rl.DrawCircleV({ sb_ball_x, sb_ball_y }, sb_ball_rad, sb_ball_c)
    }
    
    rl.DrawTexturePro(textures[txt_icons], { 1300, 0, 100, 100 }, board.settings_button, { 0, 0 }, 0, { 255, 255, 255, 200 })

    if board.help_card_display >= 0 {
        g_draw_card_info()
    } else if board.help_map_display {
        g_draw_map_help()
    }
}

g_update_log :: proc() {
    lg_f_size:f32 = board.island_log_font_size
    lg_ln_pad:f32 = board.island_log_line_padding
    lg_pad:f32 = board.island_log_font_size * 0.5
    lg_ln_h:f32 = lg_f_size + lg_ln_pad

    lg_disp_w:f32 = board.island_log.width - (2.5 * lg_pad)
    lg_disp_h:f32 = board.island_log.height - (2 * lg_pad)

    lg_img_w:f32 = lg_disp_w
    lg_img_h:f32 = lg_ln_h
    lg_lines := make([dynamic]string)
    defer delete(lg_lines)
    for lg3 in 0..<len(game_log_data) {
        wr_lines := wrap_lines(game_log_data[lg3], lg_img_w, lg_f_size)
        for lg4 in 0..<len(wr_lines) {
            append(&lg_lines, wr_lines[lg4])
        }
    }

    lg_img_h = lg_ln_h * f32(len(lg_lines))

    rl.UnloadImage(images[img_i_log])
    images[img_i_log] = rl.GenImageColor(i32(lg_img_w), i32(lg_img_h), { 0, 0, 0, 0 })
    lg_txt_y:f32 = 0

    for lg in 0..<len(lg_lines) {
        if lg_lines[lg] == "---" {
            ln_h:f32 = lg_ln_h * 0.1
            ln_w:f32 = lg_disp_w - (lg_ln_pad * 4)
            ln_y:f32 = lg_ln_h * 0.45

            rl.ImageDrawRectangleRec(&images[img_i_log], { 0, lg_txt_y + ln_y, ln_w, ln_h}, { 80, 80, 80, 100 })

            lg_txt_y += lg_ln_h

        } else {

            lg_cstr := strings.clone_to_cstring(lg_lines[lg], allocator = graph_alloc)
            defer delete(lg_cstr, allocator = graph_alloc)
            lg_ln_size := rl.MeasureTextEx(font, lg_cstr, lg_f_size, 0)
            
            //rl.DrawTextEx(font, lg_cstr, { lg_x, lg_y }, lg_f_size, 0, rl.WHITE)
            rl.ImageDrawTextEx(&images[img_i_log], font, lg_cstr, { 0, lg_txt_y }, lg_f_size, 0, rl.WHITE)

            lg_txt_y += lg_ln_size.y + lg_ln_pad
        }
    } 

    rl.UnloadTexture(textures[txt_i_log])
    textures[txt_i_log] = rl.LoadTextureFromImage(images[img_i_log])
    rl.GenTextureMipmaps(&textures[txt_i_log])
	rl.SetTextureFilter(textures[txt_i_log], main_filter)
}

g_draw_modal :: proc() {
    if board.help_card_display >= 0 {
        g_draw_card_info()
    } else if board.help_map_display {
        g_draw_map_help()
    }
}

g_draw_card_info :: proc() {
    if board.help_card_display >= 0 {
        ci_pad:f32 = board.padding
        ci_cw:f32 = board.card_dw * 1.5
        ci_ch:f32 = board.card_dh * 1.5

        card_info:rl.Rectangle = { 0, 0, 0, 0 }
        card_info.width = (6 * ci_pad) + ci_cw
        card_info.height = (2 * ci_pad) + ci_ch

        card_disp:rl.Rectangle = { 0, 0, ci_cw, ci_ch }

        c_idx:int = board.help_card_display
        suit_info_s:string = fmt.aprintf("%d of %s", deck[c_idx].power, suit_name(c_idx), allocator = graph_alloc)
        defer delete(suit_info_s, allocator = graph_alloc)
        suit_info := strings.clone_to_cstring(suit_info_s, allocator = graph_alloc)
        defer delete(suit_info_s, allocator = graph_alloc)
        s_i_font_size:f32 = board.font_size * 1.5
        s_i_size := rl.MeasureTextEx(font, suit_info, s_i_font_size, 0)
        card_info.height += s_i_size.y + board.font_size

        spell_name := strings.clone_to_cstring(spell_name(c_idx), allocator = graph_alloc)
        defer delete(spell_name, allocator = graph_alloc)
        sp_i_size := rl.MeasureTextEx(font, spell_name, s_i_font_size, 0)
        card_info.height += sp_i_size.y
    
        ci_lh := rl.MeasureTextEx(font, "ABC", board.font_size, 0).y

        ci_txt_w:f32 = card_info.width - (2 * ci_pad)

        i_lines := wrap_lines(spell_info[deck[c_idx].spell], ci_txt_w, board.font_size)
        card_info.height += f32(len(i_lines)) * ci_lh

        card_info.x = active_x + (active_width * 0.5) - (card_info.width * 0.5)
        card_info.y = active_y + (active_height * 0.5) - (card_info.height * 0.5)

        card_disp.x = (card_info.x + (card_info.width * 0.5)) - (card_disp.width * 0.5)
        card_disp.y = card_info.y + ci_pad 

        ci_txt_x:f32 = card_info.x + ci_pad

        rl.DrawRectangleRec({ 0, 0, screen_width, screen_height}, { 20, 20, 20, 100 })

        rl.DrawRectangleRounded(card_info, 0.2, 3, { 0, 0, 0, 255 })
        rl.DrawTexturePro(card_textures[c_idx], { 0, 0, f32(card_textures[c_idx].width), f32(card_textures[c_idx].height) }, card_disp, { 0, 0 }, 0, rl.WHITE)

        ci_curr_y := card_disp.y + card_disp.height

        suit_info_x:f32 = (active_width * 0.5) - (s_i_size.x * 0.5)
        //rl.DrawTextEx(font, suit_info, { suit_info_x, ci_curr_y }, s_i_font_size, 0, suit_colors[deck[c_idx].suit])
        g_draw_text(font, suit_info_s, { suit_info_x, ci_curr_y }, s_i_font_size, 0, suit_colors[deck[c_idx].suit])

        ci_curr_y += s_i_size.y + board.font_size

        sp_info_x:f32 = ci_txt_x // (active_width * 0.5) - (sp_i_size.x * 0.5)
        //rl.DrawTextEx(font, spell_name, { sp_info_x, ci_curr_y }, s_i_font_size, 0, rl.WHITE)
        g_draw_text(font, string(spell_name), { sp_info_x, ci_curr_y }, s_i_font_size, 0, rl.WHITE)

        ci_curr_y += sp_i_size.y

        for i in 0..<len(i_lines) {
            i_line_c := strings.clone_to_cstring(i_lines[i], allocator = graph_alloc)
            defer delete(i_line_c, allocator = graph_alloc)
            //rl.DrawTextEx(font, i_line_c, { ci_txt_x, ci_curr_y }, board.font_size, 0, rl.WHITE)
            g_draw_text(font, i_lines[i], { ci_txt_x, ci_curr_y }, board.font_size, 0, rl.WHITE)
            ci_curr_y += ci_lh
        }

        board.modal = { card_info.x, card_info.y, card_info.width, card_info.height }
    }
}

g_draw_map_help :: proc() {
    if board.help_map_display {
        hlp_map:rl.Rectangle = { 0, 0, 0, 0 }
        
        hlp_pad:f32 = board.font_size
        icon_s:f32 = board.font_size * 2
        hlp_map.height = 3 * board.font_size
        hlp_map.width = 0
        hlp_txt_h:f32 = 0

        for i in 1..=10 {
            hlp_map.height += icon_s + hlp_pad
            ln_size := rl.MeasureTextEx(font, area_effect_desc[i], board.font_size, 0)
            hlp_txt_h = ln_size.y
            if ln_size.x > hlp_map.width {
                hlp_map.width = ln_size.x 
            }
        }

        hlp_map.width += 4 * board.font_size + hlp_pad + icon_s

        hlp_map.x = active_x + (active_width * 0.5) - (hlp_map.width * 0.5)
        hlp_map.y = active_y + (active_height * 0.5) - (hlp_map.height * 0.5)

        rl.DrawRectangleRec({ 0, 0, active_width, active_height}, { 20, 20, 20, 100 })

        rl.DrawRectangleRounded(hlp_map, 0.2, 3, { 0, 0, 0, 255 })

        c_y:f32 = hlp_map.y + (2 * board.font_size)
        c_x:f32 = hlp_map.x + (2 * board.font_size)

        for i in 1..=10 {
            rl.DrawTexturePro(textures[txt_icons], { f32((i - 1) * 100), 0, 100, 100 }, { c_x, c_y, icon_s, icon_s }, { 0, 0 }, 0, rl.WHITE)
            //rl.DrawTextEx(font, area_effect_desc[i], { c_x + icon_s + hlp_pad, c_y + ((icon_s - hlp_txt_h) * 0.5)}, board.font_size, 0, rl.WHITE)
            g_draw_text(font, string(area_effect_desc[i]), { c_x + icon_s + hlp_pad, c_y + ((icon_s - hlp_txt_h) * 0.5)}, board.font_size, 0, rl.WHITE)

            c_y += icon_s + hlp_pad
        }

    }
}

g_draw_map_tally :: proc(mode: = 0) {

    tally_size:rl.Rectangle = { board.player_map.x + (board.player_map.width * 0.7), board.player_map.y + (board.player_map.height * 0.07), 0, 0 }
    tally_f_size:f32 = board.player_map.height * 0.05

    if mode == 1 {
        tally_f_size = board.ending.height * 0.075

        tally_size = { 0, 0, 0, 0 }
        tally_size.height = tally_f_size
        tally_size.width = -1
        tally_size.x = (active_width * 0.5)
        tally_size.y = board.ending.y + (active_height * 0.04)
    }

    i_pop_c:rl.Color = { 255, 255, 255, 255 }
    i_food_c:rl.Color = { 255, 255, 255, 255 }
    i_money_c:rl.Color = { 255, 255, 255, 255 }

    i_pop_s:string = fmt.aprintf("%d", island.population, allocator = graph_alloc)
    defer delete(i_pop_s, allocator = graph_alloc)
    i_food_s:string = fmt.aprintf("%d", island.food, allocator = graph_alloc)
    defer delete(i_food_s, allocator = graph_alloc)
    i_money_s:string = fmt.aprintf("%d", island.money, allocator = graph_alloc)
    defer delete(i_money_s, allocator = graph_alloc)
    if game_mode == .People {
        i_pop_s = fmt.aprintf("%d/%d", island.population, game_mode_targets[int(game_mode)], allocator = graph_alloc)
        if island.population < game_mode_targets[int(game_mode)] {
            i_pop_c = { 200, 0, 0, 255 }
        } else if island.population > game_mode_targets[int(game_mode)] {
            i_pop_c = { 0, 200, 0, 255 }
        }
    } 

    if island.food < island.population {
        i_food_c = { 200, 0, 0, 255 }
    }

    if game_mode == .Wealth {
        i_money_s = fmt.aprintf("%d/%d", island.money, game_mode_targets[int(game_mode)], allocator = graph_alloc)
        if island.money < game_mode_targets[int(game_mode)] {
            i_money_c = { 200, 0, 0, 255 }
        } else if island.money> game_mode_targets[int(game_mode)] {
            i_money_c = { 0, 200, 0, 255 }
        }
    } 

    i_pop:cstring = strings.clone_to_cstring(i_pop_s, allocator = graph_alloc)
    defer delete(i_pop, allocator = graph_alloc)
    i_food:cstring = strings.clone_to_cstring(i_food_s, allocator = graph_alloc)
    defer delete(i_food, allocator = graph_alloc)
    i_money:cstring = strings.clone_to_cstring(i_money_s, allocator = graph_alloc)
    defer delete(i_money, allocator = graph_alloc)

    i_c_padding1:f32 = tally_f_size * 0.1
    i_c_padding3:f32 = tally_f_size * 0.6

    i_pop_w:f32 = rl.MeasureTextEx(font, i_pop, tally_f_size, 0).x
    i_food_w:f32 = rl.MeasureTextEx(font, i_food, tally_f_size, 0).x
    i_money_w:f32 = rl.MeasureTextEx(font, i_money, tally_f_size, 0).x

    map_count_padding:f32 = 2 * i_c_padding1
    map_count_w:f32 = tally_f_size + i_c_padding1 + i_pop_w + i_c_padding3
    map_count_w += tally_f_size + i_food_w + i_c_padding3
    map_count_w += tally_f_size + i_money_w + i_c_padding3
    map_count_h:f32 = tally_f_size

    map_count_img := rl.GenImageColor(i32(map_count_w), i32(map_count_h), { 255, 255, 255, 0 })

    map_count_cx:f32 = i_c_padding1
    rl.ImageDraw(&map_count_img, images[img_icons], { 1200, 0, 100, 100 }, { map_count_cx, 0, tally_f_size, tally_f_size }, rl.WHITE)
    if mode == 0 {
        board.player_map_stats[0].x = map_count_cx
        board.player_map_stats[0].y = tally_size.y
        board.player_map_stats[0].height = map_count_h
        board.player_map_stats[0].width = i_pop_w + tally_f_size + i_c_padding1
    }
    map_count_cx += tally_f_size + i_c_padding1
    rl.ImageDrawTextEx(&map_count_img, font, i_pop, { map_count_cx, 0 }, tally_f_size, 0, i_pop_c)
    map_count_cx += i_pop_w + i_c_padding3

    rl.ImageDraw(&map_count_img, images[img_icons], { 1100, 0, 100, 100 }, { map_count_cx, 0, tally_f_size, tally_f_size }, rl.WHITE)
    if mode == 0 { 
        board.player_map_stats[1].x = map_count_cx
        board.player_map_stats[1].y = tally_size.y
        board.player_map_stats[1].height = map_count_h
        board.player_map_stats[1].width = i_pop_w + tally_f_size + i_c_padding1
    }
    map_count_cx += tally_f_size
    rl.ImageDrawTextEx(&map_count_img, font, i_food, { map_count_cx, 0 }, tally_f_size, 0, i_food_c)
    map_count_cx += i_food_w + i_c_padding3

    rl.ImageDraw(&map_count_img, images[img_icons], { 1000, 0, 100, 100 }, { map_count_cx, tally_f_size * 0.1, tally_f_size * 0.8, tally_f_size * 0.8 }, rl.WHITE)
    if mode == 0 {
        board.player_map_stats[2].x = map_count_cx
        board.player_map_stats[2].y = tally_size.y
        board.player_map_stats[2].height = map_count_h
        board.player_map_stats[2].width = i_pop_w + tally_f_size + i_c_padding1
    }
    map_count_cx += tally_f_size * 0.8
    rl.ImageDrawTextEx(&map_count_img, font, i_money, { map_count_cx, 0 }, tally_f_size, 0, i_money_c)
    map_count_cx += i_money_w
 
    rl.UnloadTexture(textures[txt_map_count])
    textures[txt_map_count] = rl.LoadTextureFromImage(map_count_img)
    tally_size.height = map_count_h
    tally_size.x -= (map_count_w * 0.5) 
    tally_size.width = map_count_w
    rl.DrawTexturePro(textures[txt_map_count], { 0, 0, map_count_w, map_count_h }, tally_size, { 0, 0 }, 0, rl.WHITE)
    rl.UnloadImage(map_count_img)

    if mode == 0 {
        board.player_map_stats[0].x += tally_size.x
        board.player_map_stats[1].x += tally_size.x
        board.player_map_stats[2].x += tally_size.x
    }
}

g_draw_title :: proc() {
    //rl.DrawRectangleRounded(board.title, 0.1, 3, board_space_color)

    rl.DrawTexturePro(textures[txt_logo], { 0, 0, f32(textures[txt_logo].width), f32(textures[txt_logo].height) }, board.logo, { 0, 0 }, 0, rl.WHITE)

    bc_idx:int = .Highlighted in board.start_button_status ? 1 : 0
    rl.DrawRectangleRounded(board.start_button, 0.3, 6, button_colors[bc_idx])
    //rl.DrawTextEx(button_font, board.start_button_text, { board.start_button.x + (3 * board.button_padding), board.start_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)
    g_draw_text(button_font, string(board.start_button_text), { board.start_button.x + (3 * board.button_padding), board.start_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)

    bc_idx = .Highlighted in board.exit_button_status ? 1 : 0
    rl.DrawRectangleRounded(board.exit_button, 0.3, 6, button_colors[bc_idx])
    //rl.DrawTextEx(button_font, board.exit_button_text, { board.exit_button.x + (3 * board.button_padding), board.exit_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)
    g_draw_text(button_font, string(board.exit_button_text), { board.exit_button.x + (3 * board.button_padding), board.exit_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)

    bc_idx = .Highlighted in board.rules_button_status ? 1 : 0
    rl.DrawRectangleRounded(board.rules_button, 0.3, 3, button_colors[bc_idx])
    //rl.DrawTextEx(button_font, board.rules_button_text, { board.rules_button.x + (2 * board.button_padding), board.rules_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)
    g_draw_text(button_font, string(board.rules_button_text), { board.rules_button.x + (2 * board.button_padding), board.rules_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)

    bc_idx_m_1:int = .Active in board.mode_buttons_status[0] ? 3 : 2
    bc_idx_m_2:int = .Active in board.mode_buttons_status[1] ? 3 : 2
    bc_idx_m_3:int = .Active in board.mode_buttons_status[2] ? 3 : 2
    rl.DrawRectangleRounded(board.mode_buttons[0], 0.3, 6, button_colors[bc_idx_m_1])
    rl.DrawRectangleRounded(board.mode_buttons[1], 0.3, 6, button_colors[bc_idx_m_2])
    rl.DrawRectangleRounded(board.mode_buttons[2], 0.3, 6, button_colors[bc_idx_m_3])

    for i in 0..<3 {
        bmb_x:f32 = board.mode_buttons[i].x
        bmb_y:f32 = board.mode_buttons[i].y

        bmb_size1 := rl.MeasureTextEx(button_font, board.mode_buttons_text[i], board.button_font_size, board.button_font_spacing)
        bmb_t_h:f32 = bmb_size1.y

        bmb_x = board.mode_buttons[i].x + (board.mode_buttons[i].width * 0.5) - (bmb_size1.x * 0.5)

        bmb_y = board.mode_buttons[i].y + (board.mode_buttons[i].height * 0.5) - (bmb_t_h * 0.5)
        
        //rl.DrawTextEx(button_font, board.mode_buttons_text[i], { bmb_x, bmb_y }, board.button_font_size, board.button_font_spacing, rl.WHITE)
        g_draw_text(button_font, string(board.mode_buttons_text[i]), { bmb_x, bmb_y }, board.button_font_size, board.button_font_spacing, rl.WHITE)
    }

    bc_idx_m_1 = .Active in board.level_buttons_status[0] ? 3 : 2
    bc_idx_m_2 = .Active in board.level_buttons_status[1] ? 3 : 2
    bc_idx_m_3 = .Active in board.level_buttons_status[2] ? 3 : 2
    rl.DrawRectangleRounded(board.level_buttons[0], 0.3, 6, button_colors[bc_idx_m_1])
    rl.DrawRectangleRounded(board.level_buttons[1], 0.3, 6, button_colors[bc_idx_m_2])
    rl.DrawRectangleRounded(board.level_buttons[2], 0.3, 6, button_colors[bc_idx_m_3])

    for i in 0..<3 {
        bmb_x:f32 = board.level_buttons[i].x
        bmb_y:f32 = board.level_buttons[i].y

        bmb_size1 := rl.MeasureTextEx(button_font, board.level_buttons_text[i], board.button_font_size, board.button_font_spacing)
        bmb_t_h:f32 = bmb_size1.y

        bmb_x = board.level_buttons[i].x + (board.level_buttons[i].width * 0.5) - (bmb_size1.x * 0.5)

        bmb_y = board.level_buttons[i].y + (board.level_buttons[i].height * 0.5) - (bmb_t_h * 0.5)
        
        //rl.DrawTextEx(button_font, board.level_buttons_text[i], { bmb_x, bmb_y }, board.button_font_size, board.button_font_spacing, rl.WHITE)
        g_draw_text(button_font, string(board.level_buttons_text[i]), { bmb_x, bmb_y }, board.button_font_size, board.button_font_spacing, rl.WHITE)
    }
}

g_draw_rules :: proc() {
    rl.DrawRectangleRounded(board.rules, 0.1, 3, board_space_color)

    if !instructions_built {
        build_instructions(board.instructions_disp.width)
    }

    rl.DrawTexturePro(instructions_texture, { 0, instructions_scroll, board.instructions_disp.width, board.instructions_disp.height }, board.instructions_disp, { 0, 0 }, 0, rl.WHITE)

    scr_y:f32 = board.instructions_disp.y
    scr_x:f32 = board.instructions_disp.x + board.instructions_disp.width + (board.font_size)
    scr_w:f32 = board.font_size * 0.5
    scr_h:f32 = board.instructions_disp.height
    rl.DrawRectangleRec({scr_x, scr_y, scr_w, scr_h }, board_space_color + { 10, 10, 10, 0 })

    max_scroll:f32 = f32(instructions_texture.height) - board.instructions_disp.height
    if instructions_scroll_max == 0 {
        instructions_scroll_max = max_scroll
    }

    scr_pad:f32 = scr_w * 0.1

    scroll_pos_r:f32 = instructions_scroll / max_scroll
    scroll_pos:f32 = scroll_pos_r * (scr_h - scr_w - scr_pad)

    if scroll_pos >= max_scroll {
        instructions_scroll = max_scroll
        scroll_pos = max_scroll
    }

    rl.DrawRectangleRec({scr_x + scr_pad, scr_y + scroll_pos + scr_pad, scr_w - (2 * scr_pad), scr_w - (2 * scr_pad) }, { 40, 40, 40, 255 } ) 

    bc_idx:int = .Highlighted in board.continue_button_status ? 1 : 0
    rl.DrawRectangleRounded(board.continue_button, 0.3, 6, button_colors[bc_idx])
    //rl.DrawTextEx(button_font, board.continue_button_text, { board.continue_button.x + (2 * board.button_padding), board.continue_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)
    g_draw_text(button_font, string(board.continue_button_text), { board.continue_button.x + (2 * board.button_padding), board.continue_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)
}

g_draw_ending :: proc() {
    rl.DrawRectangleRounded(board.rules, 0.1, 3, board_space_color)

    g_draw_map_tally(1)

    win_txt1:cstring = strings.clone_to_cstring(ending_msg[0], allocator = graph_alloc)
    win_txt2:cstring = strings.clone_to_cstring(ending_msg[1], allocator = graph_alloc)
    defer delete(win_txt1, allocator = graph_alloc)
    defer delete(win_txt2, allocator = graph_alloc)

    win_txt1_f_s:f32 = board.button_font_size * 2
    win_txt2_f_s:f32 = board.button_font_size

    win_txt1_size := rl.MeasureTextEx(font, win_txt1, win_txt1_f_s, 0)
    win_txt2_size := rl.MeasureTextEx(font, win_txt2, win_txt2_f_s, 0)

    win_txt_h:f32 = win_txt1_size.y + win_txt2_size.y + board.padding
    
    win_txt1_y:f32 = (active_height * 0.5) - (win_txt_h * 0.5)
    win_txt2_y:f32 = win_txt1_y + win_txt1_size.y + board.padding

    win_txt1_x:f32 = (active_width * 0.5) - (win_txt1_size.x * 0.5)
    win_txt2_x:f32 = (active_width * 0.5) - (win_txt2_size.x * 0.5)

    //rl.DrawTextEx(font, win_txt1, { win_txt1_x, win_txt1_y}, win_txt1_f_s, 0, rl.WHITE)
    g_draw_text(font, ending_msg[0], { win_txt1_x, win_txt1_y}, win_txt1_f_s, 0, rl.WHITE)
    //rl.DrawTextEx(font, win_txt2, { win_txt2_x, win_txt2_y}, win_txt2_f_s, 0, rl.WHITE)
    g_draw_text(font, ending_msg[1], { win_txt2_x, win_txt2_y}, win_txt2_f_s, 0, rl.WHITE)


    bc_idx:int = .Highlighted in board.ending_exit_button_status ? 1 : 0
    rl.DrawRectangleRounded(board.ending_exit_button, 0.3, 6, button_colors[bc_idx])
    //rl.DrawTextEx(button_font, board.ending_exit_button_text, { board.ending_exit_button.x + (2 * board.button_padding), board.ending_exit_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)
    g_draw_text(button_font, string(board.ending_exit_button_text), { board.ending_exit_button.x + (2 * board.button_padding), board.ending_exit_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)

    bc_idx = .Highlighted in board.ending_restart_button_status ? 1 : 0
    rl.DrawRectangleRounded(board.ending_restart_button, 0.3, 6, button_colors[bc_idx])
    //rl.DrawTextEx(button_font, board.ending_restart_button_text, { board.ending_restart_button.x + (2 * board.button_padding), board.ending_restart_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)
    g_draw_text(button_font, string(board.ending_restart_button_text), { board.ending_restart_button.x + (2 * board.button_padding), board.ending_restart_button.y + board.button_padding }, board.button_font_size, board.button_font_spacing, rl.WHITE)

}

g_get_card_pos :: proc(mode:Card_Mode, num:int, player_deck:int) -> rl.Vector2 {
    cp_x:f32 = board.suit_target_bottom.x
    cp_y:f32 = board.suit_target_bottom.y

    if player_deck < 0 {
        cp_x = board.suit_target_top.x
        cp_y = board.suit_target_top.y
    }

    if mode == .Spell {
        cp_x = board.spell_target_bottom.x
        cp_y = board.spell_target_bottom.y

        if player_deck < 0 {
            cp_x = board.spell_target_top.x
            cp_y = board.spell_target_top.y 
        }
    }

    return rl.Vector2{ cp_x + (f32(num) * (board.card_dw + board.card_padding )), cp_y }
}

g_update_card_display :: proc(show_cards:bool = true) {
    d_pos := g_get_card_pos(dealer.play.mode, 0, -1)
    c_x := d_pos.x
    c_y := d_pos.y

    for c in 0..<len(dealer.play.cards) {
        if show_cards {
            deck[dealer.play.cards[c]].display = { c_x + (board.card_dw * 0.5), c_y + (board.card_dh * 0.5), 1, 1 }
            deck[dealer.play.cards[c]].hit = { -1, -1, 0, 0 }
            deck[dealer.play.cards[c]].rotation = 0
            deck[dealer.play.cards[c]].opacity = 1
        }
        c_x += board.card_dw + board.card_padding
    }

    h_pos := board.player_hand_start
    p_pos := g_get_card_pos(player.play.mode, 0, 1)
    h_cx:f32 = h_pos.x
    h_cy:f32 = h_pos.y
    p_cx:f32 = p_pos.x
    p_cy:f32 = p_pos.y

    for c in 0..<len(player.hand) {
        if .Played in deck[player.hand[c]].status {
            deck[player.hand[c]].display = { p_cx + (board.card_dw * 0.5), p_cy + (board.card_dh * 0.5), 1, 1 }
            deck[player.hand[c]].hit = { -1, -1, 0, 0 }
            deck[player.hand[c]].rotation = 0
            p_cx += board.card_dw + board.card_padding
        } else {
            if show_cards {
                if .Selected in deck[player.hand[c]].status {
                    h_cy -= board.card_padding
                }
                deck[player.hand[c]].display = { h_cx + (board.card_dw * 0.5), h_cy + (board.card_dh * 0.5), 1, 1 }
                deck[player.hand[c]].hit = { h_cx, h_cy, board.card_dw, board.card_dh }
                deck[player.hand[c]].rotation = 0
            }
            h_cx += board.card_dw + board.card_padding
        }
    }
}

g_draw_card :: proc(idx:int) {
    if idx >= 0 && idx < len(deck) {
        card_vis:bool = true
        if .Draw in deck[idx].status || (.Discarded in deck[idx].status && deck[idx].display.width == 0 && deck[idx].display.height == 0 ) {
            card_vis = false
        }

        if card_vis {
            src_w:f32 = f32(card_textures[idx].width)
            src_h:f32 = f32(card_textures[idx].height)
            left:f32 = deck[idx].display.x
            top:f32 = deck[idx].display.y
            width:f32 = board.card_dw * deck[idx].display.width
            height:f32 = board.card_dh * deck[idx].display.height
            rot:f32 = deck[idx].rotation
    
            c_idx:int = idx
    
            if .Flipped in deck[idx].status {
                c_idx = back_idx
            }

            deck[idx].hit = { left - (width * 0.5), top - (height * 0.5), width, height }

            crd_op:u8 = u8(deck[idx].opacity * 255)
            crd_color:rl.Color = { 255, 255, 255, crd_op }

            edge_hw:f32 = 2
            if width < 2 {
                rl.DrawRectangleRounded({ left - edge_hw, top - (height * 0.5), edge_hw * 2, height }, 0.3, 3, crd_color)
            } else if height < 2 {
                rl.DrawRectangleRounded({ left - (width * 0.5), top - edge_hw, width, edge_hw * 2 }, 0.3, 3, crd_color)
            } else {
                rl.DrawTexturePro(card_textures[c_idx], { 0, 0, src_w, src_h }, { left, top, width, height }, { width * 0.5, height * 0.5 }, rot, crd_color)
            }

            deck[idx].last_draw = step
        }
    }
}

wrap_lines :: proc(str:string, width:f32, font_size:f32) -> [dynamic]string {
    ret_val := make([dynamic]string)
    defer delete(ret_val)

    words := strings.split(str," ", allocator = graph_alloc)
    defer delete(words, allocator = graph_alloc)
    c_width:f32 = 0
    c_str:string = ""
    defer delete(c_str, allocator = graph_alloc)

    for i in 0..<len(words) {
        if words[i] == "<br>" {
            append(&ret_val, c_str)
            c_str = ""
        } else {
            n_str := strings.concatenate({c_str, words[i]}, allocator = graph_alloc)
            defer delete(n_str, allocator = graph_alloc)
            m_w:f32 = rl.MeasureTextEx(font, strings.clone_to_cstring(n_str, allocator = graph_alloc), font_size, 0).x
            if width < 0 {
                spc:string = len(c_str) > 0 ? " " : ""
                c_str = strings.concatenate({c_str, spc, words[i]}, allocator = graph_alloc)
            } else {
                if m_w > width {
                    append(&ret_val, c_str)
                    c_str = strings.concatenate({"", words[i]}, allocator = graph_alloc)
                } else {
                    spc:string = len(c_str) > 0 ? " " : ""
                    c_str = strings.concatenate({c_str, spc, words[i]}, allocator = graph_alloc)
                }
            }
        }
    }

    if len(c_str) > 0 {
        append(&ret_val, c_str)
    }

    return ret_val
}

