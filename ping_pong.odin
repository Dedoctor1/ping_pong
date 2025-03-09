package ping_pong

import "core:fmt"
import "core:time"
import "vendor:sdl2"

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
}

Player :: struct {
	x:      f32,
	y:      f32,
	points: u8,
	width:  f32,
	height: f32,
}

Type :: union {
	Player,
	Ball,
}

render :: proc(entity: Type, renderer: ^sdl2.Renderer) {
	rect: sdl2.FRect

	switch s in entity {
	case Ball:
		rect = sdl2.FRect {
			x = s.x,
			y = s.y,
			w = s.diameter,
			h = s.diameter,
		}
	case Player:
		rect = sdl2.FRect {
			x = s.x,
			y = s.y,
			w = s.width,
			h = s.height,
		}
	}


	_ = sdl2.SetRenderDrawColor(renderer, 255, 255, 255, 0)
	_ = sdl2.RenderFillRectF(renderer, &rect)
	_ = sdl2.RenderDrawRectF(renderer, &rect)

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
	}

	player_left := Player {
		x      = 0,
		y      = 0,
		points = 0,
		width  = 50,
		height = 140,
	}

	player_right := Player {
		x      = f32(current_width) - 50,
		y      = 0,
		points = 0,
		width  = 50,
		height = 140,
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

		if (ball.x + ball.diameter == f32(current_width)) {
			//TODO: End the round
			ball.x_direction = .left
		} else if (ball.x == 0) {
			//TODO: End the round
			ball.x_direction = .right
		}

		if (ball.x_direction == .right) {
			ball.x += 1
		} else {
			ball.x -= 1
		}

		if (ball.y + ball.diameter == f32(current_height)) {
			ball.y_direction = .down
		} else if (ball.y == 0) {
			ball.y_direction = .up
		}

		if (ball.y_direction == .down) {
			ball.y -= 1
		} else {
			ball.y += 1
		}

		render(ball, renderer)
		render(player_left, renderer)
		render(player_right, renderer)

		sdl2.RenderPresent(renderer)
	}
}
