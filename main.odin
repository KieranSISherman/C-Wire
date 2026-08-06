package main

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

/*
Sidebar :: struct {
	camera: rl.Camera2D,
	show: bool,
	display: string,
}
*/

App :: struct {
	screen: [2]i32,
	nextId: i32,
	camera: rl.Camera2D,
	sidebar: Sidebar,
	nodes: NodeLayers,
	mouse: Mouse,
	keyboard: Keyboard,
}

font: rl.Font

/*
drawSidebar :: proc(app: ^App) {
	if app.mouse.selected == nil {return}

	rl.BeginScissorMode(i32(app.mouse.selected.pos.x + app.mouse.selected.size.x), i32(app.mouse.selected.pos.y), 100, i32(app.mouse.selected.size.y))
	rl.BeginMode2D(app.sidebar.camera)

	rl.ClearBackground({40,40,40,255})
	rl.DrawRectangleRounded({app.mouse.selected.pos.x + app.mouse.selected.size.x, app.mouse.selected.pos.y, 100, app.mouse.selected.size.y}, 0.2, 1, {90,90,90,255})

	rl.EndMode2D()
	rl.EndScissorMode()
}
*/

draw :: proc(app: ^App) {

	rl.BeginDrawing()

	rl.ClearBackground(rl.WHITE)
	
	rl.BeginMode2D(app.camera)
	rl.ClearBackground({40,40,40,255})
	
	for n in app.nodes.bottom {
		drawNode(n)
	}
	for n in app.nodes.top {
		drawNode(n)
	}
	if app.sidebar.show {drawSidebar(app)}

	rl.EndMode2D()
	rl.EndDrawing()
}

update :: proc(app: ^App) {
	app.screen = {rl.GetScreenWidth(), rl.GetScreenHeight()}

	mouseEvents(app)
	keyboardEvents(app)
}

main :: proc() {

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			else {
				fmt.println("=== No Memory Leaks Found ===")
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
	
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(1280, 720, "C-Wire")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	font = rl.LoadFontEx("assets/fonts/mplus-1m-medium.ttf", 32, nil, 0)
	defer rl.UnloadFont(font)

	app := App {
		screen = {1280, 720},
		nextId = 0,
		camera = rl.Camera2D {
			target = {0, 0},
			offset = {0, 0},
			zoom = 1,
		},
		mouse = {
			/*
			clicked = 0,
			delta = {0, 0},
			dragging = false,
			selected = nil,
			cornerDelta = {0, 0},
			pos = {0, 0},
			*/
			clicked = 0,
			delta = {0, 0},
			pos = {0, 0},
			selected = {
				dragging = false,
				cornerDelta = {0, 0},
				value = nil,
			}
		},
		keyboard = {
			timeWait = 0,
		},
		sidebar = {
			camera = rl.Camera2D {
				target = {0,0},
				offset = {0,0},
				zoom = 1,
			},
			show = false,
			display = "",
			search = "",
			width = 175,
			height = 350,
			scrollOffset = 0,
			maxScroll = 0,
			createSearch = make([dynamic]rune),
			staticPos = {-1,-1},
		}
	}
/*
	var: Node = {
		id = 0,
		nodeType = "new var",
		name = {},
		type = {},
		arrayLen = {},
		isArray = false,
		newModPos = {20, 215},
		value = make([dynamic]rune),
		pos = {15,15},
		size = {200, 310},
		format = varFormat(),
		selectedEl = "",
	}

	var2: Node = {
		id = 1,
		nodeType = "New Var",
		name = {},
		type = {},
		value = make([dynamic]rune),
		arrayLen = {},
		isArray = false,
		newModPos = {20, 215},
		pos = {30,30},
		size = {200,310},
		format = varFormat(),
		selectedEl = "",
	}

	append(&app.nodes.bottom, var)
	append(&app.nodes.bottom, var2)
*/
	for !rl.WindowShouldClose() {
		update(&app)
		draw(&app)
	}
	for &n in app.nodes.top {freeNode(&n)}
	for &n in app.nodes.bottom {freeNode(&n)}
	delete(app.nodes.top)
	delete(app.nodes.bottom)

	delete(app.sidebar.createSearch)
	delete(importedTypes)
	delete(userVarTypes)
}
