package sol

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

instructions_built:bool = false
instructions_scroll:f32 = 0
instructions_scroll_max:f32 = 0
instructions_lh:f32 = 10

instructions := []string{
    "<TITLE>",
    "When lesser gods get bored, they often play a quick hand of Blood, Banners, Bones, & Heads, to pass the time.  You are a lesser god, so why not give it a try?",
    "The god (you, the player), as with all solitares, plays against the Deck.  The Deck is made up of numbered cards, 1 through 10, in five suits: Blood, Banners, Bones, Fishheads, and Arrowheads (thus, the name of the game!).",
    "<SUITS>",
    "Each number also corresponds to a Spell (more on that in a bit).  Cards can be played in sets of either 1, 2, or 3, and they must all be played either as a Suit or as Spells.",
    "When played as a Suit by the, the total of the hand is added to the player's tally.  Your tally is used with the three most important spells: Teleport, Transmogrify, and Transmute (again, more on those in a bit).  If no cards in a play match in either number or suit, the score of the play is the highest numbered card.  If all of the cards in the play have the same suit (a Flush), the score of the play is the sum of the cards with the highest card doubled.  If all of the cards in the play have the same number (a Set), the score of the play is the sum of the cards multiplied by the number of cards in the play.",
    "When played as Spells, each card will cast its spell once.  The spells are used to affect the player's island, which is the center of the game.",
    "Your island has three main stats: Population, Food, and Coin (money).  It is divided into four main areas: the North, the East, the South, and the West (super creative naming, right?).  Each area can be blessed/afflicted with various events: Sickness, Flood, Fervor, Fire, Famine, Rain, Bandits, Fortune, War, or Peace.",
    "<EFFECTS>",
    "The spells:",
    "<SPELLS>",
    "Now, on your island, you need to have at least as much food as people or they will starve.  If your food is low, the people will first try and spend coin to buy food on a one-to-one basis.  Once that is done, if your food is lower than your population, you lose the difference to startvation.  Yikes.",
    "As mentioned earlier, you're playing against the Deck.  It's not very smart.  In fact, it can't think at all.  Its plays are determined by the roll of a six-sided dice: 1, 2, or 3 pips means it plays 1, 2, or 3 cards as Suits, and 1, 2, or 3 stars means it plays 1, 2, or 3 cards as Spells.  Here's the thing, though: when the Deck plays everything goes AGAINST you.  So if it casts Teleport, it REMOVES the sum of the cards from the population.  If it plays a Suit hand worth 20, it REMOVES 20 from your tally.  If it plays Storm as a spell, it doesn't remove any Fires, it only has a chance to add Flooding.  Bad news.",
    "So there you have it!  That's how you play!  You play 10 rounds in a game and you can chose from one of three play modes: People, in which you need to have a certain number of people on the island at the end, Wealth (it's tough), where you need to have a certain amount of coin at the end, or Score, in which the total of your population, food, and coin adds up to your goal or higher.",
    "<GOODLUCK>"
}

build_instructions :: proc(width:f32) {
    i_img_h:f32 = 0
    i_img_w:f32 = width
    i_ln_h:f32 = 0

    all_lines := make([dynamic]cstring, allocator = graph_alloc)

    for i in 0..<len(instructions) {
        n_lines := wrap_lines(instructions[i], i_img_w, board.font_size)
        for j in 0..<len(n_lines) {
            append(&all_lines, strings.clone_to_cstring(n_lines[j], allocator = graph_alloc))
            cs_i:int = len(all_lines) - 1
            if i_ln_h == 0 {
                ln_sz := rl.MeasureTextEx(font, all_lines[cs_i], board.font_size, 0)
                i_ln_h = ln_sz.y
            }
            if all_lines[cs_i] == "<TITLE>" {
                i_img_h += board.font_size * 2
            } else if all_lines[cs_i] == "<GOODLUCK>" {
                i_img_h += i_ln_h + (board.font_size * 3)
            } else if all_lines[cs_i] == "<SUITS>" {
                i_img_h += i_ln_h * 2
            } else if all_lines[cs_i] == "<EFFECTS>" {
                i_img_h += (i_ln_h * 1.5 * 10) + i_ln_h
            } else if all_lines[cs_i] == "<SPELLS>" {
                i_img_h += (i_ln_h * 1.5 * 10) + i_ln_h
            } else {
                i_img_h += i_ln_h
            }
        }
        append(&all_lines, "")
        i_img_h += i_ln_h
    }

    instructions_lh = i_ln_h

    i_img := rl.GenImageColor(i32(i_img_w), i32(i_img_h), { 0, 0, 0, 0 })
    c_y:f32 = 0
    for i in 0..<len(all_lines) {
        if all_lines[i] == "<TITLE>" {
            rl.ImageDrawTextEx(&i_img, font, "HOW TO PLAY", { 0, c_y }, board.font_size * 2, 0, rl.WHITE)
            c_y += board.font_size * 2
        } else if all_lines[i] == "<GOODLUCK>" {
            c_y += i_ln_h
            rl.ImageDrawTextEx(&i_img, font, "GOOD LUCK!", { 0, c_y }, board.font_size * 2, 0, rl.WHITE)
        } else if all_lines[i] == "<SUITS>" {

            t_w:f32 = i_ln_h * 10
            c_x1:f32 = (i_img_w * 0.5) - (t_w * 0.5)

            for st in 0..<5 {
                rl.ImageDraw(&i_img, images[img_card_layout], { f32(500 * st) + 10, 866, 100, 100 }, { c_x1, c_y, 2 * i_ln_h, 2 * i_ln_h}, suit_colors[st+1])
                c_x1 += i_ln_h * 2
            }

            c_y += i_ln_h * 2
        } else if all_lines[i] == "<EFFECTS>" {

            c_y += i_ln_h * 0.5
            c_x2:f32 = i_ln_h * 2

            for e in 1..=10 {
                rl.ImageDrawTextEx(&i_img, font, area_effect_desc[e], { c_x2, c_y }, board.font_size, 0, rl.WHITE)
                c_y += i_ln_h * 1.5
            }

            c_y += i_ln_h * 0.5

        } else if all_lines[i] == "<SPELLS>" {

            c_y += i_ln_h * 0.5
            c_x3:f32 = i_ln_h * 2

            for s in 1..=10 {
                rl.ImageDrawTextEx(&i_img, font, spell_info_short[s], { c_x3, c_y }, board.font_size, 0, rl.WHITE)
                c_y += i_ln_h * 1.5
            }

            c_y += i_ln_h * 0.5

        } else {
            rl.ImageDrawTextEx(&i_img, font, all_lines[i], { 0, c_y }, board.font_size, 0, rl.WHITE)
            c_y += i_ln_h
        }
    }

    instructions_texture = rl.LoadTextureFromImage(i_img)
    rl.UnloadImage(i_img)

    for i in 0..<len(all_lines) {
        delete(all_lines[i], allocator = graph_alloc)
    }
    delete(all_lines)

    instructions_built = true
}