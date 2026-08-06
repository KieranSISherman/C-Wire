package main

import "core:fmt"
import rl "vendor:raylib"

SelectionType :: union {
	^Node,
	^Wire,
}

Selection :: struct {
	dragging: bool,
	cornerDelta: rl.Vector2,
	value: SelectionType
}

Mouse :: struct {
	clicked: i32, // 0 = none, 1 = left, 2 = right
	delta: rl.Vector2,
	pos: rl.Vector2,
	selected: Selection,
	wireConns: [2]^Connection,
}

mouseEvents :: proc(app: ^App) {
	app.mouse.pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), app.camera)

	mouse := &app.mouse
	selected := &app.mouse.selected

	if rl.IsMouseButtonDown(.LEFT) {
		if selected.dragging {drag(mouse)}
		else if mouse.clicked == 1 {checkDrag(app)}
		else {
			mouse.clicked = 1
			if node, ok := selected.value.(^Node); ok {node.selectedEl = ""}
			if selected.value == nil {
				selected.value, selected.cornerDelta = getSelected(app)
			}
		}
	}
	else if rl.IsMouseButtonDown(.RIGHT) {
		mouse.clicked = 2
	}
	else {
		if mouse.clicked == 1 {leftClick(app)}
		else if mouse.clicked == 2 {
			rightClick(app)
		}

		mouse.clicked = 0
		mouse.delta = {0, 0}
		mouse.selected.dragging = false
	}

	scroll := rl.GetMouseWheelMove()
	if scroll != 0 {scrollEvent(app, scroll)}
}

scrollEvent :: proc(app: ^App, scroll: f32) {
	sidebarRec: rl.Rectangle
	selected := app.mouse.selected.value

	if selected == nil {
		pos := app.sidebar.staticPos
		width := f32(app.sidebar.width)
		height := f32(app.sidebar.height)
		sidebarRec = {pos.x, pos.y, width, height}
	}
	else if node, ok := selected.(^Node); ok {
		sidebarX := node.pos.x + node.size.x + 5
		sidebarY := node.pos.y
		width := f32(app.sidebar.width)
		height := f32(app.sidebar.height)
		sidebarRec = {sidebarX, sidebarY, width, height}
	}

	if rl.CheckCollisionPointRec(app.mouse.pos, sidebarRec) {
		if app.sidebar.scrollOffset >= 0 && scroll > 0 {}
		else {
			app.sidebar.scrollOffset += i32(scroll*20)
		}
	}

	if app.sidebar.scrollOffset < app.sidebar.maxScroll {
		//	
	}
}

drag :: proc(mouse: ^Mouse) {
	if node, ok := mouse.selected.value.(^Node); !ok {return}
	mouse.selected.value.(^Node).pos = mouse.pos - mouse.selected.cornerDelta
	mouse.selected.value.(^Node).selectedEl = ""
}

checkDrag :: proc(app: ^App) {
	app.mouse.delta = rl.GetMouseDelta()
	if abs(app.mouse.delta.x) > 5 || abs(app.mouse.delta.y) > 5 {
		app.mouse.selected.dragging = true
		app.sidebar.show = false
	}
}

leftClick :: proc(app: ^App) {
	selected := &app.mouse.selected
	app.sidebar.show = false
	selected.value, selected.cornerDelta = getSelected(app)
	//fmt.println(selected)

	if node, ok := selected.value.(^Node); ok {
		conn: ^Connection = nil
		node.selectedEl, conn = getSelectedElement(node, app.mouse.pos)
		//fmt.println(node.selectedEl)

		if conn != nil {
			fmt.println(conn.name)
			clickUpdate(conn, app)
		}
		else {
			fmt.println(node.selectedEl)
			clickUpdate(node, app)
		}
	}
}

rightClick :: proc(app: ^App) {
	selected := &app.mouse.selected
	selected.value, selected.cornerDelta = getSelected(app)
	//fmt.println(selected.value)
	if selected.value == nil {
		// Show menu to create new node
		app.sidebar.show = true
		app.sidebar.staticPos = {-1, -1}
	}
}

/*
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
*/

clickUpdate :: proc {
	clickUpdateNode,
	clickUpdateWire,
	clickUpdateConn,
}

clickUpdateConn :: proc(conn: ^Connection, app: ^App) {
	if node, ok := app.mouse.selected.value.(^Node); !ok {return}
	nodeConns: ^[dynamic]Connection = &app.mouse.selected.value.(^Node).conns

	if app.mouse.wireConns[0] == nil {
		app.mouse.wireConns[0] = conn
	}
	else if app.mouse.wireConns[0] != nil && app.mouse.wireConns[1] == nil {
		if !inSameNode(conn, app.mouse.wireConns[0], nodeConns) {
			app.mouse.wireConns[1] = conn
			createWire(app)
			app.mouse.wireConns[0] = nil
			app.mouse.wireConns[1] = nil
		}
	}
	else {
		app.mouse.wireConns[0] = nil
		app.mouse.wireConns[1] = nil
	}
}

