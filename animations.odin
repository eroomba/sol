package sol

import "core:fmt"
import utf8 "core:unicode/utf8"
import vmem "core:mem/virtual"
import "core:math"
import "core:strings"
import "core:strconv"
import "core:math/rand"
import rl "vendor:raylib"

A_LEN_CARD_PLAY:int : 26
A_LEN_CARD_DEAL:int : 30
A_LEN_CARD_DISCARD:int : 14
A_LEN_CARD_FLIP:int : 30
A_LEN_TALLY_DISP:int : 180
A_LEN_SUIT_PLAY:int : 120
A_LEN_SPELL_PLAY:int : 120

Animation_Type :: enum {
    Basic,
    Card,
    Icon,
    Score
}

Animation_Step :: struct {
    pos:rl.Vector2,
    scale:rl.Vector2,
    rotation:f32,
    opacity:f32
}

Animation_Status :: enum {
    Running,
    Paused,
    Ended
}

Animation :: struct {
    type:Animation_Type,
    status:Animation_Status,
    start:int,
    end_step:Animation_Step,
    params:[10]f32,
    str_param:string,
    steps:[dynamic]Animation_Step
}

an_arena : vmem.Arena
anim_alloc := vmem.arena_allocator(&an_arena)

animations := make([dynamic]Animation, allocator = anim_alloc)
ac_index:int = 0

init_animations :: proc() {
  
}

clear_animations :: proc() {
    for a in 0..<len(animations) {
        delete(animations[a].str_param, allocator = anim_alloc)
        delete(animations[a].steps)
    }
    delete(animations)

    animations = make([dynamic]Animation)
}

end_animations :: proc() {
    free_all(anim_alloc)
    vmem.arena_destroy(&an_arena)
}

an_run_animations :: proc() {
    for a in 0..<len(animations) {
        an_draw_animation(a)
    }

    for a := len(animations) - 1; a >= 0; a -= 1 {
        if animations[a].status == .Ended {
            delete (animations[a].str_param, allocator = anim_alloc)
            delete(animations[a].steps)
            ordered_remove(&animations, a)
        }
    }
}

