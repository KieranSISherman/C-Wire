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
	pos: rl.Vector2
}
