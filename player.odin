package sol

import "core:fmt"
import "core:math"
import "core:math/rand"

PLAYER_HAND_SIZE:int : 5
MAX_SCORE:int : 300
INIT_SCORE:int : 0

idSeed:int = 100

getID :: proc() -> int {
    idSeed += 1
    return idSeed
}

Player :: struct {
    id:int,
    name:string,
    score:int,
    hand_size:int,
    hand:[dynamic]int,
    play:Card_Play,
    last_roll:int
}

player := Player{
    id = getID(),
    name = "Player",
    score = INIT_SCORE,
    hand_size = PLAYER_HAND_SIZE,
    hand = make([dynamic]int),
    play = new_play(1,Card_Mode.Suit),
    last_roll = 0
}

dealer := Player{
    id = 0,
    name = "Deck",
    score = INIT_SCORE,
    hand_size = 1,
    hand = make([dynamic]int),
    play = new_play(-1,Card_Mode.Suit),
    last_roll = roll()
}

set_player_mode :: proc(mode:Card_Mode) {
    if (player.play.mode != mode) {
        player.play.mode = mode
    }
}