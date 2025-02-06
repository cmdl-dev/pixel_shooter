package game

import "core:math"
import rl "vendor:raylib"

GetScreenDimension :: proc() -> Vec2 {
	return {f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
}
GetCameraScreenDimension :: proc(camera: rl.Camera2D) -> Vec2 {
	dim := GetScreenDimension()
	nPos := rl.GetScreenToWorld2D({dim.x, dim.y}, camera)
	return nPos
}

Screen_Pos :: enum {
	Top_Right,
	Bottom_Left,
	Center_Center,
	Center_Left,
}


getScreenPos :: proc(
	pos: Screen_Pos,
	size: Vec2,
	camera: rl.Camera2D = rl.Camera2D{zoom = 1},
) -> Rect {
	screenDim := GetCameraScreenDimension(camera)

	switch pos {
	case .Top_Right:
		return {x = screenDim.x - size.x, y = 0, width = size.x, height = size.y}
	case .Bottom_Left:
		return {x = 0, y = screenDim.y - size.y, width = size.x, height = size.y}
	case .Center_Center:
		return {x = screenDim.x / 2, y = screenDim.y / 2 - size.y, width = size.x, height = size.y}
	case .Center_Left:
		return {x = 0, y = (screenDim.y / 2) - size.y, width = size.x, height = size.y}
	}
	return Rect{}
}

onFrameDelay :: proc {
	onFrameDelayNoArgs,
	onFrameDelayWithArgs,
}

onFrameDelayNoArgs :: proc(timer: ^f32, maxTimer: f32, cb: proc()) {
	dt := rl.GetFrameTime()

	timer^ += dt
	if timer^ >= maxTimer {
		timer^ = 0.0
		cb()
	}
}
onFrameDelayWithArgs :: proc(timer: ^f32, maxTimer: f32, cb: proc(_: $T), args: T) {
	dt := rl.GetFrameTime()

	timer^ += dt
	if timer^ >= maxTimer {
		timer^ = 0.0
		cb(args)
	}
}
rotateVector :: proc(v: Vec2, angle: f32) -> Vec2 {

	rad := angle * math.RAD_PER_DEG
	cosA := math.cos(rad)
	sinA := math.sin(rad)

	return Vec2{v.x * cosA - v.y * sinA, v.x * sinA + v.y * cosA}
}
