package main

import rl "vendor:raylib"

WireConnection :: union {
	^Wire,
	^Node,
}

WireType :: enum {
	NORMAL,
	MAIN,
}

Wire :: struct {
	id: i32,
	wireType: WireType,
	pos: [2]rl.Vector2,
}

createWire :: proc(app: ^App) {
	if app.mouse.selected.value == nil {return}
	if node, ok := app.mouse.selected.value.(^Node); !ok {return}
	node: ^Node = app.mouse.selected.value.(^Node)

	Pos := app.mouse.pos
	Id := app.nextId
	type: WireType = .NORMAL
	app.nextId += 1

	wire: Wire = {
		id = Id,
		wireType = type,

	}
}

drawWire :: proc(wire: ^Wire) {
	rl.DrawLineV(wire.pos[0], wire.pos[1], {235,235,235,255})
}
