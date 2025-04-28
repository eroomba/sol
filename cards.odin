package sol

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

/*
    Effects:
        Sickness p-
        Flood p--
        Fervor p+
        Fire f-
        Famine f--
        Rain f+
        Bandits m-
        Fortune m+
        War p--, f--, m--
        Peace p+, f+, m+

    Spells:
        Teleport : +10 population
        Transmogrify : +10 food
        Transmute : +10 money
        Storm : -Fire, +Flood
        Invigorate : -Sickness, +Fervor
        Growth : -Famine, +Rain
        Evaporate : -Flood, +Famine
        Luck : ~-Rain/~-Bandits, ~+Fortune/~+War
        Calm : -Fervor/~-War, +Bandits/~+Peace
        Cover : Double
*/

CARD_MAX_POWER:int : 10
CARD_MAX_SUIT:int : 5

DECK_SIZE:int : 50
PLAY_SIZE:int : 3

STAT_SWING:int : 8

SUIT_BLOOD:int : 1
SUIT_BANNER:int : 2
SUIT_BONES:int : 3
SUIT_FISHHEAD:int : 4
SUIT_ARROWHEAD:int : 5

Suit_Names := []string {
    "None",
    "Blood",
    "Banner",
    "Bones",
    "Fishhead",
    "Arrowhead"
}

Suit_Names_Plural := []string {
    "None",
    "Blood",
    "Banners",
    "Bones",
    "Fishheads",
    "Arrowheads"
}

Spell_Names := []string {
    "None",
    "Teleport",
    "Transmogrify",
    "Transmute",
    "Storm",
    "Invigorate",
    "Growth",
    "Evaporate",
    "Luck",
    "Calm",
    "Chaos"
}

spell_info := []string {
    "None",
    "When played by the player: Increase the population by the player's tally. <br> <br> When played by the deck: Decrease the population by the total of the played cards.",
    "When played by the player: Increase the food by the player's tally. <br> <br> When played by the deck: Decrease the food by the total of the played cards.",
    "When played by the player: Increase coin by the the player's tally. <br> <br> When played by the deck: Decrease coin by the total of the played cards.",
    "When played by the player: Put out a single Fire. If no Fire, chance to create a Flood. <br> <br>  When played by the deck: Chance to create a Flood.",
    "When played by the player: End a single Sickness. If no Sickness, chance to create a Fervor. <br> <br>  When played by the deck: Chance to create a Fervor.",
    "When played by the player: End a single Famine. If no Famine, chance to create Sickness. <br> <br>  When played by the deck: Chance to create Sickness.",
    "When played by the player: Dry a single Flood. If no Flooding, chance to create Famine. <br> <br>  When played by the deck:  Chance to create Famine.",
    "When played by the player: Expel a single group of Bandits or end a single instance of Rain. If no Bandits or Rain, chance to create Fortune or War. <br> <br>  When played by the deck:  Chance to create Fortune or War.",
    "When played by the player: End a single Fervor or War. If no Fervor or War, chance to bring Bandits or Peace. <br> <br>  When played by the deck:  Chance to bring Bandits or Peace.",
    "When played by the player: End a single Fortune or Peace. If no Fortune or Peace, chance to create Fire or Rain. <br> <br>  When played by the deck:  Chance to create Fire or Rain.",
}

spell_info_short := []cstring {
    "None",
    "Teleport - Increase the population by the player's tally.",
    "Transmogrify - Increase the food by the player's tally.",
    "Transmute - Increase coin by the the player's tally.",
    "Storm - Put out a single Fire. If no Fire, chance to create a Flood.",
    "Invigorate - End a single Sickness. If no Sickness, chance to create a Fervor.",
    "Growth - End a single Famine. If no Famine, chance to create Sickness.",
    "Evaporate - Dry a single Flood. If no Flooding, chance to create Famine.",
    "Luck - Expel a single group of Bandits or end a single instance of Rain. If no Bandits or Rain, chance to create Fortune or War.",
    "Calm - End a single Fervor or War. If no Fervor or War, chance to bring Bandits or Peace.",
    "Chaos - End a single Fortune or Peace. If no Fortune or Peace, chance to create Fire or Rain.",
}

Card_Mode :: enum {
    None,
    Suit,
    Spell
}

Card_Status :: enum {
    Draw,
    Hand,
    Discarded,
    Selected,
    Flipped,
    Played
}

