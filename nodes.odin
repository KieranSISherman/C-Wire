package main

import rl "vendor:raylib"
import "core:fmt"

/*
freeNode :: proc(node: ^Node) {
	delete(node.name)
	delete(node.type)
	delete(node.mods)
	delete(node.modSearch)
	delete(node.arrayLen)
	#partial switch &value in node.value {
	case [dynamic]rune:
		delete(value)
	}
}
*/

Mod :: struct {
	rec: rl.Rectangle,
	text: cstring
}

DataValue :: union {
	[dynamic]rune,
	^Node,
}

NodeLayers :: struct {
	top: [dynamic]Node,
	bottom: [dynamic]Node,
}

Node :: struct {
	id: i32,
	nodeType: string,
	topConn: ^Wire,
	bottomConn: ^Wire,
	leftConn: ^Wire,
	nextConn: ^Wire,
	referenceConn: ^Wire,
	/*
	name: [dynamic]rune,
	type: [dynamic]rune,
	mods: [dynamic]Mod,
	modSearch: [dynamic]rune,
	newModPos: rl.Vector2,
	//isPointer: bool,
	isArray: bool,
	arrayLen: [dynamic]rune,
	value: DataValue,
	*/
	data: rawptr,//DataUnion,
	pos: rl.Vector2,
	size: rl.Vector2,
	format: rawptr,//FormatUnion,
	selectedEl: string,
}

/*
DataUnion :: union {
	VarData,
	BinaryOpData,
}

FormatUnion :: union {
	VarFormat,
	BinaryOpFormat,
}
*/

VarData :: struct {
	name: [dynamic]rune,
	type: [dynamic]rune,
	mods: [dynamic]Mod,
	modSearch: [dynamic]rune,
	newModPos: rl.Vector2,
	isArray: bool,
	arrayLen: [dynamic]rune,
	value: DataValue,
}

VarFormat :: struct {
	name: rl.Rectangle,
	value: rl.Rectangle,
	type: rl.Rectangle,
	mods: rl.Rectangle,
	modSearch: rl.Rectangle,
	array: rl.Rectangle,
	arrayLen: rl.Rectangle,
	topConn: rl.Rectangle,
	leftConn: rl.Rectangle,
	bottomConn: rl.Rectangle,
	rightConn: rl.Rectangle,
	nextConn: rl.Rectangle,
}

BinaryOpData :: struct {

}

BinaryOpFormat :: struct {

}

initVarFormat :: proc() -> VarFormat {
	return VarFormat {
		name = {x=65,y=60,width=120,height=20},
		type = {x=65,y=90,width=120,height=20},
		value = {x=65,y=120,width=120,height=20},
		array = {x=100,y=150,width=20,height=20},
		arrayLen = {x=130,y=150,width=55,height=20},
		mods = {x=15,y=210,width=170,height=80},
		modSearch = {x=65,y=180,width=120,height=20},
		topConn = {x=95,y=-6,width=10,height=10},
		leftConn = {x=-3,y=150,width=10,height=10},
		bottomConn = {x=95,y=305,width=10,height=10},
		rightConn = {x=195,y=170,width=10,height=10},
		nextConn = {x=195,y=130,width=10,height=10},
	}
}



createNode :: proc(nodeType: string, app: ^App) {
	switch nodeType {
	case "new var":
		createNewVar(app)
	}
}

createNewVar :: proc(app: ^App) {
	Pos := app.sidebar.staticPos
	Id := app.nextId

	varData := new(VarData)
	varData.name =  make([dynamic]rune)
	varData.type = make([dynamic]rune)
	varData.mods = make([dynamic]Mod)
	varData.modSearch = make([dynamic]rune)
	varData.newModPos = {20, 215}
	varData.isArray = false
	varData.arrayLen = make([dynamic]rune)
	varData.value = make([dynamic]rune)

	varFormat := new(VarFormat)
	varFormat^ = initVarFormat()

	node: Node = {
		id = Id,
		pos = Pos,
		nodeType = "new var",
		size = {200,310},
		selectedEl = "",
		format = varFormat,
		data = varData,
	}

	append(&app.nodes.bottom, node)
}

freeNode :: proc(node: ^Node) {
	switch node.nodeType {
	case "new var":
		data := cast(^VarData)node.data
		delete(data.name)
		delete(data.type)
		delete(data.mods)
		delete(data.modSearch)
		delete(data.arrayLen)
		#partial switch &value in data.value {
		case [dynamic]rune:
			delete(value)
		}
		free(node.data)
		free(node.format)
	}
}
