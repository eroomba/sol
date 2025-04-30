package sol

import "core:fmt"
import utf8 "core:unicode/utf8"
import vmem "core:mem/virtual"
import "core:math"
import "core:strings"
import "core:strconv"
import "core:math/rand"
import rl "vendor:raylib"

Animation_Type :: enum {
    Basic,
    Card,
    Icon
}

Animation_Step :: struct {
    pos:rl.Vector2,
    scale:rl.Vector2,
    rotation:f32
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
    steps:[dynamic]Animation_Step
}

animations := make([dynamic]Animation)
card_animations:int = 0
icon_animations:int = 0
animation_trigger_cards:bool = false
animation_trigger_icons:bool = false

init_animations :: proc() {

}

end_animations :: proc() {
    delete(animations)
}

an_run_animations :: proc() {
    c_card_animations:int = card_animations
    c_icon_animations:int = icon_animations

    for a in 0..<len(animations) {
        an_draw_animation(a)
    }

    for a := len(animations) - 1; a >= 0; a -= 1 {
        if animations[a].status == .Ended {
            delete(animations[a].steps)
            ordered_remove(&animations, a)
        }
    }

    if c_card_animations > 0 && card_animations == 0 {
        if prev_game_step == .Select {
            animation_trigger_cards = true
            run_game_step()
        }
    }
}

an_draw_animation :: proc(a:int) {
    switch animations[a].type {
        case .Basic:

        case .Card:
            c_idx:int = int(animations[a].params[0])
            if step >= animations[a].start { 
                if len(animations[a].steps) == 0 {
                    animations[a].status = .Ended
                    deck[c_idx].display = { animations[a].end_step.pos.x, animations[a].end_step.pos.y, animations[a].end_step.scale.x, animations[a].end_step.scale.y }
                    deck[c_idx].rotation = animations[a].end_step.rotation
                    deck[c_idx].status -= { .Animating }
                    card_animations -= 1
                } else {
                    curr_step := pop(&animations[a].steps)
                    deck[c_idx].display = { curr_step.pos.x, curr_step.pos.y, curr_step.scale.x, curr_step.scale.y }
                    deck[c_idx].rotation = curr_step.rotation
                    if animations[a].params[1] == 100.100 && len(animations[a].steps) == int(animations[a].params[2]) && .Flipped in deck[c_idx].status {
                        deck[c_idx].status -= { .Flipped }
                    }
                }
            }

        case .Icon:

            
    }
}

an_move_card :: proc(c_idx:int, start_pos:rl.Vector2, end_pos:rl.Vector2, offset:int = 0) {
 
    s_x:f32 = start_pos.x
    s_y:f32 = start_pos.y
    e_x:f32 = end_pos.x
    e_y:f32 = end_pos.y
    diff_x:f32 = e_x - s_x
    diff_y:f32 = e_y - s_y
    m_steps:int = 30
    key_1:int = 14
    key_2:int = 16

    append(&animations, Animation{
        type = .Card,
        status = .Running,
        start = step + offset,
        end_step = Animation_Step{
            pos = rl.Vector2{ e_x, e_y },
            scale = rl.Vector2{ 1, 1 },
            rotation = 0
        },
        params = [10]f32{
            f32(c_idx),
            0, 0, 0, 0, 0, 0, 0, 0, 0
        },
        steps = make([dynamic]Animation_Step)
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
            rotation = 0
        })
    }

    card_animations += 1
}

an_flip_card :: proc(c_idx:int, offset:int = 0) {
 
    m_steps:int = 30
    key_1:int = 15

    c_x:f32 = deck[c_idx].display.x
    c_y:f32 = deck[c_idx].display.y

    append(&animations, Animation{
        type = .Card,
        status = .Running,
        start = step + offset,
        end_step = Animation_Step{
            pos = rl.Vector2{ c_x, c_y },
            scale = rl.Vector2{ 1, 1 },
            rotation = 0
        },
        params = [10]f32{
            f32(c_idx),
            100.100,
            f32(key_1), 
            0, 0, 0, 0, 0, 0, 0
        },
        steps = make([dynamic]Animation_Step)
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
            rotation = 0
        })
    }

    card_animations += 1
}