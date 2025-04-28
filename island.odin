package sol

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

ISLAND_START_STATS:int : 50

A_NORTH:int : 0
A_EAST:int : 1
A_SOUTH:int : 2
A_WEST:int : 3

EFF_SICKNESS_RATE:f32 : 0.05
EFF_FLOOD_RATE:f32 : 0.1
EFF_FERVOR_RATE:f32 : 0.15

EFF_FIRE_RATE:f32 : 0.05
EFF_FAMINE_RATE:f32 : 0.2
EFF_RAIN_RATE:f32 : 0.15

EFF_BANDITS_RATE:f32 : 0.08
EFF_FORTUNE_RATE:f32 : 0.12

EFF_WAR_RATE:f32 : 0.1
EFF_PEACE_RATE:f32 : 0.12

Area_Effects :: enum {
    Sickness = 1,
    Flood = 2,
    Fervor = 3,
    Fire = 4,
    Famine = 5,
    Rain = 6,
    Bandits = 7,
    Fortune = 8,
    War = 9,
    Peace = 10
} 

area_effect_desc := []cstring {
    "None",
    "Sickness - Takes 5% of population at the end of each turn.",
    "Flood - Takes 10% of population at the end of each turn.",
    "Fervor - Increases population by 15% at the end of each turn.",
    "Fire - Destroys 5% of food at the end of each turn.",
    "Famine - Destroys 20% of food at the end of each turn.",
    "Rain - Increases food by 15% of food at the end of each turn.",
    "Bandits - Take 8% of coin at the end of each turn.",
    "Fortune - Increase coin by 12% at the end of each turn.",
    "War - Decrease population, food, and coin by 10% each at end of turn.",
    "Peace - Increase population, food, and coin by 12% each at end of turn."
}

island_area_names := [4]string{
    "North",
    "East",
    "South",
    "West"
}

Island :: struct {
    population:int,
    mult:int,
    food:int,
    money:int,
    areas:[4]bit_set[Area_Effects],
    area_eff_coords:[4][10]rl.Vector2,
    area_eff_rad:f32
}

island := Island{
    population = ISLAND_START_STATS,
    mult = 1,
    food = ISLAND_START_STATS,
    money = ISLAND_START_STATS,
    areas = [4]bit_set[Area_Effects]{
        bit_set[Area_Effects]{},
        bit_set[Area_Effects]{},
        bit_set[Area_Effects]{},
        bit_set[Area_Effects]{}
    },
    area_eff_coords = [4][10]rl.Vector2{
        [10]rl.Vector2{ {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0} },
        [10]rl.Vector2{ {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0} },
        [10]rl.Vector2{ {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0} },
        [10]rl.Vector2{ {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0} }
    },
    area_eff_rad = 150
}

init_island :: proc() {
    center_coords := [4]rl.Vector2{
        { 580 + 150, 420 + 150 },
        { 1020 + 150, 595 + 150 },
        { 595 + 150, 780 + 150 },
        { 150 + 150, 555 + 150 }
    }

    for a in 0..<4 {
        c_x:f32 = center_coords[a].x
        c_y:f32 = center_coords[a].y

        full_rad:f32 = 140
        ang:f32 = rand.float32() * 360
        ang_i:f32 = 360 / 10

        for i in 0..<10 {
            c_rad:f32 = full_rad
            if i % 2 == 0 {
                c_rad = 80
            }
            t_rad:f32 = (full_rad * 0.4) + (rand.float32() * (full_rad * 0.6))
            t_x:f32 = c_rad * math.cos(ang * math.π / 180)
            t_y:f32 = c_rad * math.sin(ang * math.π / 180)

            island.area_eff_coords[a][i] = { c_x + t_x, c_y + t_y }

            ang += ang_i
            if ang > 360 {
                ang -= 360
            }
        }
    }
}