Card :: struct {
    suit:int,
    power:int,
    spell:int,
    selected:bool,
    status:bit_set[Card_Status],
    owner:int,
    display:rl.Rectangle
}

Card_Play :: struct{
    cards:[dynamic]int,
    mode:Card_Mode,
    direction:int
}

dealer_dice:bool = true

deck:[DECK_SIZE]Card
draw := make([dynamic]int)

init_deck :: proc() {
    i:int = 0
    for s in 1..=CARD_MAX_SUIT {
        for p in 1..=CARD_MAX_POWER {
            deck[i] = Card{
                suit = s,
                power = p,
                spell = p,
                selected = false,
                status = { .Draw },
                owner = -1,
                display = { -1, -1, 0, 0 }
            }
            append(&draw,i)
            i += 1
        }
    }
    shuffle()
}

reset_deck :: proc() {
    clear(&draw)
    for i in 0..<len(deck) {
        deck[i].selected = false
        deck[i].owner = -1
        deck[i].status = { .Draw }
        deck[i].display = { -1, -1, 0, 0 }
        append(&draw, i)
    }
    shuffle()
}

shuffle :: proc() {
    count:f32 = f32(len(draw))
    for i in 0..<len(draw) {
        j:int = int(math.floor(rand.float32() * count))
        tmpI := draw[j]
        draw[j] = draw[i]
        draw[i] = tmpI
    }
}

restock :: proc() {
    if len(draw) <= 0 {
        clear(&draw)
        for i in 0..<len(deck) {
            if .Discarded in deck[i].status {
                append(&draw, i)
                deck[i].status = { .Draw }
                deck[i].owner = -1
                deck[i].selected = false
                deck[i].display = { -1, -1, 0, 0 }
            }
        }
    }
    shuffle()
}

draw_card :: proc() -> int {
    if len(draw) <= 0 {
        restock()
    }
    return pop(&draw)
}

discard :: proc(c_idx:int) {
    deck[c_idx].status = { .Discarded }
    deck[c_idx].owner = -1
    deck[c_idx].selected = false
    deck[c_idx].display = { -1, -1, 0, 0 }
}

new_play :: proc(direction:int, mode:Card_Mode) -> Card_Play {
    return Card_Play{
        cards = make([dynamic]int),
        mode = mode,
        direction = direction
    }
}

deal :: proc() {
    for i in 0..<PLAYER_HAND_SIZE {
        if len(player.hand) < PLAYER_HAND_SIZE {
            d_idx:int = draw_card()
            append(&player.hand, d_idx)
            deck[d_idx].status = { .Hand }
            deck[d_idx].owner = player.id
            deck[d_idx].selected = false
            deck[d_idx].display = { -1, -1, 0, 0 }
         }

         if len(dealer.play.cards) < dealer.hand_size {
            d_idx:int = draw_card()
            append(&dealer.play.cards, d_idx)
            deck[d_idx].status = { .Hand, .Flipped }
            deck[d_idx].owner = dealer.id
            deck[d_idx].selected = false
            deck[d_idx].display = { -1, -1, 0, 0 }
         }
    }
}

spell_name :: proc(c_idx:int) -> string {
    if c_idx < len(deck) {
        return Spell_Names[deck[c_idx].spell]
    }
    return "Unknown"
}

suit_name :: proc(c_idx:int, plural:bool = true) -> string {
    if c_idx < len(deck) {
        if plural {
            return Suit_Names_Plural[deck[c_idx].suit]
        } else {
            return Suit_Names[deck[c_idx].suit]
        }
    }
    return "Unknown"
}

score_play :: proc(play:^Card_Play) -> int {
	if play.mode == .Suit {

		score:int = 0
		high:int = 0
		mult:int = 1

		p_check:int = 0
		s_check:int = 0

		p_count:int = 1
		s_count:int = 1

		p_len:int = len(play.cards)

		if p_len > 0 {
			score = deck[play.cards[0]].power
			high = score
			p_check = score
			s_check = deck[play.cards[0]].suit 
		}

		for c in 1..<len(play.cards) {
			if deck[play.cards[c]].power > high {
				high = deck[play.cards[c]].power
			}
			score += deck[play.cards[c]].power
			if deck[play.cards[c]].power == p_check {
				p_count += 1
			}
			if deck[play.cards[c]].suit == s_check {
				s_count += 1
			}
		}

		if p_count == p_len && p_len > 1 {
			score *= p_len
		} else if s_count == p_len && p_len > 1 {
			score += high
		} else {
			score = high
		}

		return score
	}

	return 0
}

