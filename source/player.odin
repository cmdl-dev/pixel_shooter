package game

import "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

/**
TODO: Create a gatherable item that the player can use for power ups
TODO: Create a power that shoots 3 bullets at once
*/

PowerUp :: struct {
	apply: proc(b: BulletInfo) -> BulletInfo,
}
RapiFirePowerUp :: struct {
	using powerUp: PowerUp,
}

// TODO: Have a way to undo this
RF :: RapiFirePowerUp {
	powerUp = PowerUp{apply = proc(b: BulletInfo) -> BulletInfo {
			tb := b
			tb.maxBulletInterval = b.maxBulletInterval / 3
			return tb
		}},
}

PowerUpTypes :: enum {
	RapidFire,
	SpreadFire,
}

BulletInfo :: struct {
	_bulletInterval:   f32,
	maxBulletInterval: f32,
}
bulletInfo_ratio_cooldown :: proc(bInfo: BulletInfo) -> f32 {
	return bInfo._bulletInterval / bInfo.maxBulletInterval
}

ShootingStats :: struct {
	readyToShoot:     bool,
	powerUps:         bit_set[PowerUpTypes],
	powerUpsCooldown: map[PowerUpTypes]f32,
	bulletInfo:       BulletInfo,
}
init_shootingStats :: proc(interval: f32) -> ShootingStats {
	return ShootingStats {
		bulletInfo = {_bulletInterval = interval, maxBulletInterval = interval},
		readyToShoot = true,
	}
}
shootingSats_readyToShoot :: proc(stat: ShootingStats) -> bool {
	return stat.readyToShoot
}


Player :: struct {
	pos:            Vec2,
	speed:          f32,
	size:           f32,
	sprintingMulti: f32,
	health:         i32,
	maxHealth:      i32,
	isSprinting:    bool,
	shooting:       bool,
	shootingStats:  ShootingStats,
}

init_player :: proc() -> Player {
	bInterval: f32 = .600
	return Player {
		pos = Vec2(2),
		size = 20,
		speed = 200,
		sprintingMulti = 2.0,
		maxHealth = 100,
		health = 100,
		shooting = false,
		shootingStats = init_shootingStats(bInterval),
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

	if rl.IsMouseButtonPressed(.RIGHT) {
		player_addPowerUp(player, .RapidFire)
		player_addPowerUp(player, .SpreadFire)
	}


	// Player Shooting 
	if !shootingSats_readyToShoot(player.shootingStats) {
		bulletInfo := player.shootingStats.bulletInfo

		if .RapidFire in player.shootingStats.powerUps {
			bulletInfo = RF.apply(player.shootingStats.bulletInfo)
		}

		onFrameDelay(
			&player.shootingStats.bulletInfo._bulletInterval,
			bulletInfo.maxBulletInterval,
			proc(player: ^Player) {player.shootingStats.readyToShoot = true},
			player,
		)
	}

	return
}

player_addPowerUp :: proc(player: ^Player, powerUp: PowerUpTypes) {
	player.shootingStats.powerUps += {powerUp}
	player.shootingStats.powerUpsCooldown[powerUp] = 10 // 10 Seconds
	// bulletInfo_apply_powerup(&player.shootingStats)
}
player_removePowerUp :: proc(player: ^Player, powerUp: PowerUpTypes) {
	delete_key(&player.shootingStats.powerUpsCooldown, powerUp)
	player.shootingStats.powerUps -= {powerUp}
	// bulletInfo_remove_powerup(&player.shootingStats)
}

player_get_speed :: proc(player: Player) -> f32 {
	return player.speed * (player.isSprinting ? player.sprintingMulti : 1.0)
}

player_center :: proc(player: Player) -> Vec2 {

	return {player.pos.x + (player.size / 2), player.pos.y + (player.size / 2)}

}

update_player :: proc(player: ^Player, dt: f32) {
	pInput := handle_player_input(player)

	player.pos += linalg.normalize0(pInput) * dt * player_get_speed(player^)


	if player.shooting && shootingSats_readyToShoot(player.shootingStats) {
		player.shootingStats.readyToShoot = false
		mPos := rl.GetScreenToWorld2D(rl.GetMousePosition(), game_camera())
		bulletPos := linalg.normalize0(mPos - g_mem.player.pos)
		spawn_bullet(player_center(g_mem.player), bulletPos, 6)
		if .SpreadFire in player.shootingStats.powerUps {
			spawn_bullet(player_center(g_mem.player), rotateVector(bulletPos, 10), 6)
			spawn_bullet(player_center(g_mem.player), rotateVector(bulletPos, -10), 6)
		}

	}

	if len(player.shootingStats.powerUpsCooldown) > 0 {

		for key, &val in player.shootingStats.powerUpsCooldown {
			val -= dt
			if (val < 0) {
				player_removePowerUp(player, key)
			}
		}
	}


}

draw_player :: proc(p: Player) {
	rl.DrawRectangleV(p.pos, Vec2(p.size), rl.BLUE)
}
draw_player_ui :: proc(p: Player) {
	draw_player_health(p)
	draw_player_bullet_timer(p)
	draw_player_powerUp_cooldown(p)

}
draw_player_powerUp_cooldown :: proc(p: Player) {
	fontSize: i32 = 15
	pos := Rect{}
	for _, val in p.shootingStats.powerUpsCooldown {
		powerUpText := fmt.ctprintf("Cooldown: %f", val)
		textWidth := rl.MeasureText(powerUpText, fontSize)
		uiCamera := ui_camera()

		pos = getScreenPos(
			.Center_Left,
			{f32(textWidth) + pos.width, f32(fontSize) + pos.height},
			uiCamera,
		)
		// nPos := rl.GetScreenToWorld2D({pos.x, pos.y}, uiCamera)
		rl.DrawText(powerUpText, i32(pos.x), i32(pos.y), fontSize, rl.WHITE)
	}
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

// TODO: When we have a power up the ratio does not match that ??? 
draw_player_bullet_timer :: proc(p: Player) {
	w: f32 = 5
	h: f32 = 10

	pos := getScreenPos(.Bottom_Left, {w, h}, ui_camera())
	pos.y -= 15

	rl.DrawRectangleRec(pos, rl.GRAY)

	pos.height = pos.height * bulletInfo_ratio_cooldown(p.shootingStats.bulletInfo)

	rl.DrawRectangleRec(pos, rl.GREEN)
}