an_draw_animation :: proc(a:int) {
    switch animations[a].type {
        case .Basic:

        case .Card:
            if game_state == .Running {
                c_idx:int = int(animations[a].params[0])
                if step >= animations[a].start { 
                    if len(animations[a].steps) == 0 {
                        n_x:f32 = animations[a].end_step.pos.x
                        n_y:f32 = animations[a].end_step.pos.y
                        n_w:f32 = board.card_dw * animations[a].end_step.scale.x
                        n_h:f32 = board.card_dh * animations[a].end_step.scale.y
                        animations[a].status = .Ended
                        deck[c_idx].display = { n_x, n_y, animations[a].end_step.scale.x, animations[a].end_step.scale.y }
                        deck[c_idx].hit = { n_x - (n_w * 0.5), n_y - (n_h * 0.5), n_w, n_h }
                        deck[c_idx].rotation = animations[a].end_step.rotation
                        deck[c_idx].opacity = animations[a].end_step.opacity
                        deck[c_idx].status -= { .Animating }
                    } else {
                        curr_step := pop(&animations[a].steps)
                        deck[c_idx].display = { curr_step.pos.x, curr_step.pos.y, curr_step.scale.x, curr_step.scale.y }
                        deck[c_idx].rotation = curr_step.rotation
                        deck[c_idx].opacity = curr_step.opacity
                        if animations[a].params[1] == 100.100 && len(animations[a].steps) == int(animations[a].params[2]) && .Flipped in deck[c_idx].status {
                            deck[c_idx].status -= { .Flipped }
                        }
                    }
                }
            }

        case .Icon:
            
        case .Score:
            if game_state == .Running {
                if step >= animations[a].start {
                    if len(animations[a].steps) == 0 {
                        rem_idx:int = int(animations[a].params[0])
                        animations[a].status = .Ended
                    } else {
                        ch_idx:int = int(animations[a].params[0])
                        center:bool = animations[a].params[5] == 1 ? true : false
                        curr_step := pop(&animations[a].steps)
                        sc_font_size:f32 = animations[a].params[4]
                        d_str := strings.clone_to_cstring(animations[a].str_param, allocator = anim_alloc)
                        defer delete(d_str, allocator = anim_alloc)
                        scr_color:rl.Color = { u8(animations[a].params[1]), u8(animations[a].params[2]), u8(animations[a].params[3]), u8(255 * curr_step.opacity) }
                        r_color:rl.Color = { 10, 10, 10, u8(255 * curr_step.opacity) }

                        tx_x:f32 = curr_step.pos.x
                        tx_y:f32 = curr_step.pos.y 

                        if animations[a].params[1] == 1 {
                            r_p:f32 = sc_font_size * 0.2
                            r_x:f32 = curr_step.pos.x
                            r_y:f32 = curr_step.pos.y - r_p
                            r_size := rl.MeasureTextEx(font,d_str, sc_font_size, 0)
                            if center == true {
                                r_x -= r_size.x * 0.5
                                tx_x -= r_size.x * 0.5
                                r_y -= r_size.y * 0.5
                                tx_y -= r_size.y * 0.5
                            }
                            r_w:f32 = r_size.x + (2 * r_p)
                            r_h:f32 = r_size.y + (2 * r_p)
                            rl.DrawRectangleRounded({ r_x, r_y, r_w, r_h }, 0.1, 3, r_color)
                            rl.DrawRectangleRec({ r_x, r_y, r_w * 0.25, r_h }, r_color)
                            rl.DrawTriangle({ r_x, r_y }, { board.player_info.x + board.player_info.width - r_p, r_y + (r_h * 0.5) }, { r_x, r_y + r_h }, r_color)
                        } else {
                            r_p:f32 = sc_font_size * 0.2
                            r_x:f32 = curr_step.pos.x - (r_p * 2)
                            r_y:f32 = curr_step.pos.y - r_p
                            r_size := rl.MeasureTextEx(font,d_str, sc_font_size, 0)
                            if center == true {
                                r_x -= r_size.x * 0.5
                                tx_x -= r_size.x * 0.5
                                r_y -= r_size.y * 0.5
                                tx_y -= r_size.y * 0.5
                            }
                            r_w:f32 = r_size.x + (4 * r_p)
                            r_h:f32 = r_size.y + (2 * r_p)
                            if math.abs(r_w - board.card_dw) < 5 {
                                r_w += board.card_dw * 0.2
                                r_x -= board.card_dw * 0.1
                            }
                            rl.DrawRectangleRounded({ r_x, r_y, r_w, r_h }, 0.1, 3, r_color)
                        }
                        rl.DrawTextEx(font, d_str, { tx_x, tx_y }, animations[a].params[4], 0, scr_color)
                    }
                }
            }
    }
}

an_move_card :: proc(c_idx:int, start_pos:rl.Vector2, end_pos:rl.Vector2, length:int, offset:int = 0) {
 
    s_x:f32 = start_pos.x
    s_y:f32 = start_pos.y
    e_x:f32 = end_pos.x
    e_y:f32 = end_pos.y
    diff_x:f32 = e_x - s_x
    diff_y:f32 = e_y - s_y
    m_steps:int = length
    key_1:int = int(math.floor(f32(length) * 0.5)) - 1
    key_2:int = int(math.ceil(f32(length) * 0.5)) + 1

    deck[c_idx].hit = { -1, -1, 0, 0 }

    append(&animations, Animation{
        type = .Card,
        status = .Running,
        start = step + offset,
        end_step = Animation_Step{
            pos = rl.Vector2{ e_x, e_y },
            scale = rl.Vector2{ 1, 1 },
            rotation = 0,
            opacity = 1
        },
        params = [10]f32{
            f32(c_idx),
            0, 0, 0, 0, 0, 0, 0, 0, 0
        },
        str_param = strings.clone("", allocator = anim_alloc),
        steps = make([dynamic]Animation_Step, allocator = anim_alloc)
    })
    a_idx := len(animations) - 1

    dist:f32 = math.hypot_f32(diff_x, diff_y)
    ang:f32 = math.atan2(diff_y, diff_x)
    s_change:f32 = dist / f32(m_steps)

    d_x:f32 = s_change * math.cos(ang)
    d_y:f32 = s_change * math.sin(ang)

    mv_x:f32 = s_x
    mv_y:f32 = s_y
    sc_x:f32 = 1
    sc_y:f32 = 1

    for st in 0..<m_steps {
        mv_x += d_x
        mv_y += d_y
        if st < key_1 {
            sc_x += 0.025
            sc_y += 0.025
        } else if st >= key_2 {
            sc_x -= 0.025
            sc_y -= 0.025
            if sc_x < 1 {
                sc_x = 0
            }
            if sc_y < 1 {
                sc_y = 1
            }
        }
        inject_at(&animations[a_idx].steps, 0, Animation_Step{
            pos = rl.Vector2{ mv_x, mv_y },
            scale = rl.Vector2{ sc_x, sc_y },
            rotation = 0,
            opacity = 1
        })
    }

    if !(.Animating in deck[c_idx].status) {
        deck[c_idx].status += { .Animating }
    }

}

