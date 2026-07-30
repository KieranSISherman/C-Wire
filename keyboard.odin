package main

import "core:fmt"
import rl "vendor:raylib"
import "core:unicode/utf8"

Keyboard :: struct {
	timeWait: i32,
}

keyboardEvents :: proc(app: ^App) {
	databox: ^[dynamic]rune
	if app.mouse.selected == nil {
		if app.sidebar.show == true {
			databox = &app.sidebar.createSearch
		}
		else {return}
	}
	else {databox = getDatabox(app.mouse.selected)}

	if databox == nil {return}

	key := rl.GetCharPressed()
	for key != 0 {
		append(databox, key)
		key = rl.GetCharPressed()
	}
	if key == 0 && rl.IsKeyPressed(.BACKSPACE) && len(databox) > 0 {
		pop(databox)
	}
	else if rl.IsKeyDown(.BACKSPACE) {
		if app.keyboard.timeWait > 30 && len(databox) > 0 {
			pop(databox)
		}
		else {
			app.keyboard.timeWait += 1
		}
	}
	else if rl.IsKeyPressed(.ENTER) {
		if app.mouse.selected != nil && app.mouse.selected.nodeType == .NEWVAR && app.mouse.selected.selectedEl == "varModSearch" {
			node := app.mouse.selected
			data := cast(^VarData)node.data
			format := cast(^VarFormat)node.format
			addVarMod(data, format)
		}
		else if app.mouse.selected == nil && app.sidebar.show == true {
			nodeString: = utf8.runes_to_string(app.sidebar.createSearch[:])
			fmt.println("new = ", nodeString)
			nodeType := stringToNodeType(nodeString)
			fmt.println("new = ", nodeType)
			createNode(nodeType, app)//, app.sidebar.staticPos, app.nextId)
			app.sidebar.show = false
			clear(&app.sidebar.createSearch)
		}
	}
	else if key == 0 && !rl.IsKeyDown(.BACKSPACE) {
		app.keyboard.timeWait = 0
	}
}

getDatabox :: proc(node: ^Node) -> ^[dynamic]rune {
	switch node.nodeType {
	case .NONE: return nil
	case .NEWVAR:
		return getNewVarDatabox(node)
	case .VAR:
		return nil
	case .INDEX:
		return nil
	case .UNARYOP:
		return getUnOpDatabox(node)
	case .BINARYOP:
		return getBinOpDatabox(node)
	case .TERNARYOP:
		return nil
	}
	return nil
}

getNewVarDatabox :: proc(node: ^Node) -> ^[dynamic]rune {
	data := cast(^VarData)node.data
	switch node.selectedEl {
		case "varName":
			return &data.name
		case "varType":
			return &data.type
		case "varModSearch":
			return &data.modSearch
		case "varValue":
			#partial switch &type in data.value {
			case [dynamic]rune:
				return &type
			}
		case "varArrayLen":
			if data.isArray {return &data.arrayLen}
	}
	return nil
}

getUnOpDatabox :: proc(node: ^Node) -> ^[dynamic]rune {
	data := cast(^UnaryOpData)node.data
	if node.selectedEl == "unOp" {
		return &data.operation
	}
	return nil
}

getBinOpDatabox :: proc(node: ^Node) -> ^[dynamic]rune {
	data := cast(^BinaryOpData)node.data
	if node.selectedEl == "binOp" {
		return &data.operation
	}
	return nil
}
