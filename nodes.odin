package main

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

/*
   Node Definitions
*/

NodeLayers :: struct {
	top: [dynamic]Node,
	bottom: [dynamic]Node,
}

Node :: struct {
	id: i32,
	nodeType: NodeType,
	pos: rl.Vector2,
	size: rl.Vector2,
	data: rawptr,//DataUnion,
	format: rawptr,//FormatUnion,
	conns: [dynamic]Connection,
	selectedEl: string,
}

Connection :: struct {
	name: string,
	wire: ^Wire,
	format: rl.Rectangle,
}

NodeType :: enum {
	NONE,
	NEWVAR,
	VAR,
	INDEX,
	UNARYOP,
	BINARYOP,
	TERNARYOP,

}

stringToNodeType :: proc(type: string) -> NodeType {
	/*
	lower, err := strings.to_lower(type)
	defer delete(lower)
	if err == nil {
		fmt.println("Err")
		return nil
	}
	fmt.println(lower)
	*/

	switch type {
		case "new var":
			return .NEWVAR
		case "var":
			return .VAR
		case "index":
			return .INDEX
		case "unary op":
			return .UNARYOP
		case "binary op":
			return .BINARYOP
		case "ternary op":
			return .TERNARYOP
		case:
			return .NONE
	}
	return .NONE
}

/*
   Node creation
*/

drawNode :: proc(node: Node) {
	switch node.nodeType {
		case .NONE: return
		case .NEWVAR:
			data := cast(^VarData)node.data
			format := cast(^VarFormat)node.format
			drawNewVarNode(node, data, format)
		case .VAR:
			return
		case .INDEX:
			return
		case .UNARYOP:
			data := cast(^UnaryOpData)node.data
			format := cast(^UnaryOpFormat)node.format
			drawUnaryOpNode(node, data, format)
		case .BINARYOP:
			data := cast(^BinaryOpData)node.data
			format := cast(^BinaryOpFormat)node.format
			drawBinaryOpNode(node, data, format)
		case .TERNARYOP:
			//data := cast(^TernaryOpData)node.data
			//format := cast(^TernaryOpFormat)node.format
			drawTernaryOpNode(node)//, data, format)
	}
}


createNode :: proc(nodeType: NodeType, app: ^App) {
	/*
	if nodeType == nil {
		fmt.println("nil node")		
		return
	}
	*/
	switch nodeType {
	case .NONE: return
	case .NEWVAR:
		createNewVar(app)
	case .VAR:
		return
	case .INDEX:
		return
	case .UNARYOP:
		createUnaryOp(app)
	case .BINARYOP:
		createBinaryOp(app)
	case .TERNARYOP:
		createTernaryOp(app)
	case:
		return
	}
	app.nextId += 1
}

/*
   New Variable
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
	/*
	topConn: ^Wire,
	leftConn: ^Wire,
	bottomConn: ^Wire,
	nextConn: ^Wire,
	*/
}

Mod :: struct {
	rec: rl.Rectangle,
	text: cstring
}

DataValue :: union {
	[dynamic]rune,
	^Node,
}

VarFormat :: struct {
	name: rl.Rectangle,
	value: rl.Rectangle,
	type: rl.Rectangle,
	mods: rl.Rectangle,
	modSearch: rl.Rectangle,
	array: rl.Rectangle,
	arrayLen: rl.Rectangle,
	/*
	topConn: rl.Rectangle,
	leftConn: rl.Rectangle,
	bottomConn: rl.Rectangle,
	//rightConn: rl.Rectangle,
	nextConn: rl.Rectangle,
	*/
}

initVarFormat :: proc() -> VarFormat {
	return VarFormat {
		name = {x=65,y=60,width=120,height=20},
		type = {x=65,y=90,width=120,height=20},
		value = {x=75,y=120,width=110,height=20},
		array = {x=105,y=150,width=20,height=20},
		arrayLen = {x=130,y=150,width=55,height=20},
		mods = {x=15,y=210,width=170,height=80},
		modSearch = {x=65,y=180,width=120,height=20},
		/*
		topConn = {x=95,y=-6,width=10,height=10},
		leftConn = {x=-3,y=150,width=10,height=10},
		bottomConn = {x=95,y=305,width=10,height=10},
		nextConn = {x=195,y=150,width=10,height=10},
		*/
		//rightConn = {x=195,y=170,width=10,height=10},
		//nextConn = {x=195,y=130,width=10,height=10},
	}
}

addNewVarConnData :: proc(conns: ^[dynamic]Connection) {
	append(conns, Connection{name="top", wire=nil, format=rl.Rectangle{x=95,y=-5,width=10,height=10}})
	append(conns, Connection{name="left", wire=nil, format=rl.Rectangle{x=-3,y=152,width=10,height=10}})
	append(conns, Connection{name="bottom", wire=nil, format=rl.Rectangle{x=95,y=305,width=10,height=10}})
	append(conns, Connection{name="next", wire=nil, format=rl.Rectangle{x=195,y=155,width=10,height=10}})
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
	/*
	varData.topConn = nil
	varData.leftConn = nil
	varData.bottomConn = nil
	varData.nextConn = nil
	*/

	varFormat := new(VarFormat)
	varFormat^ = initVarFormat()

	node: Node = {
		id = Id,
		pos = Pos,
		nodeType = .NEWVAR,
		size = {200,310},
		selectedEl = "",
		format = varFormat,
		data = varData,
		conns = make([dynamic]Connection)
	}

	addNewVarConnData(&node.conns)
	append(&app.nodes.bottom, node)
}