an_flip_card :: proc(c_idx:int, offset:int = 0) {
 
    m_steps:int = A_LEN_CARD_FLIP
    key_1:int = int(f32(m_steps) * 0.5)

    c_x:f32 = deck[c_idx].display.x
    c_y:f32 = deck[c_idx].display.y

    deck[c_idx].hit = { -1, -1, 0, 0 }

    append(&animations, Animation{
        type = .Card,
        status = .Running,
        start = step + offset,
        end_step = Animation_Step{
            pos = rl.Vector2{ c_x, c_y },
            scale = rl.Vector2{ 1, 1 },
            rotation = 0,
            opacity = 1
        },
        params = [10]f32{
            f32(c_idx),
            100.100,
            f32(key_1), 
            0, 0, 0, 0, 0, 0, 0
        },
        str_param = strings.clone("", allocator = anim_alloc),
        steps = make([dynamic]Animation_Step, allocator = anim_alloc)
    })
    a_idx := len(animations) - 1

    sc_x:f32 = 1
    sc_y:f32 = 1
    sc_f_change:f32 = 1 / (f32(m_steps) / 2)
    sc_change:f32 = 0.002

    for st in 0..<m_steps {
        if st <= key_1 {
            sc_x -= sc_f_change
            sc_y += sc_change
        } else {
            sc_x += sc_f_change
            sc_y -= sc_change
            if sc_y < 1 {
                sc_y = 1
            }
        }
        inject_at(&animations[a_idx].steps, 0, Animation_Step{
            pos = rl.Vector2{ c_x, c_y },
            scale = rl.Vector2{ sc_x, sc_y },
            rotation = 0,
            opacity = 1
        })
    }

    if !(.Animating in deck[c_idx].status) {
        deck[c_idx].status += { .Animating }
    }

}

an_discard_card :: proc(c_idx:int, offset:int) {
    m_steps:int = A_LEN_CARD_DISCARD

    c_x:f32 = deck[c_idx].display.x
    c_y:f32 = deck[c_idx].display.y

    deck[c_idx].hit = { -1, -1, 0, 0 }

    append(&animations, Animation{
        type = .Card,
        status = .Running,
        start = step + offset,
        end_step = Animation_Step{
            pos = rl.Vector2{ -1, -1 },
            scale = rl.Vector2{ 0, 0 },
            rotation = 0,
            opacity = 1
        },
        params = [10]f32{
            f32(c_idx),
            0, 0, 0, 0, 0, 0, 0, 0, 0
        },
        str_param = strings.clone("", allocator = anim_alloc),
        steps = make([dynamic]Animation_Step, allocator = anim_alloc)
    })
    a_idx := len(animations) - 1

    c_op:f32 = 1
    op_change:f32 = 1 / f32(m_steps)

    for st in 0..<m_steps {
        c_op -= op_change
        if c_op < 0 {
            c_op = 0
        }
        inject_at(&animations[a_idx].steps, 0, Animation_Step{
            pos = rl.Vector2{ c_x, c_y },
            scale = rl.Vector2{ 1, 1 },
            rotation = 0,
            opacity = c_op
        })
    }

    inject_at(&animations[a_idx].steps, 0, Animation_Step{
        pos = rl.Vector2{ c_x, c_y },
        scale = rl.Vector2{ 1, 1 },
        rotation = 0,
        opacity = 0
    })

    if !(.Animating in deck[c_idx].status) {
        deck[c_idx].status += { .Animating }
    }

}

