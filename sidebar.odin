package main

import "core:fmt"
import rl "vendor:raylib"
import "core:unicode/utf8"
import "core:strings"

// Variable Data
builtinTypes: []cstring : {"int", "float", "char", "bool", "double", "short", "long", "long long"}
importedTypes: [dynamic]cstring = {}
userVarTypes: [dynamic]cstring = {}
varMods: []cstring = {"pointer", "*", "const", "signed", "unsigned", "auto", "static", "volatile", "restrict", "_Atomic", "extern", "register", "_Thread_local", "_Alignas"}

// Unary Operator Data
unaryMutation: []cstring : {"x++", "x--", "++x", "--x"}
unaryPointers: []cstring : {"&", "address-of", "*", "dereference"}
unaryCompileTime: []cstring : {"sizeof", "_Alignof"}
unaryLogic: []cstring : {"!"}
unaryBitwise: []cstring : {"~"}

// Binary Operator Data
bitwiseOps: []cstring : {"&", "|", "^", "<<", ">>"}
assignOps: []cstring : {"=", "+=", "-=", "*=", "/=", "%=", "<<=", ">>=", "&=", "|=", "^="}
arithOps: []cstring : {"+", "-", "*", "/", "%"}
logicOps: []cstring : {"&&", "||"}
compOps: []cstring : {"==", "!=", "<", ">", "<=", ">="}

// Ternary Operator Data
ternaryOp: cstring : "?"

// Node Creation Data
variableNodes: []cstring : {"new var", "var", "index"}
operatorNodes: []cstring : {"unary op", "binary op", "ternary op"}

Sidebar :: struct {
	camera: rl.Camera2D,
	show: bool,
	display: string,
	search: string,
	width: i32,
	height: i32,
	scrollOffset: i32,
	maxScroll: i32,
	createSearch: [dynamic]rune,
	staticPos: rl.Vector2,
}

drawSidebar :: proc(app: ^App) {
	app := app
	//fmt.println(app.sidebar.staticPos)
	if app.mouse.selected == nil {//|| app.sidebar.display == "create" {
		drawCreateNodes(app)		
		return
	}
	app.sidebar.staticPos = {-1,-1}

	sidebarX := i32(app.mouse.selected.pos.x + app.mouse.selected.size.x + 5)
	//sidebarWidth: i32 = 175
	node := app.mouse.selected
	sidebar := app.sidebar

	app.sidebar.camera.offset = {f32(sidebarX), f32(node.pos.y)}

	rl.BeginScissorMode(sidebarX, i32(node.pos.y), sidebar.width, sidebar.height)
	rl.BeginMode2D(app.sidebar.camera)

	rl.ClearBackground({40,40,40,255})
	rl.DrawRectangleRounded({0,0,f32(sidebar.width),f32(sidebar.height)}, 0.2, 1, {90,90,90,255})
	rl.DrawRectangleRounded({2,2,f32(sidebar.width)-4,f32(sidebar.height)-4}, 0.2, 1, {60,60,60,255})

	rl.BeginScissorMode(sidebarX+5, i32(node.pos.y)+5, sidebar.width-10, sidebar.height-10)
	drawSidebarContent(app)
	rl.EndScissorMode()

	rl.EndMode2D()
	rl.EndScissorMode()
}

drawSidebarContent :: proc(app: ^App) {
	app := app
	switch app.sidebar.display {
		// Var
		case "varType":
			drawVarTypes(app)
		case "varMods":
			drawVarMods(app)

		// Unary ops
		case "unOp":
			drawUnOps(app)
		
		// Binary Ops
		case "binOp":
			drawBinOps(app)
	}
}

drawCreateNodes :: proc(app: ^App) {
	pos: rl.Vector2
	if app.sidebar.staticPos.x == -1 {
		pos = app.mouse.pos
		app.sidebar.staticPos = pos
	}
	else {pos = app.sidebar.staticPos}

	width := app.sidebar.width
	height := app.sidebar.height
	search: cstring = strings.clone_to_cstring(utf8.runes_to_string(app.sidebar.createSearch[:]))
	defer delete(search)

	app.sidebar.camera.offset = pos
	rl.BeginScissorMode(i32(pos.x), i32(pos.y), width, height)
	rl.BeginMode2D(app.sidebar.camera)

	rl.ClearBackground({40,40,40,255})
	rl.DrawRectangleRounded({0,0,f32(width),350}, 0.2, 1, {90,90,90,255})
	rl.DrawRectangleRounded({2,2,f32(width-4),346}, 0.2, 1, {60,60,60,255})
	rl.DrawRectangle(8, 20, width-16, 25, {80,80,80,255})

	rl.DrawText(search, 13, 25, 19, {235,235,235,255})

	rl.BeginScissorMode(i32(pos.x+5), i32(pos.y+50), width-10, height-10)

	// Draw Content
	drawPos: rl.Vector2 = {10, 55+f32(app.sidebar.scrollOffset)}
	rl.DrawText("Variables", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0,25}
	for node in variableNodes {
		if search != "" && !strings.contains(string(node), string(search)) {continue}
		rl.DrawText(node, i32(drawPos.x+10), i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0,23}
	}

	drawPos += {0,25}
	rl.DrawText("Operators", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0,25}
	for node in operatorNodes {
		if search != "" && !strings.contains(string(node), string(search)) {continue}
		rl.DrawText(node, i32(drawPos.x+10), i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0,23}
	}

	rl.EndScissorMode()

	rl.EndMode2D()
	rl.EndScissorMode()
}

