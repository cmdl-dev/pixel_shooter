package game

import "core:math/linalg"
import rl "vendor:raylib"

Bullet :: struct {
	size:      [2]f32,
	direction: Vec2,
	pos:       Vec2,
	velocity:  f32,
	lifeTime:  f64,
	isAlive:   bool,
}

getNextBulletId :: proc() -> int {
	@(static) BID := 0
	maxId := MAX_BULLETS

	BID += 1
	return BID % maxId
}

spawn_bullet :: proc(pos: Vec2, direction: Vec2, size: f32) {
	id := getNextBulletId()
	g_mem.bullets[id]^ = {
		size      = {size, size},
		direction = direction,
		pos       = pos,
		velocity  = 1000,
		isAlive   = true,
		lifeTime  = rl.GetTime() + 5,
	}
}
bullet_getRect :: proc(b: Bullet) -> Rect {
	return Rect{b.pos.x, b.pos.y, b.size.x, b.size.y}
}

despawn_bullet :: proc(bullet: ^Bullet) {
	bullet.pos = {0, 0}
	bullet.velocity = 0
	bullet.isAlive = false
}

update_bullet :: proc(bullet: ^Bullet, dt: f32) {
	if bullet.lifeTime <= rl.GetTime() {
		despawn_bullet(bullet)
		return
	}
	for &e in g_mem.enemies {
		if e.alive {
			if rl.CheckCollisionRecs(enemy_getRect(e^), bullet_getRect(bullet^)) {
				e.health -= 30
				spawn_bunch_particles(20, bullet.pos)
				despawn_bullet(bullet)
			}
		}
	}

	bullet.pos += dt * linalg.normalize0(bullet.direction) * bullet.velocity
}

draw_bullet :: proc(bullet: ^Bullet) {
	rl.DrawRectangleV(bullet.pos, bullet.size, rl.WHITE)
}


draw_all_bullets :: proc() {
	for &b in g_mem.bullets {
		if (b.isAlive) {
			draw_bullet(b)
		}
	}
}
update_all_bullets :: proc(dt: f32) {
	for &b in g_mem.bullets {
		if (b.isAlive) {
			update_bullet(b, dt)
		}
	}
}