cast_play :: proc(play:^Card_Play, dir:int) {
	if play.mode == .Spell {
        sp_mult:int = 1
        delta_pop:int = 0
        delta_food:int = 0
        delta_money:int = 0

        score:int = 0
        for c in 0..<len(play.cards) {
            score += deck[play.cards[c]].power
        }

        chk_areas:[4]int = { 0, 1, 2, 3 }
        for a in 0..<4 {
            nx:int = int(math.floor(rand.float32() * 4))
            tmp:int = chk_areas[nx]
            chk_areas[nx] = chk_areas[a]
            chk_areas[a] = tmp
        }

        /*
            Spells:
                Teleport : +TALLY population/-SCORE popluation
                Transmogrify : +TALLY food/-SCORE food - X
                Transmute : +TALLY money/-SCORE money - X
                Storm : -Fire, +Flood; attack: 0.85 - X
                Invigorate : -Sickness, +Fervor; attack: 0.75
                Growth : -Famine, +Sickness; attack: 0.85
                Evaporate : -Flood, +Famine; attack: 0.85 - X
                Luck : ~-Rain/~-Bandits, ~+Fortune/~+War; attack (War): 0.9, attack (Fortune): 0.85
                Calm : -Fervor/~-War, +Bandits/~+Peace; attack (Bandits): 0.75, attack (Peace): 0.9
                Chaos : -Fortune/~-Peace, ~+Fire/~+Rain; attack (Fire):0.95, attack (Rain): 0.85


            Sickness    +Growth         -Invigorate
            Flood       +Storm          -Evaporate
            Fervor      +Invigorate     -Calm
            Fire        +Chaos          -Storm
            Famine      +Evaporate      -Growth
            Rain        +Chaos          -Luck
            Bandits     +Calm           -Luck
            Fortune     +Luck           -Chaos
            War         +Luck           -Calm
            Peace       +Calm           -Chaos

        */

        //for c in 0..<len(play.cards) {
        //    if deck[play.cards[c]].spell == 10 {
        //        sp_mult *= 2
        //    }
        //}

        play_name:string = "Your"
        if dir < 0 {
            play_name = "The deck's"
        }
        
        for c in 0..<len(play.cards) {
            switch deck[play.cards[c]].spell {
                case 1:
                    // Teleport : +score population
                    if dir < 0 {
                        d_pop := score * sp_mult
                        island.population -= d_pop
                        lg_line := fmt.aprintf("%s Teleport took %d people.", play_name, d_pop, allocator = log_alloc)
                        defer delete(lg_line, allocator = log_alloc)
                        game_log(lg_line)
                    } else {
                        d_pop := player.score * sp_mult
                        island.population += d_pop
                        lg_line := fmt.aprintf("%s Teleport brought %d people.", play_name, d_pop, allocator = log_alloc)
                        defer delete(lg_line, allocator = log_alloc)
                        game_log(lg_line)
                    }
                case 2:
                    // Transmogrify : +SCORE food
                    if dir < 0 {
                        d_food := score * sp_mult
                        island.food -= d_food
                        lg_line := fmt.aprintf("%s Transmogrify lost %d food.", play_name, d_food, allocator = log_alloc)
                        defer delete(lg_line, allocator = log_alloc)
                        game_log(lg_line)
                    } else {
                        d_food := player.score * sp_mult
                        island.food += d_food
                        lg_line := fmt.aprintf("%s Transmogrify created %d food.", play_name, d_food, allocator = log_alloc)
                        defer delete(lg_line, allocator = log_alloc)
                        game_log(lg_line)
                    }
                case 3:
                    // Transmute : +SCORE money
                    if dir < 0 {
                        d_money := score * sp_mult
                        island.money -= d_money
                        lg_line := fmt.aprintf("%s Transmute destroyed %d coin.", play_name, d_money, allocator = log_alloc)
                        defer delete(lg_line, allocator = log_alloc)
                        game_log(lg_line)
                    } else {
                        d_money := player.score * sp_mult
                        island.money += d_money
                        lg_line := fmt.aprintf("%s Transmute created %d coin.", play_name, d_money, allocator = log_alloc)
                        defer delete(lg_line, allocator = log_alloc)
                        game_log(lg_line)
                    }
                case 4:
                    // Storm : -Fire, +Flood; attack: 0.85
                    for j in 0..<sp_mult {
                        fixed:bool = false
                        a_idx:int = -1
                        if dir > 0 {
                            fixed, a_idx = island_fix(.Fire, chk_areas) 
                        }
                        if !fixed {
                            att, a_idx := island_attack(.Flood, chk_areas, 0.85)
                            if att {
                                lg_line := fmt.aprintf("%s Storm flooded the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            } else {
                                lg_line := fmt.aprintf("%s Storm failed.", play_name, allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        } else {
                            lg_line := fmt.aprintf("%s Storm put out the fire in the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                            defer delete(lg_line, allocator = log_alloc)
                            game_log(lg_line)
                        }
                    }
                case 5:
                    // Invigorate : -Sickness, +Fervor; attack: 0.75
                    for j in 0..<sp_mult {
                        fixed:bool = false
                        a_idx:int = -1
                        if dir > 0 {
                            fixed, a_idx = island_fix(.Sickness, chk_areas)
                        } 
                        if !fixed {
                            att, a_idx := island_attack(.Fervor, chk_areas, 0.75)
                            if att {
                                lg_line := fmt.aprintf("%s Invigorate created a Fervor in the %s", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                            game_log(lg_line)
                            } else {
                                lg_line := fmt.aprintf("%s Invigorate failed.", play_name, allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        } else {
                            lg_line := fmt.aprintf("%s Invigorate healed the Sickness in the %s", play_name, island_area_names[a_idx], allocator = log_alloc)
                            defer delete(lg_line, allocator = log_alloc)
                            game_log(lg_line)
                        }
                    }
                case 6:
                    // Growth : -Famine, +Sickness; attack: 0.85
                    for j in 0..<sp_mult {
                        fixed:bool = false
                        a_idx:int = -1
                        if dir > 0 {
                            fixed, a_idx = island_fix(.Famine, chk_areas)
                        } 
                        if !fixed {
                            att, a_idx := island_attack(.Sickness, chk_areas, 0.85)
                            if att {
                                lg_line := fmt.aprintf("%s Growth created Sickness in the %s", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            } else {
                                lg_line := fmt.aprintf("%s Growth failed.", play_name, allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        } else {
                            lg_line := fmt.aprintf("%s Growth ended the Famine in %s!", play_name, island_area_names[a_idx], allocator = log_alloc)
                            defer delete(lg_line, allocator = log_alloc)
                            game_log(lg_line)
                        }
                    }
                case 7:
                    // Evaporate : -Flood, +Famine; attack: 0.85
                    for j in 0..<sp_mult {
                        fixed:bool = false
                        a_idx:int = -1
                        if dir > 0 {
                            fixed, a_idx = island_fix(.Flood, chk_areas) 
                        }
                        if !fixed {
                            att, a_idx := island_attack(.Famine, chk_areas, 0.85)
                            if att {
                                lg_line := fmt.aprintf("%s Evaporate created Famine in the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            } else {
                                lg_line := fmt.aprintf("%s Evaporate failed.", play_name, allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        } else {
                            lg_line := fmt.aprintf("%s Evaporate dried the Flood in the %s", play_name, island_area_names[a_idx], allocator = log_alloc)
                            defer delete(lg_line, allocator = log_alloc)
                            game_log(lg_line)
                        }
                    }
                case 8:
                    // Luck : ~-Rain/~-Bandits, ~+Fortune/~+War; attack (War): 0.9, attack (Fortune): 0.85
                    for j in 0..<sp_mult {
                        if rand.float32() > 0.5 {
                            fixed:bool = false
                            a_idx:int = -1
                            if dir > 0 {
                                fixed, a_idx = island_fix(.Bandits, chk_areas)
                            }
                            if !fixed {
                                att, a_idx := island_attack(.War, chk_areas, 0.9)
                                if att {
                                    lg_line := fmt.aprintf("%s Luck began a War in the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                } else {
                                    lg_line := fmt.aprintf("%s Luck failed.", play_name, allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                }
                            } else {
                                lg_line := fmt.aprintf("%s Luck expelled the Bandits from the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        } else {
                            fixed:bool = false
                            a_idx:int = -1
                            if dir > 0 {
                                fixed, a_idx = island_fix(.Rain, chk_areas)
                            }
                            if !fixed {
                                att, a_idx := island_attack(.Fortune, chk_areas, 0.85)
                                if att {
                                    lg_line := fmt.aprintf("%s Luck brought Fortune to the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                } else {
                                    lg_line := fmt.aprintf("%s Luck failed.", play_name, allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                }
                            } else {
                                lg_line := fmt.aprintf("%s Luck ended the Rain in the %s", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        }
                    }
                case 9:
                    // Calm : -Fervor/~-War, +Bandits/~+Peace; attack (Bandits): 0.75, attack (Peace): 0.9
                    for j in 0..<sp_mult {
                        if rand.float32() > 0.5 {
                            fixed:bool = false
                            a_idx:int = -1
                            if dir > 0 {
                                fixed, a_idx = island_fix(.Fervor, chk_areas)
                            }
                            if !fixed {
                                att, a_idx := island_attack(.Bandits, chk_areas, 0.75)
                                if att {
                                    lg_line := fmt.aprintf("%s Calm allowed Bandits to arrive in the %s", play_name, island_area_names[a_idx], allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                } else {
                                    lg_line := fmt.aprintf("%s Calm failed.", play_name, allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                }
                            } else {
                                lg_line := fmt.aprintf("%s Calm ended the Fervor in the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        } else {
                            fixed:bool = false
                            a_idx:int = -1
                            if dir > 0 {
                                fixed, a_idx = island_fix(.War, chk_areas)
                            }
                            if !fixed {
                                att, a_idx := island_attack(.Peace, chk_areas, 0.9)
                                if att {
                                    lg_line := fmt.aprintf("%s Calm brought Peace to the %d.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                } else {
                                    lg_line := fmt.aprintf("%s Calm failed.", play_name, allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                }
                            } else {
                                lg_line := fmt.aprintf("%s Calm ended the War in the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        }
                    }
                case 10:
                    // Chaos : -Fortune/~-Peace, ~+Rain/~+Fire; attack (Rain): 0.85, attack (Fire): 0.95
                    for j in 0..<sp_mult {
                        if rand.float32() > 0.5 {
                            fixed:bool = false
                            a_idx:int = -1
                            if dir > 0 {
                                fixed, a_idx = island_fix(.Fortune, chk_areas)
                            }
                            if !fixed {
                                att, a_idx := island_attack(.Rain, chk_areas, 0.75)
                                if att {
                                    lg_line := fmt.aprintf("%s Chaos brought Rain to the %s", play_name, island_area_names[a_idx], allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                } else {
                                    lg_line := fmt.aprintf("%s Chaos failed.", play_name, allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                }
                            } else {
                                lg_line := fmt.aprintf("%s Chaos ended the Fortune in the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        } else {
                            fixed:bool = false
                            a_idx:int = -1
                            if dir > 0 {
                                fixed, a_idx = island_fix(.Peace, chk_areas)
                            }
                            if !fixed {
                                att, a_idx := island_attack(.Fire, chk_areas, 0.9)
                                if att {
                                    lg_line := fmt.aprintf("%s Chaos started Fire in the %d.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                } else {
                                    lg_line := fmt.aprintf("%s Chaos failed.", play_name, allocator = log_alloc)
                                    defer delete(lg_line, allocator = log_alloc)
                                    game_log(lg_line)
                                }
                            } else {
                                lg_line := fmt.aprintf("%s Calm ended the Peace in the %s.", play_name, island_area_names[a_idx], allocator = log_alloc)
                                defer delete(lg_line, allocator = log_alloc)
                                game_log(lg_line)
                            }
                        }
                    }
            }
        }
    }
}

island_fix :: proc(effect:Area_Effects, check:[4]int) -> (bool, int) {
    fixed:bool = false
    fix_area:int = -1

    for a in 0..<len(check) {
        if effect in island.areas[check[a]] {
            island.areas[check[a]] -= { effect }
            fixed = true
            fix_area = check[a]
            break
        }
    }

    return fixed, fix_area
}

island_attack :: proc(effect:Area_Effects, check:[4]int, rate:f32) -> (bool, int) {
    attacked:bool = false
    att_area:int = -1

    for a in 0..<len(check) {
        if !(effect in island.areas[check[a]]) && rand.float32() > rate {
            island.areas[check[a]] += { effect }
            attacked = true
            att_area = check[a]
            break
        }
    }

    return attacked, att_area
}


