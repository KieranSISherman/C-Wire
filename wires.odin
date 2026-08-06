package main

import rl "vendor:raylib"
import "core:fmt"

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
	pos: [2]^Connection,
}

createWire :: proc(app: ^App) {
	//if app.mouse.selected.value == nil {return}
	//if node, ok := app.mouse.selected.value.(^Node); !ok {return}
	//node: ^Node = app.mouse.selected.value.(^Node)
	//fmt.println("Creating Wire")

	conns := app.mouse.wireConns
	if conns[0] == nil || conns[1] == nil {return}

	Pos := app.mouse.pos
	Id := app.nextId
	type: WireType = .NORMAL
	app.nextId += 1

	if conns[0].name == "next" || conns[1].name == "next" {type = .MAIN}

	wire: Wire = {
		id = Id,
		wireType = type,
		pos = {conns[0], conns[1]},
	}

	conns[0].wire = &wire
	conns[1].wire = &wire

	append(&app.wires, wire)
	fmt.println("Wire created")
}

drawWire :: proc(wire: ^Wire) {
	p1: rl.Vector2 = {wire.pos[0].format.x, wire.pos[0].format.y}
	p2: rl.Vector2 = {wire.pos[1].format.x, wire.pos[1].format.y}
	if wire.wireType == .MAIN {rl.DrawLineV(p1, p2, rl.GREEN)}
	else {rl.DrawLineV(p1, p2, {235,235,235,255})}
}

/*
drawWire :: proc(wire: ^Wire) {
	rl.DrawLineV(wire.pos[0], wire.pos[1], {235,235,235,255})
}
*/