an_score_display :: proc(disp:string, pos:rl.Vector2, length:int, offset:int, font_size:f32, color:[3]u8, rise:bool, center:bool = false) {

    length1:int = int(f32(length) * 0.55)
    length2:int = int(f32(length) * 0.45)

    center_prams:f32 = center == true ? 1 : 0

    append(&animations, Animation{
        type = .Score,
        status = .Running,
        start = step + offset,
        end_step = Animation_Step{
            pos = rl.Vector2{ -1, -1 },
            scale = rl.Vector2{ 0, 0 },
            rotation = 0,
            opacity = 1
        },
        params = [10]f32{
            1,
            f32(color[0]), f32(color[1]), f32(color[2]), 
            font_size, 
            center_prams, 
            0, 0, 0, 0
        },
        str_param = strings.clone(disp, allocator = anim_alloc),
        steps = make([dynamic]Animation_Step, allocator = anim_alloc)
    })
    a_idx := len(animations) - 1

    c_x:f32 = pos.x
    c_y:f32 = pos.y
    c_op:f32 = 1

    for st in 0..<length1 {
        inject_at(&animations[a_idx].steps, 0, Animation_Step{
            pos = rl.Vector2{ c_x, c_y },
            scale = rl.Vector2{ 1, 1 },
            rotation = 0,
            opacity = c_op
        })
    }

    op_change:f32 = 1 / f32(length2)
    y_change:f32 = (board.info_font_size) / f32(length2)

    for st in 0..<length2 {
        inject_at(&animations[a_idx].steps, 0, Animation_Step{
            pos = rl.Vector2{ c_x, c_y },
            scale = rl.Vector2{ 1, 1 },
            rotation = 0,
            opacity = c_op
        })
        if rise {
            c_y -= y_change
        }
        c_op -= op_change
        if c_op < 0 {
            c_op = 0
        }
    }

}

an_play_display :: proc(disp:string, mode:Card_Mode, top_bottom:int, length:int, offset:int) {

    length1:int = int(f32(length) * 0.75)
    length2:int = int(f32(length) * 0.25)

    c_x:f32 = board.suit_target_top.x
    c_y:f32 = board.suit_target_top.y

    font_size:f32 = board.font_size * 1.25

    if mode == .Spell {
        c_x = board.spell_target_top.x
        c_y = board.spell_target_top.y
    }

    if top_bottom == 1 {
        c_x = board.suit_target_bottom.x
        c_y = board.suit_target_bottom.y

        if mode == .Spell {
            c_x = board.spell_target_bottom.x
            c_y = board.spell_target_bottom.y
        }
    }

    c_y += board.card_dh * 0.5
    if top_bottom == 1 {
        c_x += ((board.card_dw * f32(len(player.play.cards))) + (board.card_padding * (f32(len(player.play.cards) - 1)))) * 0.5
    } else {
        c_x += ((board.card_dw * f32(len(dealer.play.cards))) + (board.card_padding * (f32(len(dealer.play.cards) - 1)))) * 0.5
    }

    tmp_str := strings.clone_to_cstring(disp, allocator = anim_alloc)
    defer delete(tmp_str, allocator = anim_alloc)
    t_sz := rl.MeasureTextEx(font, tmp_str, font_size, 0)
    
    c_x -= t_sz.x * 0.5
    c_y -= t_sz.y * 0.5

    append(&animations, Animation{
        type = .Score,
        status = .Running,
        start = step + offset,
        end_step = Animation_Step{
            pos = rl.Vector2{ -1, -1 },
            scale = rl.Vector2{ 0, 0 },
            rotation = 0,
            opacity = 1
        },
        params = [10]f32{
            0,
            255, 255, 255, 
            font_size, 
            0, 0, 0, 0, 0
        },
        str_param = strings.clone(disp, allocator = anim_alloc),
        steps = make([dynamic]Animation_Step, allocator = anim_alloc)
    })
    a_idx := len(animations) - 1

    for st in 0..<length1 {
        inject_at(&animations[a_idx].steps, 0, Animation_Step{
            pos = rl.Vector2{ c_x, c_y },
            scale = rl.Vector2{ 1, 1 },
            rotation = 0,
            opacity = 1
        })
    }

    c_op:f32 = 1
    op_change:f32 = 1 / f32(length2)

    for st in 0..<length2 {
        inject_at(&animations[a_idx].steps, 0, Animation_Step{
            pos = rl.Vector2{ c_x, c_y },
            scale = rl.Vector2{ 1, 1 },
            rotation = 0,
            opacity = c_op
        })
        c_op -= op_change
        if c_op < 0 {
            c_op = 0
        }
    }

}