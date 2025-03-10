package ping_pong

import "core:fmt"
import "core:strconv"
import "core:strings"
import "vendor:sdl2"
import "vendor:sdl2/ttf"

Vertical :: enum {
	up,
	down,
}

Horizontal :: enum {
	left,
	right,
}

Ball :: struct {
	x:           f32,
	y:           f32,
	diameter:    f32,
	x_direction: Horizontal,
	y_direction: Vertical,
	speed:       f32,
}

Player :: struct {
	x:      f32,
	y:      f32,
	points: u64,
	width:  f32,
	height: f32,
	color:  sdl2.Color,
}

PLAYER_SPEED :: 2

Type :: union {
	Player,
	Ball,
}

fg := sdl2.Color {
	r = 255,
	g = 255,
	b = 255,
	a = 255,
}

render :: proc(entity: Type, renderer: ^sdl2.Renderer) {
	rect: sdl2.FRect
	color: sdl2.Color

	switch s in entity {
	case Ball:
		rect = sdl2.FRect {
			x = s.x,
			y = s.y,
			w = s.diameter,
			h = s.diameter,
		}
		color = sdl2.Color {
			r = 255,
			g = 255,
			b = 255,
			a = 255,
		}
	case Player:
		rect = sdl2.FRect {
			x = s.x,
			y = s.y,
			w = s.width,
			h = s.height,
		}
		color = s.color
	}

	_ = sdl2.SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a)
	_ = sdl2.RenderFillRectF(renderer, &rect)
	_ = sdl2.RenderDrawRectF(renderer, &rect)

}

reset_positions :: proc(
	player_left: ^Player,
	player_right: ^Player,
	ball: ^Ball,
	current_width: i32,
	current_height: i32,
) {
	player_left.x = 0
	player_left.y = 0
	player_right.x = f32(current_width) - 50
	player_right.y = 0
	ball.x = f32(current_width) / 2
	ball.y = f32(current_height) / 2
}

control_players :: proc(player_left: ^Player, player_right: ^Player, current_height: i32) {
	keyboard: []u8 = sdl2.GetKeyboardStateAsSlice()

	if b8(keyboard[sdl2.SCANCODE_W]) && player_left.y != 0 {
		player_left.y -= PLAYER_SPEED
	}

	if b8(keyboard[sdl2.SCANCODE_S]) && player_left.y + player_left.height < f32(current_height) {
		player_left.y += PLAYER_SPEED
	}

	if b8(keyboard[sdl2.SCANCODE_UP]) && player_right.y != 0 {
		player_right.y -= PLAYER_SPEED
	}

	if b8(keyboard[sdl2.SCANCODE_DOWN]) &&
	   player_right.y + player_right.height < f32(current_height) {
		player_right.y += PLAYER_SPEED
	}
}

main :: proc() {
	assert(sdl2.Init(sdl2.INIT_VIDEO) == 0, sdl2.GetErrorString())
	defer sdl2.Quit()

	window := sdl2.CreateWindow(
		"Odin Game",
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		640,
		480,
		sdl2.WINDOW_SHOWN,
	)
	assert(window != nil, sdl2.GetErrorString())
	defer sdl2.DestroyWindow(window)

	// Must not do VSync because we run the tick loop on the same thread as rendering.
	renderer: ^sdl2.Renderer = sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
	assert(renderer != nil, sdl2.GetErrorString())
	defer sdl2.DestroyRenderer(renderer)

	current_width: i32
	current_height: i32
	sdl2.GetWindowSize(window, &current_width, &current_height)
	// fmt.println("Height: ", current_height, "Width: ", current_width)

	ball := Ball {
		x           = f32(current_width / 2),
		y           = f32(current_height / 2),
		diameter    = 20,
		y_direction = .up,
		x_direction = .right,
		speed       = 1,
	}

	player_left := Player {
		x = 0,
		y = 0,
		points = 0,
		width = 50,
		height = 140,
		color = sdl2.Color{r = 255, b = 0, g = 0, a = 0},
	}

	player_right := Player {
		x = f32(current_width) - 50,
		y = 0,
		points = 0,
		width = 50,
		height = 140,
		color = sdl2.Color{r = 0, b = 255, g = 0, a = 0},
	}

	for {
		event: sdl2.Event
		for sdl2.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				return
			case .KEYDOWN:
				if event.key.keysym.scancode == sdl2.SCANCODE_ESCAPE {
					return
				}
			}
		}
		sdl2.GetWindowSize(window, &current_width, &current_height)
		player_right.x = f32(current_width) - player_right.width

		_ = sdl2.SetRenderDrawColor(renderer, 0, 0, 0, 0)
		_ = sdl2.RenderClear(renderer)

		_ = ttf.Init()
		font: ^ttf.Font = ttf.OpenFont(
			"/home/quan/Documents/projects/odin/games/ping_pong/freesansbold.ttf",
			40,
		)
		assert(font != nil, string(ttf.GetError()))

		bytes: [1024]byte
		builder := strings.builder_from_bytes(bytes[:])
		strings.write_u64(&builder, player_left.points)
		strings.write_string(&builder, " : ")
		strings.write_u64(&builder, player_right.points)
		text, err := strings.to_cstring(&builder)
		if (err != nil) {
			fmt.println(err)
		}

		font_surf := ttf.RenderText_Blended(font, text, fg)
		ttf.CloseFont(font)
		text_rect: sdl2.FRect = sdl2.FRect {
			x = f32(current_width) / 2 - f32(font_surf.w) / 2,
			y = 0,
			w = f32(font_surf.w),
			h = f32(font_surf.h),
		}

		text_image := sdl2.CreateTextureFromSurface(renderer, font_surf)
		sdl2.FreeSurface(font_surf)
		defer ttf.Quit()

		if (ball.x + ball.diameter == f32(current_width)) {
			player_left.points += 1
			reset_positions(&player_left, &player_right, &ball, current_width, current_height)
			fmt.println(player_left.points, " : ", player_right.points)
		} else if (ball.x == 0) {
			player_right.points += 1
			reset_positions(&player_left, &player_right, &ball, current_width, current_height)
			fmt.println(player_left.points, " : ", player_right.points)
		}


		if (ball.y + ball.diameter == f32(current_height)) {
			ball.y_direction = .up
		} else if (ball.y == 0) {
			ball.y_direction = .down
		}

		if (ball.y_direction == .down) {
			ball.y += ball.speed
		} else {
			ball.y -= ball.speed
		}


		if (ball.y < player_right.y + player_right.height && ball.y > player_right.y) {
			if (ball.x + ball.diameter == player_right.x) {
				ball.x_direction = .left
			}
		}

		if (ball.y < player_left.y + player_left.height && ball.y > player_left.y) {
			if (ball.x == player_left.x + player_left.width) {
				ball.x_direction = .right
			}
		}

		if (ball.x_direction == .right) {
			ball.x += ball.speed
		} else {
			ball.x -= ball.speed
		}

		control_players(&player_left, &player_right, current_height)

		render(ball, renderer)
		render(player_left, renderer)
		render(player_right, renderer)
		_ = sdl2.RenderCopyF(renderer, text_image, nil, &text_rect)
		sdl2.RenderPresent(renderer)
	}
}
