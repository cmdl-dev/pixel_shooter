package game

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"


Player :: struct {
	pos:               Vec2,
	speed:             f32,
	size:              f32,
	isSprinting:       bool,
	sprintingMulti:    f32,
	health:            i32,
	maxHealth:         i32,
	// o
	_bulletInterval:   f32,
	maxBulletInterval: f32,
	shooting:          bool,
	readyToShoot:      bool,
}


init_player :: proc() -> Player {
	bInterval: f32 = .500
	return Player {
		pos               = Vec2(2),
		size              = 20,
		speed             = 200,
		sprintingMulti    = 2.0,
		maxHealth         = 100,
		health            = 100,
		maxBulletInterval = bInterval,
		_bulletInterval   = bInterval, // Ready to shoot initially
		shooting          = false,
		readyToShoot      = true,
	}
}

handle_player_input :: proc(player: ^Player) -> (input: Vec2) {
	player.isSprinting = false
	player.shooting = false
	// Player Input
	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.PERIOD) {
		input.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.E) {
		input.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.O) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.U) {
		input.x += 1
	}

	if rl.IsKeyDown(.LEFT_SHIFT) {
		player.isSprinting = true
	}

	if rl.IsMouseButtonDown(.LEFT) {
		player.shooting = true
	}

	// Player Shooting 
	if !player.readyToShoot {

		onFrameDelay(
			&player._bulletInterval,
			player.maxBulletInterval,
			proc(player: ^Player) {player.readyToShoot = true},
			player,
		)
	}

	return
}

player_get_speed :: proc(player: Player) -> f32 {
	return player.speed * (player.isSprinting ? player.sprintingMulti : 1.0)
}


update_player :: proc(player: ^Player, dt: f32) {
	pInput := handle_player_input(player)

	player.pos += linalg.normalize0(pInput) * dt * player_get_speed(player^)


	if player.shooting && player.readyToShoot {
		player.readyToShoot = false
		mPos := rl.GetScreenToWorld2D({f32(rl.GetMouseX()), f32(rl.GetMouseY())}, game_camera())
		spawn_bullet(g_mem.player.pos, linalg.normalize0(mPos - g_mem.player.pos), 6)

	}
}

draw_player :: proc(p: Player) {
	rl.DrawRectangleV(p.pos, Vec2(p.size), rl.BLUE)
}
draw_player_ui :: proc(p: Player) {
	draw_player_health(p)
	draw_player_bullet_timer(p)

}
draw_player_health :: proc(p: Player) {
	fontSize: i32 = 15
	healthText := fmt.ctprintf("Health: %d/%d", p.health, p.maxHealth)
	textWidth := rl.MeasureText(healthText, fontSize)
	uiCamera := ui_camera()

	pos := getScreenPos(.Bottom_Left, {f32(textWidth), f32(fontSize)}, uiCamera)

	// nPos := rl.GetScreenToWorld2D({pos.x, pos.y}, uiCamera)
	rl.DrawText(healthText, i32(pos.x), i32(pos.y), fontSize, rl.WHITE)
}

draw_player_bullet_timer :: proc(p: Player) {
	w: f32 = 5
	h: f32 = 10

	pos := getScreenPos(.Bottom_Left, {w, h}, ui_camera())
	pos.y -= 15

	rl.DrawRectangleRec(pos, rl.GRAY)

	pos.height = pos.height * (p._bulletInterval / p.maxBulletInterval)

	rl.DrawRectangleRec(pos, rl.GREEN)
}
