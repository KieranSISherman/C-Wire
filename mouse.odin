package main

import "core:fmt"
import rl "vendor:raylib"

Mouse :: struct {
	clicked: i32, // 0 = none, 1 = left, 2 = right
	delta: rl.Vector2,
	dragging: bool,
	selected: ^Node,
	cornerDelta: rl.Vector2,
	pos: rl.Vector2,
}

mouseEvents :: proc(app: ^App) {
	app.mouse.pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), app.camera)

	mousePos := app.mouse.pos
	selected := app.mouse.selected

	if rl.IsMouseButtonDown(.LEFT) {
		if app.mouse.dragging && selected != nil {
			selected.pos = mousePos - app.mouse.cornerDelta
			selected.selectedEl = ""
			
		}
		else if app.mouse.clicked == 1 {
			app.mouse.delta += rl.GetMouseDelta()
			if abs(app.mouse.delta.x) > 5 || abs(app.mouse.delta.y) > 5 {
				app.mouse.dragging = true
				app.sidebar.show = false	
			}
		}
		else {
			app.mouse.clicked = 1
			app.sidebar.show = false
			if selected != nil {selected.selectedEl = ""}
			getSelected(app)
		}
	}
	else if rl.IsMouseButtonDown(.RIGHT) {
		app.mouse.clicked = 2
	}
	else {
		if app.mouse.clicked == 1 && !app.mouse.dragging {
			if app.mouse.selected != nil {
				selected.selectedEl = getSelectedElement(selected, mousePos)
				fmt.println(app.mouse.selected.selectedEl)
				clickUpdate(app)
			}
		}
		if app.mouse.clicked == 2 {
			// right click
			getSelected(app)
			if selected == nil {
				app.sidebar.show = true
				app.sidebar.staticPos = {-1,-1}
			}
		}
		app.mouse.clicked = 0
		app.mouse.delta = {0, 0}
		app.mouse.dragging = false
	}
	scroll := rl.GetMouseWheelMove()
	if scroll != 0 {//&& app.mouse.selected != nil {
		sidebarRec: rl.Rectangle

		if app.mouse.selected == nil {
			pos := app.sidebar.staticPos
			width := f32(app.sidebar.width)
			height := f32(app.sidebar.height)
			sidebarRec = {pos.x, pos.y, width, height}
		}
		else {
			sidebarX := selected.pos.x + selected.size.x + 5
			selY := selected.pos.y
			sideW := f32(app.sidebar.width)
			selH := f32(app.sidebar.height)
			sidebarRec = {sidebarX, selY, sideW, selH}
		}

		if rl.CheckCollisionPointRec(mousePos, sidebarRec) {
			if (app.sidebar.scrollOffset >= 0 && scroll > 0) {}
			else {
				app.sidebar.scrollOffset += i32(scroll*20)
				//fmt.println(app.sidebar.scrollOffset)
				/*
				if app.sidebar.scrollOffset < app.sidebar.maxScroll {
					//app.sidebar.scrollOffset = app.sidebar.maxScroll
				}
				*/
			}
		}
		/*
		else {
			fmt.println(scroll)
			app.camera.zoom += (scroll*0.2)
		}
		*/
	}
}

clickUpdate :: proc(app: ^App) {
	app := app
	if app.mouse.selected == nil {return}
	node := app.mouse.selected
	app.sidebar.show = false

	switch node.selectedEl {
	// Var
		case "varType":
			app.sidebar.show = true
			app.sidebar.scrollOffset = 0
			app.sidebar.display = "varType"
		case "varMods":
			removeVarMod(app) 
			return
		case "varModSearch":
			app.sidebar.show = true
			app.sidebar.scrollOffset = 0
			app.sidebar.display = "varMods"
		case "varArray":
			data := cast(^VarData)node.data
			data.isArray = !data.isArray
			return

		// Unary Op
		case "unOp":
			app.sidebar.show = true
			app.sidebar.scrollOffset = 0
			app.sidebar.display = "unOp"

		// Binary Op
		case "binOp":
			app.sidebar.show = true
			app.sidebar.scrollOffset = 0
			app.sidebar.display = "binOp"
		
	}
}