addVarMod :: proc(data: ^VarData, format: ^VarFormat) {//node: ^Node) {
    search: string = utf8.runes_to_string(data.modSearch[:])
	defer delete(search)
    for selectedMod in varMods { // varMods from sidebar.odin
        if string(selectedMod) == search {
            if len(data.mods) != 0 {
                data.newModPos += {data.mods[len(data.mods)-1].rec.width+10, 0}
                if f32(rl.MeasureText(selectedMod, 17)) + data.newModPos.x >= format.mods.x + format.mods.width {
                    data.newModPos.x = 20
                    data.newModPos.y += 23
                }
            }
            newMod: Mod = {
                rec = {x=data.newModPos.x,y=data.newModPos.y,width=f32(rl.MeasureText(selectedMod, 17)),height=20},
                text = selectedMod,
            }
            append(&data.mods, newMod)
            clear(&data.modSearch)
            return
        }
    }
}

/*
   Unary Operator
*/

UnaryOpData :: struct {
	operation: [dynamic]rune,
	topConn: ^Wire,
	leftConn: ^Wire,
	bottomConn: ^Wire,
	nextConn: ^Wire,
}

UnaryOpFormat :: struct {
	operation: rl.Rectangle,
	topConn: rl.Rectangle,
	leftConn: rl.Rectangle,
	bottomConn: rl.Rectangle,
	nextConn: rl.Rectangle,
}

initUnaryOpData :: proc() -> UnaryOpData {
	return UnaryOpData {
		operation = make([dynamic]rune),
		/*
		topConn = nil,
		leftConn = nil,
		bottomConn = nil,
		nextConn = nil,
		*/
	}
}

initUnaryOpFormat :: proc() -> UnaryOpFormat {
	return UnaryOpFormat {
		operation = {x=110,y=55,width=80,height=20},
		/*
		topConn = {x=95,y=-6,width=10,height=10},
		leftConn = {x=-3,y=58,width=10,height=10},
		bottomConn = {x=95,y=95,width=10,height=10},
		nextConn = {x=195,y=60,width=10,height=10},
		*/
	}
}

addUnaryOpConnData :: proc(conns: ^[dynamic]Connection) {
	append(conns, Connection{name="top", wire=nil, format=rl.Rectangle{x=95,y=-5,width=10,height=10}})
	append(conns, Connection{name="left", wire=nil, format=rl.Rectangle{x=-3,y=58,width=10,height=10}})
	append(conns, Connection{name="bottom", wire=nil, format=rl.Rectangle{x=95,y=95,width=10,height=10}})
	append(conns, Connection{name="next", wire=nil, format=rl.Rectangle{x=195,y=60,width=10,height=10}})
}

createUnaryOp :: proc(app: ^App) {
	Pos := app.sidebar.staticPos
	Id := app.nextId

	unaryOpData := new(UnaryOpData)
	unaryOpData^ = initUnaryOpData()

	unaryOpFormat := new(UnaryOpFormat)
	unaryOpFormat^ = initUnaryOpFormat()

	node: Node = {
		id = Id,
		pos = Pos,
		nodeType = .UNARYOP,
		size = {200,100},
		selectedEl = "",
		format = unaryOpFormat,
		data = unaryOpData,
		conns = make([dynamic]Connection),
	}
	addUnaryOpConnData(&node.conns)
	append(&app.nodes.bottom, node)
}

/*
   Binary Operator
*/

BinaryOpData :: struct {
	operation: [dynamic]rune,
	/*
	topConn: ^Wire,
	leftConn: ^Wire,
	bottomConn: ^Wire,
	nextConn: ^Wire,
	*/
}

BinaryOpFormat :: struct {
	operation: rl.Rectangle,
	/*
	topConn: rl.Rectangle,
	leftConn: rl.Rectangle,
	botLeftConn: rl.Rectangle,
	botRightConn: rl.Rectangle,
	nextConn: rl.Rectangle,
	*/
}

initBinaryOpData :: proc() -> BinaryOpData {
	return BinaryOpData {
		operation = make([dynamic]rune),
		/*
		topConn = nil,
		leftConn = nil,
		bottomConn = nil,
		nextConn = nil,
		*/
	}
}

initBinaryOpFormat :: proc() -> BinaryOpFormat {
	return BinaryOpFormat {
		operation = {x=110,y=55,width=80,height=20},	
		/*
		topConn = {x=95,y=-6,width=10,height=10},
		leftConn = {x=-3,y=58,width=10,height=10},
		botLeftConn = {x=60,y=95,width=10,height=10},
		botRightConn = {x=130,y=95,width=10,height=10},
		nextConn = {x=195,y=60,width=10,height=10},
		*/
	}
}