drawVarTypes :: proc(app: ^App) {
	if app.mouse.selected == nil {return}
	sidebar := app.sidebar
	data := cast(^VarData)app.mouse.selected.data
	search: string = utf8.runes_to_string(data.type[:])
	scrollHeight: i32 = i32(app.mouse.selected.size.y-10)

	
	/*
	if search != "" {
		return
	}
	*/

	drawPos: rl.Vector2 = {10,f32(15+sidebar.scrollOffset)}
	rl.DrawText("Built-in Types", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for type in builtinTypes {
		if search != "" && !strings.contains(string(type), search) {continue}
		rl.DrawText(type, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}
	
	drawPos += {0, 25}
	rl.DrawText("User Types", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for type in userVarTypes {
		if search != "" && !strings.contains(string(type), search) {continue}
		rl.DrawText(type, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}

	drawPos += {0, 25}
	rl.DrawText("Imported Types", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for type in importedTypes {
		if search != "" && !strings.contains(string(type), search) {continue}
		rl.DrawText(type, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}

	sidebar.maxScroll = (i32(drawPos.y) - sidebar.scrollOffset - scrollHeight)*-1
	//fmt.println(sidebar.maxScroll)
}

drawVarMods :: proc(app: ^App) {
	if app.mouse.selected == nil {return}
	sidebar := app.sidebar
	data := cast(^VarData)app.mouse.selected.data
	search: string = utf8.runes_to_string(data.modSearch[:])
	sidebarHeight: i32 = i32(app.mouse.selected.size.y-10)

	drawPos: rl.Vector2 = {10,f32(15+sidebar.scrollOffset)}
	for mod in varMods {
		if search != "" && !strings.contains(string(mod), search) {continue}
		rl.DrawText(mod, i32(drawPos.x), i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}
	sidebar.maxScroll = (i32(drawPos.y) - sidebar.scrollOffset - sidebarHeight)*-1
}

drawUnOps :: proc(app: ^App) {
	if app.mouse.selected == nil {return}
	sidebar := app.sidebar
	data := cast(^UnaryOpData)app.mouse.selected.data
	search: string = utf8.runes_to_string(data.operation[:])
	scrollHeight: i32 = i32(app.mouse.selected.size.y-10)
	
	drawPos: rl.Vector2 = {10,f32(15+sidebar.scrollOffset)}
	rl.DrawText("Unary Mutation", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for op in unaryMutation {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}

	drawPos += {0, 25}
	rl.DrawText("Unary Logic", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for op in unaryLogic {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0,23}
	}

	drawPos += {0, 25}
	rl.DrawText("Unary Pointers", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for op in unaryPointers {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0,24}
	}

	drawPos += {0, 25}
	rl.DrawText("Unary Bitwise", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,225})
	drawPos += {0, 25}
	for op in unaryBitwise {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0,23}
	}

	drawPos += {0, 25}
	rl.DrawText("Compile Time", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for op in unaryCompileTime {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0,23}
	}
	sidebar.maxScroll = (i32(drawPos.y) - sidebar.scrollOffset - scrollHeight)*-1
}

drawBinOps :: proc(app: ^App) {
	if app.mouse.selected == nil {return}
	sidebar := app.sidebar
	data := cast(^BinaryOpData)app.mouse.selected.data
	search: string = utf8.runes_to_string(data.operation[:])
	scrollHeight: i32 = i32(app.mouse.selected.size.y-10)

	drawPos: rl.Vector2 = {10,f32(15+sidebar.scrollOffset)}
	rl.DrawText("Assignment Ops", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for op in assignOps {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}

	drawPos += {0, 25}
	rl.DrawText("Comparison Ops", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for op in compOps {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}

	drawPos += {0, 25}
	rl.DrawText("Logic Ops", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for op in logicOps {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}

	drawPos += {0, 25}
	rl.DrawText("Arithmetic Ops", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for op in arithOps {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}

	drawPos += {0, 25}
	rl.DrawText("Bitwise Ops", i32(drawPos.x), i32(drawPos.y), 19, {235,235,235,255})
	drawPos += {0, 25}
	for op in bitwiseOps {
		if search != "" && !strings.contains(string(op), search) {continue}
		rl.DrawText(op, i32(drawPos.x)+10, i32(drawPos.y), 17, {235,235,235,255})
		drawPos += {0, 23}
	}
	sidebar.maxScroll = (i32(drawPos.y) - sidebar.scrollOffset - scrollHeight)*-1
}
