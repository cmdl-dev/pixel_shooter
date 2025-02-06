package game

import "core:fmt"
import mu "vendor:microui"
import rl "vendor:raylib"

init_microui :: proc() -> Mu_State {

	pixels := make([][4]u8, mu.DEFAULT_ATLAS_WIDTH * mu.DEFAULT_ATLAS_HEIGHT)
	for alpha, i in mu.default_atlas_alpha {
		pixels[i] = {0xff, 0xff, 0xff, alpha}
	}
	defer delete(pixels)

	image := rl.Image {
		data    = raw_data(pixels),
		width   = mu.DEFAULT_ATLAS_WIDTH,
		height  = mu.DEFAULT_ATLAS_HEIGHT,
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8A8,
	}
	return Mu_State{atlas_texture = rl.LoadTextureFromImage(image)}
}
mu_update :: proc() {

	ctx := &g_mem.mu_state.mu_ctx
	// mouse coordinates
	mouse_pos := [2]i32{rl.GetMouseX(), rl.GetMouseY()}
	mu.input_mouse_move(ctx, mouse_pos.x, mouse_pos.y)
	mu.input_scroll(ctx, 0, i32(rl.GetMouseWheelMove() * -30))

	// mouse buttons
	@(static) buttons_to_key := [?]struct {
		rl_button: rl.MouseButton,
		mu_button: mu.Mouse,
	}{{.LEFT, .LEFT}, {.RIGHT, .RIGHT}, {.MIDDLE, .MIDDLE}}
	for button in buttons_to_key {
		if rl.IsMouseButtonPressed(button.rl_button) {
			mu.input_mouse_down(ctx, mouse_pos.x, mouse_pos.y, button.mu_button)
		} else if rl.IsMouseButtonReleased(button.rl_button) {
			mu.input_mouse_up(ctx, mouse_pos.x, mouse_pos.y, button.mu_button)
		}

	}

	// keyboard
	@(static) keys_to_check := [?]struct {
		rl_key: rl.KeyboardKey,
		mu_key: mu.Key,
	} {
		{.LEFT_SHIFT, .SHIFT},
		{.RIGHT_SHIFT, .SHIFT},
		{.LEFT_CONTROL, .CTRL},
		{.RIGHT_CONTROL, .CTRL},
		{.LEFT_ALT, .ALT},
		{.RIGHT_ALT, .ALT},
		{.ENTER, .RETURN},
		{.KP_ENTER, .RETURN},
		{.BACKSPACE, .BACKSPACE},
	}
	for key in keys_to_check {
		if rl.IsKeyPressed(key.rl_key) {
			mu.input_key_down(ctx, key.mu_key)
		} else if rl.IsKeyReleased(key.rl_key) {
			mu.input_key_up(ctx, key.mu_key)
		}
	}

	mu.begin(ctx)
	mu_windows(ctx)
	mu.end(ctx)
}
mu_windows :: proc(ctx: ^mu.Context) {
	@(static) opts := mu.Options{.NO_CLOSE, .NO_RESIZE, .NO_INTERACT}

	screenPos := getScreenPos(.Top_Right, {200, 300})
	if mu.window(
		ctx,
		"Debug Window",
		{i32(screenPos.x), i32(screenPos.y), i32(screenPos.width), i32(screenPos.height)},
		opts,
	) {

		if .ACTIVE in mu.header(ctx, "Player Info", mu.Options{.AUTO_SIZE}) {
			player := g_mem.player
			// win := mu.get_current_container(ctx)
			mu.layout_row(ctx, {0, -1}, 0)
			mu.label(ctx, "Position:")
			mu.label(ctx, fmt.tprintf("%f, %f", player.pos.x, player.pos.y))
			mu.label(ctx, "Speed:")
			mu.label(ctx, fmt.tprintf("%f", player_get_speed(player)))
			mu.label(ctx, "Size:")
			mu.label(ctx, fmt.tprintf("%f", player.size))

			mu.label(ctx, "Toggle Cursor Line")
			mu.checkbox(ctx, "", &g_mem.debugInfo.showLineToCursor)
		}
	}
	// if mu.window(ctx, "Test Window", {350, 40, 200, 200}, opts) {

	// 	if .ACTIVE in mu.header(ctx, "Window Info") {
	// 		win := mu.get_current_container(ctx)
	// 		mu.layout_row(ctx, {54, -1}, 0)
	// 		mu.label(ctx, "Position:")
	// 		mu.label(ctx, fmt.tprintf("%d, %d", win.rect.x, win.rect.y))
	// 		mu.label(ctx, "Size:")
	// 		mu.label(ctx, fmt.tprintf("%d, %d", win.rect.w, win.rect.h))
	// 	}

	// if .ACTIVE in mu.header(ctx, "Window Options") {
	// 	mu.layout_row(ctx, {120, 120, 120}, 0)
	// 	for opt in mu.Opt {
	// 		state := opt in opts
	// 		if .CHANGE in mu.checkbox(ctx, fmt.tprintf("Label: %v", opt), &state) {
	// 			if state {
	// 				opts += {opt}
	// 			} else {
	// 				opts -= {opt}
	// 			}
	// 		}
	// 	}
	// }
	// }
}

mu_draw :: proc() {
	rl.BeginScissorMode(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight())
	defer rl.EndScissorMode()

	render_texture :: proc(rect: mu.Rect, pos: [2]i32, color: mu.Color) {
		source := rl.Rectangle{f32(rect.x), f32(rect.y), f32(rect.w), f32(rect.h)}
		position := rl.Vector2{f32(pos.x), f32(pos.y)}

		rl.DrawTextureRec(g_mem.mu_state.atlas_texture, source, position, transmute(rl.Color)color)
	}
	command_backing: ^mu.Command
	for variant in mu.next_command_iterator(&g_mem.mu_state.mu_ctx, &command_backing) {
		switch cmd in variant {
		case ^mu.Command_Text:
			pos := [2]i32{cmd.pos.x, cmd.pos.y}
			for ch in cmd.str do if ch & 0xc0 != 0x80 {
				r := min(int(ch), 127)
				rect := mu.default_atlas[mu.DEFAULT_ATLAS_FONT + r]
				render_texture(rect, pos, cmd.color)
				pos.x += rect.w
			}
		case ^mu.Command_Rect:
			rl.DrawRectangle(
				cmd.rect.x,
				cmd.rect.y,
				cmd.rect.w,
				cmd.rect.h,
				transmute(rl.Color)cmd.color,
			)
		case ^mu.Command_Icon:
			rect := mu.default_atlas[cmd.id]
			x := cmd.rect.x + (cmd.rect.w - rect.w) / 2
			y := cmd.rect.y + (cmd.rect.h - rect.h) / 2
			render_texture(rect, {x, y}, cmd.color)
		case ^mu.Command_Clip:
			rl.EndScissorMode()
			rl.BeginScissorMode(cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h)
		case ^mu.Command_Jump:
			unreachable()
		}
	}

}