start_island :: proc() {
    island.population = ISLAND_START_STATS
    island.mult = 1
    island.food = ISLAND_START_STATS
    island.money = ISLAND_START_STATS
    island.areas = [4]bit_set[Area_Effects]{
        bit_set[Area_Effects]{},
        bit_set[Area_Effects]{},
        bit_set[Area_Effects]{},
        bit_set[Area_Effects]{}
    }

    center_coords := [4]rl.Vector2{
        { 580 + 150, 420 + 150 },
        { 1020 + 150, 595 + 150 },
        { 595 + 150, 780 + 150 },
        { 150 + 150, 555 + 150 }
    }
    
    for a in 0..<4 {
        c_x:f32 = center_coords[a].x
        c_y:f32 = center_coords[a].y

        full_rad:f32 = 140
        ang:f32 = rand.float32() * 360
        ang_i:f32 = 360 / 10

        for i in 0..<10 {
            c_rad:f32 = full_rad
            if i % 2 == 0 {
                c_rad = 80
            }
            t_rad:f32 = (full_rad * 0.4) + (rand.float32() * (full_rad * 0.6))
            t_x:f32 = c_rad * math.cos(ang * math.π / 180)
            t_y:f32 = c_rad * math.sin(ang * math.π / 180)

            island.area_eff_coords[a][i] = { c_x + t_x, c_y + t_y }

            ang += ang_i
            if ang > 360 {
                ang -= 360
            }
        }
    }
}

end_island :: proc() {

}