addBinaryOpConnData :: proc(conns: ^[dynamic]Connection) {
	append(conns, Connection{name="top", wire=nil, format=rl.Rectangle{x=95,y=-5,width=10,height=10}})
	append(conns, Connection{name="left", wire=nil, format=rl.Rectangle{x=-3,y=58,width=10,height=10}})
	append(conns, Connection{name="botLeft", wire=nil, format=rl.Rectangle{x=60,y=95,width=10,height=10}})
	append(conns, Connection{name="botRight", wire=nil, format=rl.Rectangle{x=130,y=95,width=10,height=10}})
	append(conns, Connection{name="next", wire=nil, format=rl.Rectangle{x=195,y=60,width=10,height=10}})
}

createBinaryOp :: proc(app: ^App) {
	Pos := app.sidebar.staticPos
	Id := app.nextId

	binOpData := new(BinaryOpData)
	binOpData^ = initBinaryOpData()

	binOpFormat := new(BinaryOpFormat)
	binOpFormat^ = initBinaryOpFormat()

	node: Node = {
		id = Id,
		pos = Pos,
		nodeType = .BINARYOP,
		size = {200,100},
		selectedEl = "",
		format = binOpFormat,
		data = binOpData,
		conns = make([dynamic]Connection)
	}
	addBinaryOpConnData(&node.conns)
	append(&app.nodes.bottom, node)
}

/*
   Ternary Operator
*/

/*
TernaryOpData :: struct {
	topConn: ^Wire,
	leftConn: ^Wire,
	nextConn: ^Wire,
	condConn: ^Wire,
	expr1Conn: ^Wire,
	expr2Conn: ^Wire,
}

TernaryOpFormat :: struct {
	topConn: rl.Rectangle,
	leftConn: rl.Rectangle,
	nextConn: rl.Rectangle,
	condConn: rl.Rectangle,
	expr1Conn: rl.Rectangle,
	expr2Conn: rl.Rectangle,
}

initTernaryOpData :: proc() -> TernaryOpData {
	return TernaryOpData {
		topConn = nil,
		leftConn = nil,
		nextConn = nil,
		condConn = nil,
		expr1Conn = nil,
		expr2Conn = nil,
	}
}

initTernaryOpFormat :: proc() -> TernaryOpFormat {
	return TernaryOpFormat {
		topConn = {x=95,y=-6,width=10,height=10},
		leftConn = {x=-3,y=58,width=10,height=10},
		nextConn = {x=195,y=60,width=10,height=10},
		condConn = {x=50,y=95,width=10,height=10},
		expr1Conn = {x=100,y=95,width=10,height=10},
		expr2Conn = {x=150,y=95,width=10,height=10},
	}
}
*/

addTernaryOpConnData :: proc(conns: ^[dynamic]Connection) {
	append(conns, Connection{name="top", wire=nil, format=rl.Rectangle{x=95,y=-5,width=10,height=10}})
	append(conns, Connection{name="left", wire=nil, format=rl.Rectangle{x=-3,y=58,width=10,height=10}})
	append(conns, Connection{name="next", wire=nil, format=rl.Rectangle{x=195,y=60,width=10,height=10}})
	append(conns, Connection{name="cond", wire=nil, format=rl.Rectangle{x=50,y=95,width=10,height=10}})
	append(conns, Connection{name="expr1", wire=nil, format=rl.Rectangle{x=100,y=95,width=10,height=10}})
	append(conns, Connection{name="expr2", wire=nil, format=rl.Rectangle{x=150,y=95,width=10,height=10}})
}

createTernaryOp :: proc(app: ^App) {
	Pos := app.sidebar.staticPos
	Id := app.nextId

	/*
	ternOpData := new(TernaryOpData)
	ternOpData^ = initTernaryOpData()

	ternOpFormat := new(TernaryOpFormat)
	ternOpFormat^ = initTernaryOpFormat()
	*/

	node: Node = {
		id = Id,
		pos = Pos,
		nodeType = .TERNARYOP,
		size = {200,100},
		selectedEl = "",
		format = nil,
		data = nil,
		conns = make([dynamic]Connection)
	}
	addTernaryOpConnData(&node.conns)
	append(&app.nodes.bottom, node)
}

/*
   Free Memory
*/

freeNode :: proc(node: ^Node) {
	switch node.nodeType {
	case .NONE: return
	case .NEWVAR:
		data := cast(^VarData)node.data
		format := cast(^VarFormat)node.format
		delete(data.name)
		delete(data.type)
		delete(data.mods)
		delete(data.modSearch)
		delete(data.arrayLen)
		#partial switch &value in data.value {
		case [dynamic]rune:
			delete(value)
		}
	case .VAR:
		return
	case .INDEX:
		return
	case .UNARYOP:
		data := cast(^UnaryOpData)node.data
		delete(data.operation)
	case .BINARYOP:
		data := cast(^BinaryOpData)node.data
		delete(data.operation)
	case .TERNARYOP:
		break
	}
	free(node.data)
	free(node.format)
	delete(node.conns)
}
