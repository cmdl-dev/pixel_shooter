/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
      pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g_mem` global
      variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:fmt"
import mu "vendor:microui"
import rl "vendor:raylib"


_ :: fmt
Vec2 :: rl.Vector2
Rect :: rl.Rectangle

MAX_BULLETS :: 50
INIT_ENEMIES_COUNT :: 10
PIXEL_WINDOW_HEIGHT :: 800

Mu_State :: struct {
	atlas_texture: rl.Texture2D,
	bg:            mu.Color,
	mu_ctx:        mu.Context,
}
Game_Memory :: struct {
	showDebug:   bool,
	player:      Player,
	bullets:     [MAX_BULLETS]^Bullet,
	enemies:     [dynamic]Enemy,
	some_number: int,
	run:         bool,
	mu_state:    Mu_State,
}

g_mem: ^Game_Memory

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {zoom = h / PIXEL_WINDOW_HEIGHT, target = g_mem.player.pos, offset = {w / 2, h / 2}}
}

ui_camera :: proc() -> rl.Camera2D {
	// return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
	return {zoom = 3.0}
}

update :: proc() {
	dt := rl.GetFrameTime()

	if rl.IsKeyPressed(.F2) {
		g_mem.showDebug = !g_mem.showDebug
	}


	{
		update_player(&g_mem.player, dt)
		update_all_bullets(dt)
		update_all_enemies(dt)
	}

	if rl.IsKeyPressed(.ESCAPE) {
		g_mem.run = false
	}
}

draw :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.BLACK)

	{ 	// World
		rl.BeginMode2D(game_camera())
		defer rl.EndMode2D()
		draw_player(g_mem.player)

		// rl.DrawRectangleV({20, 20}, {10, 10}, rl.RED)
		// rl.DrawRectangleV({-30, -20}, {10, 10}, rl.GREEN)
		draw_all_bullets()
		draw_all_enemies()
	}

	{ 	// Camera
		rl.BeginMode2D(ui_camera())
		defer rl.EndMode2D()

		draw_player_ui(g_mem.player)

		// screenDim := GetCameraScreenDimension(ui_camera())
		// RED LINES
		// rl.DrawLine(i32(0), i32(screenDim.y / 2), i32(screenDim.x), i32(screenDim.y / 2), rl.RED)
	}
	if g_mem.showDebug {
		screenDim := GetScreenDimension()
		tRPos := getScreenPos(.Top_Right, Vec2(20))

		rl.DrawText("DEBUG IS ON", i32(screenDim.x / 2), 0, 50, rl.ORANGE)
		rl.DrawFPS(i32(tRPos.x / 2), i32(tRPos.y + 50))
		mu_draw()
	}
}


@(export)
game_update :: proc() {
	mu_update()

	update()
	draw()

}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1920, 1080, "Odin + Raylib + Hot Reload template!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(60)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)


	g_mem^ = Game_Memory {
		run       = true,
		mu_state  = init_microui(),
		showDebug = false,
		player    = init_player(),
	}
	for i in 0 ..= MAX_BULLETS - 1 {
		g_mem.bullets[i] = new(Bullet)
	}


	mu.init(&g_mem.mu_state.mu_ctx)
	g_mem.mu_state.mu_ctx.text_width = mu.default_atlas_text_width
	g_mem.mu_state.mu_ctx.text_height = mu.default_atlas_text_height

	init_n_enemies()

	game_hot_reloaded(g_mem)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g_mem.run
}

@(export)
game_shutdown :: proc() {
	rl.UnloadTexture(g_mem.mu_state.atlas_texture)
	for i in 0 ..= MAX_BULLETS - 1 {
		free(g_mem.bullets[i])
	}
	free(g_mem)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g_mem
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g_mem = (^Game_Memory)(mem)

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside
	// `g_mem`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