run_island :: proc() {

    pre_pop := island.population
    pre_food := island.food
    pre_money := island.money

    //island.population += player.score
    //island.food += player.score
    //island.money += player.score

    run_pop:f32 = f32(island.population)
    run_food:f32 = f32(island.food)
    run_money:f32 = f32(island.money)

    /*
    if game_hand > 0 {
        if player.score == 0 {
            game_log("Your tally is 0.")
        } else {
            tally_dir:string = player.score < 0 ? "removed" : "added"
            lg_line := fmt.aprintf("Your tally has %s %d people (%d -> %d), %d food (%d -> %d), and %d coin (%d -> %d).", 
                tally_dir,
                math.abs(player.score), 
                pre_pop, island.population,
                math.abs(player.score), 
                pre_food, island.food,
                math.abs(player.score),
                pre_money, island.money,
                allocator = log_alloc
            )
            lg_line := fmt.aprintf("Your tally has %s %d people (%d -> %d).", tally_dir, math.abs(player.score), pre_pop, island.population)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        } 
    }
    */

    for a in 0..<4 {
        if .Sickness in island.areas[a] {
            d_pop:int = int(math.floor(run_pop * EFF_SICKNESS_RATE))
            island.population = island.population - d_pop <= 0 ? 0 : island.population - d_pop
            lg_line := fmt.aprintf("Sickness in the %s has taken %d people.", island_area_names[a], d_pop, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
        if .Flood in island.areas[a] {
            d_pop:int = int(math.floor(run_pop * EFF_FLOOD_RATE))
            island.population = island.population - d_pop <= 0 ? 0 : island.population - d_pop
            lg_line := fmt.aprintf("Flooding in the %s has taken %d people.", island_area_names[a], d_pop, allocator = log_alloc) 
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
        if .Fervor in island.areas[a] {
            d_pop:int = int(math.ceil(run_pop * EFF_FERVOR_RATE))
            island.population += d_pop
            lg_line := fmt.aprintf("The Fervor in the %s has grown the population by %d.", island_area_names[a], d_pop, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }

        if .Fire in island.areas[a] {
            d_fd:int = int(math.floor(run_food * EFF_FIRE_RATE))
            island.food = island.food - d_fd <= 0 ? 0 : island.food - d_fd
            lg_line := fmt.aprintf("Fire in the %s destroyed %d food.", island_area_names[a], d_fd, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
        if .Famine in island.areas[a] {
            d_fd:int = int(math.floor(run_food * EFF_FAMINE_RATE))
            island.food = island.food - d_fd <= 0 ? 0 : island.food - d_fd
            lg_line := fmt.aprintf("Famine in the %s destroyed %d food.", island_area_names[a], d_fd, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
        if .Rain in island.areas[a] {
            d_fd:int = int(math.ceil(run_food * EFF_RAIN_RATE))
            island.food += d_fd
            lg_line := fmt.aprintf("Rain in the %s helped add %d food.", island_area_names[a], d_fd, allocator = log_alloc) 
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }

        if .Bandits in island.areas[a] {
            d_mn:int = int(math.floor(run_money * EFF_BANDITS_RATE))
            island.money = island.money - d_mn <= 0 ? 0 : island.money - d_mn
            lg_line := fmt.aprintf("Bandits in the %s have stolen %d coin.", island_area_names[a], d_mn, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
        if .Fortune in island.areas[a] {
            d_mn:int = int(math.ceil(run_money * EFF_FORTUNE_RATE))
            island.money += d_mn
            lg_line := fmt.aprintf("Fortune in the %s has added %d coin.", island_area_names[a], d_mn, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }

        if .War in island.areas[a] {
            d_pop:int = int(math.floor(run_pop * EFF_WAR_RATE))
            d_fd:int = int(math.floor(run_food * EFF_WAR_RATE))
            d_mn:int = int(math.floor(run_money * EFF_WAR_RATE))
            island.population = island.population - d_pop <= 0 ? 0 : island.population - d_pop
            island.food = island.food - d_fd <= 0 ? 0 : island.food - d_fd
            island.money = island.money - d_mn <= 0 ? 0 : island.money - d_mn
            lg_line := fmt.aprintf("War in the %s has claimed %d, lost %d food, and cost %d coin.", island_area_names[a], d_pop, d_fd, d_mn, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
        if .Peace in island.areas[a] {
            d_pop:int = int(math.ceil(f32(island.population) * EFF_PEACE_RATE))
            d_fd:int = int(math.ceil(f32(island.food) * EFF_PEACE_RATE))
            d_mn:int = int(math.ceil(run_money * EFF_PEACE_RATE))
            island.population += d_pop
            island.food += d_fd
            island.money += d_mn
            lg_line := fmt.aprintf("Peace in the %s has added %d, gained %d food, and added %d coin.", island_area_names[a], d_pop, d_fd, d_mn, allocator = log_alloc) 
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
    }

    if game_settings.births && game_hand > 0 {
        births:int = int(math.ceil(f32(island.population) * 0.02))
        island.population += births
        if births > 0 {
            baby:string = births == 1 ? "baby has" : "babies have"
            lg_line := fmt.aprintf("%d %s been born!", births, baby, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
    }
    
    if island.food < island.population {
        f_diff:int = island.population - island.food
        d_mn:int = 0
        if island.money > f_diff {
            d_mn = f_diff
            island.money -= f_diff
            island.food += f_diff
        } else if island.money > 0 {
            island.food += island.money
            d_mn = island.money
            island.money = 0
        }
        if d_mn > 0 {
            lg_line := fmt.aprintf("You have spent %d coin to buy food.", d_mn, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
        if island.food < island.population {
            f_diff = island.population - island.food
            island.population -= f_diff
            lg_line := fmt.aprintf("You have lost %d people due to lack of food.", f_diff, allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
    }

    if island.population < 0 {
        island.population = 0
    }

    if island.food < 0 {
        island.food = 0
    }

    if island.money < 0 {
        island.money = 0
    }

    sick_rate:f32 = 0.99 - (0.1 * math.floor(f32(island.population) / 200))
    fire_rate:f32 = 0.99 - (0.1 * math.floor(f32(island.food) / 200))
    bandit_rate:f32 = 0.99 - (0.1 * math.floor(f32(island.money) / 200))

    for a in 0..<4 {
        if rand.float32() > sick_rate && !(.Sickness in island.areas[a]) {
            island.areas[a] += { .Sickness }
            lg_line := fmt.aprintf("A mysterious illness has broken out in the %s!", island_area_names[a], allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }

        if rand.float32() > fire_rate && !(.Fire in island.areas[a]) {
            island.areas[a] += { .Fire }
            lg_line := fmt.aprintf("A fire has broken out in the %s!", island_area_names[a], allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }

        if rand.float32() > bandit_rate && !(.Bandits in island.areas[a]) {
            island.areas[a] += { .Bandits }
            lg_line := fmt.aprintf("Bandits have been spotted in the %s!", island_area_names[a], allocator = log_alloc)
            defer delete(lg_line, allocator = log_alloc)
            game_log(lg_line)
        }
    }
}