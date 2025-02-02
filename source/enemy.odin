package game

import "core:math/rand"
import rl "vendor:raylib"

Enemy :: struct {
	size:   f32,
	health: f32,
	pos:    Vec2,
}

init_enemy :: proc(pos: Vec2) -> Enemy {
	return {size = 20, health = 100, pos = pos}
}


update_enemy :: proc(e: ^Enemy, dt: f32) {
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

init_n_enemies :: proc() {
	for _ in 0 ..= INIT_ENEMIES_COUNT {
		x := rand.float32_range(-100, 500)
		y := rand.float32_range(-100, 500)

		append(&g_mem.enemies, init_enemy({x, y}))
	}
}


draw_all_enemies :: proc() {
	for &e in g_mem.enemies {
		draw_enemy(&e)
	}
}
update_all_enemies :: proc(dt: f32) {
	for &e in g_mem.enemies {
		update_enemy(&e, dt)
	}
}
