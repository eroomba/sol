package cards

import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

SCREEN_WIDTH:i32 : 1280
SCREEN_HEIGHT:i32 : 720
BOARD_WIDTH:f32 : 1280
BOARD_HEIGHT:f32 : 720
FRAME_RATE:i32 : 500
STEP_RATE:i32 : 96

active_width:f32 = f32(BOARD_WIDTH)
active_height:f32 = f32(BOARD_HEIGHT)

delta:f32 = 0
s_delta:f32 = 0

step:int = 0
step_delta:int = 0

main :: proc() {
    rl.SetTraceLogLevel(rl.TraceLogLevel.NONE)
	rl.SetConfigFlags({ .VSYNC_HINT })
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "cards")
	rl.SetTargetFPS(FRAME_RATE)
	defer rl.CloseWindow()

    init_graphics()
    defer end_graphics()

    for !rl.WindowShouldClose() {

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
		}
		step_delta = step - prev_step

        {
            rl.BeginDrawing()
            rl.ClearBackground(BG_COLOR)
    
            // draw game step	
            draw_step()
    
            rl.EndDrawing()
        }
    }
}