package game

import "core:math/rand"
import rl "vendor:raylib"

Enemy :: struct {
	size:   f32,
	health: f32,
	pos:    Vec2,
	alive:  bool,
}
getNextEnemyId :: proc() -> int {
	@(static) EID := 0
	maxId := MAX_ENEMIES
	EID += 1
	return EID % maxId
}

init_enemy :: proc(pos: Vec2) -> Enemy {
	return {size = 20, health = 100, pos = pos}
}


update_enemy :: proc(e: ^Enemy, dt: f32) {
	if e.health <= 0 {
		despawn_enemy(e)
		return
	}
}

enemy_getRect :: proc(e: Enemy) -> Rect {
	return Rect{e.pos.x, e.pos.y, e.size, e.size}
}

draw_enemy :: proc(e: ^Enemy) {
	pos := e.pos
	rl.DrawRectangleV(pos, Vec2(e.size), rl.RED)

	w: f32 = 20
	h: f32 = 5

	rl.DrawRectangleV({pos.x, pos.y + e.size + 1}, {w, h}, rl.GRAY)
	rl.DrawRectangleV({pos.x, pos.y + e.size + 1}, {w * (e.health / 100), h}, rl.GREEN)
}

respawn_enemy :: proc() {
	if g_mem.countEnemiesAlive < INIT_ENEMIES_COUNT {
		spawn_enemy_random()
	}
}

init_enemies :: proc() {
	for _ in 0 ..= INIT_ENEMIES_COUNT {
		spawn_enemy_random()
	}
}

despawn_enemy :: proc(e: ^Enemy) {
	g_mem.countEnemiesAlive -= 1
	e.alive = false
	e.health = 0
	e.pos = {0, 0}
	e.size = 0
}

spawn_enemy :: proc(pos: Vec2) {
	g_mem.countEnemiesAlive += 1
	id := getNextEnemyId()
	g_mem.enemies[id]^ = {
		health = 100,
		pos    = pos,
		alive  = true,
		size   = 20,
	}

}

spawn_enemy_random :: proc() {
	x := rand.float32_range(-1000, 2000)
	y := rand.float32_range(-1000, 2000)
	spawn_enemy({x, y})

}

draw_all_enemies :: proc() {
	for &e in g_mem.enemies {
		if e.alive {
			draw_enemy(e)
		}
	}
}
update_all_enemies :: proc(dt: f32) {
	for &e in g_mem.enemies {
		if e.alive {
			update_enemy(e, dt)
		}
	}
}