getSelected :: proc(app: ^App) {
	mouse := rl.GetScreenToWorld2D(rl.GetMousePosition(), app.camera)

	for i in 0..<len(app.nodes.top){
		node := &app.nodes.top[i]

		rect: rl.Rectangle = {
			x = node.pos.x,
			y = node.pos.y,
			width = node.size.x,
			height = node.size.y
		}

		if rl.CheckCollisionPointRec(mouse, rect) {
			app.mouse.selected = node
			app.mouse.cornerDelta = mouse - node.pos
			return
		}
	}
	for i in 0..<len(app.nodes.bottom) {
		node := &app.nodes.bottom[i]

		rect: rl.Rectangle = {
			x = node.pos.x,
			y = node.pos.y,
			width = node.size.x,
			height = node.size.y
		}

		if rl.CheckCollisionPointRec(mouse, rect) {
			app.mouse.selected = node
			app.mouse.cornerDelta = mouse - node.pos
			return
		}
	}

	if len(app.sidebar.createSearch) > 0 {clear(&app.sidebar.createSearch)}
	if app.mouse.selected == nil {return}
	app.mouse.selected.selectedEl = ""
	app.mouse.selected = nil
}

getSelectedElement :: proc(node: ^Node, mouse: rl.Vector2) -> string {
	#partial switch node.nodeType {
	case .NEWVAR:
		return getSelectedVarElement(node, mouse)
	case .UNARYOP:
		return getSelectedUnaryOpElement(node, mouse)
	case .BINARYOP:
		return getSelectedBinaryOpElement(node, mouse)
	}
	return "None"
}

getSelectedVarElement :: proc(node: ^Node, mouse: rl.Vector2) -> string {
	format := cast(^VarFormat)node.format
	if inElement(node.pos, format.name, mouse) {return "varName"}
	if inElement(node.pos, format.value, mouse) {return "varValue"}

	if inElement(node.pos, format.type, mouse) {return "varType"}
	if inElement(node.pos, format.mods, mouse) {return "varMods"}
	if inElement(node.pos, format.modSearch, mouse) {return "varModSearch"}
	if inElement(node.pos, format.array, mouse) {return "varArray"}

	if inElement(node.pos, format.arrayLen, mouse) {return "varArrayLen"}
	if inElement(node.pos, format.topConn, mouse) {return "varTopConn"}
	if inElement(node.pos, format.leftConn, mouse) {return "varLeftConn"}
	if inElement(node.pos, format.bottomConn, mouse) {return "varBottomConn"}
	//if inElement(node.pos, format.rightConn, mouse) {return "varRightConn"}
	if inElement(node.pos, format.nextConn, mouse) {return "varNextConn"}

	return "None"
}

getSelectedUnaryOpElement :: proc(node: ^Node, mouse: rl.Vector2) -> string {
	format := cast(^UnaryOpFormat)node.format
	if inElement(node.pos, format.operation, mouse) {return "unOp"}
	if inElement(node.pos, format.topConn, mouse) {return "unTopConn"}
	if inElement(node.pos, format.leftConn, mouse) {return "unLeftConn"}
	if inElement(node.pos, format.bottomConn, mouse) {return "unBottomConn"}
	if inElement(node.pos, format.nextConn, mouse) {return "unNextConn"}

	return "None"
}

getSelectedBinaryOpElement :: proc(node: ^Node, mouse: rl.Vector2) -> string {
	format := cast(^BinaryOpFormat)node.format
	if inElement(node.pos, format.operation, mouse) {return "binOp"}
	if inElement(node.pos, format.topConn, mouse) {return "binTopConn"}
	if inElement(node.pos, format.leftConn, mouse) {return "binLeftConn"}
	if inElement(node.pos, format.botLeftConn, mouse) {return "binBotLeftConn"}
	if inElement(node.pos, format.botRightConn, mouse) {return "binBotRightConn"}
	if inElement(node.pos, format.nextConn, mouse) {return "binNextConn"}

	return "None"
}

inElement :: proc(point: rl.Vector2, el: rl.Rectangle, mouse: rl.Vector2) -> bool {
	rec := el
	rec.x += point.x
	rec.y += point.y
	if rl.CheckCollisionPointRec(mouse, rec) {return true}
	return false
}

removeVarMod :: proc(app: ^App) {
	if app.mouse.selected == nil {return}
	node := app.mouse.selected
	data := cast(^VarData)node.data

	for mod, idx in data.mods {
		if rl.CheckCollisionPointRec(app.mouse.pos, {node.pos.x+mod.rec.x, node.pos.y+mod.rec.y, mod.rec.width, mod.rec.height}) {
			ordered_remove(&data.mods, idx)
		}
	}

	if len(data.mods) == 0 {
		data.newModPos = {20, 215}
		return
	}
	prevModRec := data.mods[len(data.mods)-1].rec
	data.newModPos = {prevModRec.x, prevModRec.y}
	return
}