inSameNode :: proc(conn1: ^Connection, conn2: ^Connection, nodeConns: ^[dynamic]Connection) -> bool{
	found: i32 = 0
	for &c in nodeConns {
		if &c == conn1 || &c == conn2 {found += 1}
	}
	if found == 2 {return true}
	return false
}

clickUpdateWire :: proc(wire: ^Wire, app: ^App) {

}

clickUpdateNode :: proc(node: ^Node, app: ^App) {
	app := app
	node := node
	//if _, ok := app.mouse.selected.value.(^Node); !ok {return}
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

getSelected :: proc(app: ^App) -> (SelectionType, rl.Vector2) {
	mouse := rl.GetScreenToWorld2D(rl.GetMousePosition(), app.camera)
	selected := &app.mouse.selected.value

	for i in 0..<len(app.nodes.top){
		node := &app.nodes.top[i]

		rect: rl.Rectangle = {
			x = node.pos.x-5,
			y = node.pos.y-5,
			width = node.size.x+10,
			height = node.size.y+10
		}

		if rl.CheckCollisionPointRec(mouse, rect) {
			/*
			selected = node
			app.mouse.selected.cornerDelta = mouse - node.pos
			*/
			return node, (mouse - node.pos)
		}
	}
	for i in 0..<len(app.nodes.bottom) {
		node := &app.nodes.bottom[i]

		rect: rl.Rectangle = {
			x = node.pos.x-5,
			y = node.pos.y-5,
			width = node.size.x+10,
			height = node.size.y+10
		}

		if rl.CheckCollisionPointRec(mouse, rect) {
			/*
			selected = node
			app.mouse.cornerDelta = mouse - node.pos
			*/
			return node, (mouse - node.pos)
		}
	}

	if len(app.sidebar.createSearch) > 0 {clear(&app.sidebar.createSearch)}
	if node, ok := selected.(^Node); ok {
		node.selectedEl = ""
	}
	return nil, {0,0}
}

getSelectedElement :: proc(node: ^Node, mouse: rl.Vector2) -> (string, ^Connection) {
	#partial switch node.nodeType {
	case .NEWVAR:
		el := getSelectedVarElement(node, mouse)
		if el == "None" {return el, inConnElement(node.pos, node.conns, mouse)}
		return el, nil

	case .UNARYOP:
		el := getSelectedUnaryOpElement(node, mouse)
		if el == "None" {return el, inConnElement(node.pos, node.conns, mouse)}
		return el, nil

	case .BINARYOP:
		el := getSelectedBinaryOpElement(node, mouse)
		if el == "None" {return el, inConnElement(node.pos, node.conns, mouse)}
		return el, nil

	case .TERNARYOP:
		return "None", inConnElement(node.pos, node.conns, mouse)
	}
	return "None", nil
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
	return "None"
}

/*
getSelectedTernaryOpElement :: proc(node: ^Node, mouse: rl.Vector2) -> string {
	format := cast(^TernaryOpFormat)node.format
	if inElement(node.pos, format.topConn, mouse) {return "ternTopConn"}
	if inElement(node.pos, format.leftConn, mouse) {return "ternLeftConn"}
	if inElement(node.pos, format.nextConn, mouse) {return "ternNextConn"}
	if inElement(node.pos, format.condConn, mouse) {return "ternCondConn"}
	if inElement(node.pos, format.expr1Conn, mouse) {return "ternExpr1Conn"}
	if inElement(node.pos, format.expr2Conn, mouse) {return "ternExpr2Conn"}
	return "None"
}
*/

inElement :: proc(point: rl.Vector2, el: rl.Rectangle, mouse: rl.Vector2) -> bool {
	rec := el
	rec.x += point.x
	rec.y += point.y
	if rl.CheckCollisionPointRec(mouse, rec) {return true}
	return false
}

inConnElement :: proc(point: rl.Vector2, conns: [dynamic]Connection, mouse: rl.Vector2) -> ^Connection {
	for &conn in conns {
		rec := conn.format
		rec.x += point.x
		rec.y += point.y
		if rl.CheckCollisionPointRec(mouse, rec) {return &conn}
	}
	return nil
}

removeVarMod :: proc(app: ^App) {
	if _, ok := app.mouse.selected.value.(^Node); !ok {return}
	node := app.mouse.selected.value.(^Node)
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
