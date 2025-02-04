package game

import "core:math/rand"
import rl "vendor:raylib"

Particle :: struct {
	timeAlive: f32,
	opacity:   f32,
	size:      i32,
	//
	position:  Vec2,
	acc:       Vec2,
	velocity:  Vec2,
}


init_particle :: proc(pos: Vec2) -> Particle {


	return Particle {
		timeAlive = .200,
		opacity = 1,
		size = 3,
		position = pos,
		velocity = {rand.float32_range(-5, 5), rand.float32_range(-5, 5)},
		acc = {0, 0.5},
	}
}

update_particle :: proc(p: ^Particle, dt: f32) {
	p.timeAlive -= dt

	p.velocity += p.acc
	p.position += p.velocity
	if rand.float32_range(0, 100) > 80 {
		size := p.size - 1
		p.size = clamp(size, 1, 5)
	}
	// if
}

draw_particle :: proc(p: Particle) {
	rl.DrawRectangleV(p.position, Vec2(p.size), rl.YELLOW)
}

spawn_bunch_particles :: proc(num: i32, pos: Vec2) {
	for i in 0 ..= num {
		p := init_particle(pos)
		g_mem.particles[i] = p
	}
}

update_all_particles :: proc(dt: f32) {
	for &p in g_mem.particles {
		if p.timeAlive > 0 {

			update_particle(&p, dt)
		}
	}
}
draw_all_particles :: proc() {
	for p in g_mem.particles {
		if p.timeAlive > 0 {
			draw_particle(p)
		}
	}
}
