package main

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

/*
   Helper Functions
*/

drawLabel :: proc(name: cstring, height: i32, pos: rl.Vector2) {
    rl.DrawText(name, i32(pos.x)+15, i32(pos.y)+height, 17, {235,235,235,255})
}

drawDatabox :: proc(node: Node, rec: rl.Rectangle, color: rl.Color = {80,80,80,255}) {
    rl.DrawRectangleV(node.pos+{rec.x,rec.y}, {rec.width,rec.height}, color)
}


// Draw new var

drawNewVarNode :: proc(node: Node, data: ^VarData, format: ^VarFormat) {
    // Draw node
    rl.DrawRectangleRounded({node.pos.x, node.pos.y, node.size.x, node.size.y}, 0.2, 1, {90,90,90,255})
    rl.DrawRectangleRounded({node.pos.x+2, node.pos.y+2, node.size.x-4, node.size.y-4}, 0.2, 1, rl.RED)
    rl.DrawRectangleRounded({node.pos.x+2, node.pos.y+47, node.size.x-4, node.size.y-49}, 0.2, 1, {60,60,60,255})
    rl.DrawRectangleV(node.pos+{2,45}, {node.size.x-4, 20}, {60,60,60,255})

    // Draw data boxes
    if node.selectedEl == "varName" {drawDatabox(node, format.name, {100,100,100,255})}
    else {drawDatabox(node, format.name)}
    if node.selectedEl == "varType" {drawDatabox(node, format.type, {100,100,100,255})}
    else {drawDatabox(node, format.type)}
    if data.isArray {
        drawDatabox(node, format.array, rl.GREEN)
        if node.selectedEl == "varArrayLen" {drawDatabox(node, format.arrayLen, {100,100,100,255})}
        else {drawDatabox(node, format.arrayLen)}
        drawDatabox(node, format.value, {70,70,70,255})
    }
    else {
        drawDatabox(node, format.array)
        if node.selectedEl == "varValue" {drawDatabox(node, format.value, {100,100,100,255})}
        else {drawDatabox(node, format.value)}
    }
    if node.selectedEl == "varModSearch" {drawDatabox(node, format.modSearch, {100,100,100,255})}
    else {drawDatabox(node, format.modSearch)}
    drawDatabox(node, format.mods)

    // Draw text
    rl.DrawText("New Variable", i32(node.pos.x+10), i32(node.pos.y+15), 25, {235,235,235,255})

    csName: cstring = strings.clone_to_cstring(utf8.runes_to_string(data.name[:]))
    rl.DrawText(csName, i32(node.pos.x)+70, i32(node.pos.y)+62, 17, {235,235,235,255})

    csName = strings.clone_to_cstring(utf8.runes_to_string(data.type[:]))
    rl.DrawText(csName, i32(node.pos.x)+70, i32(node.pos.y)+92, 17, {235,235,235,255})

    csName = strings.clone_to_cstring(utf8.runes_to_string(data.modSearch[:]))
    rl.DrawText(csName, i32(node.pos.x)+70, i32(node.pos.y)+182, 17, {235,235,235,255})

    if data.isArray {
        csName = strings.clone_to_cstring(utf8.runes_to_string(data.arrayLen[:]))
        rl.DrawText(csName, i32(node.pos.x)+135, i32(node.pos.y)+152, 17, {235, 235, 235, 255})
    }
    else {
        switch type in data.value {
            case nil:
                break
            case [dynamic]rune:
                //fmt.println("Rune")
                csName = strings.clone_to_cstring(utf8.runes_to_string(type[:]))
                rl.DrawText(csName, i32(node.pos.x)+70, i32(node.pos.y)+122, 17, {235,235,235,255})
            case ^Node:
                //fmt.println("Node")
                drawDatabox(node, format.value, {70,70,70,255})
        }
    }
    delete(csName)

    // Draw Labels
    drawLabel("Name:", 60, node.pos)
    drawLabel("Type:", 90, node.pos)
    drawLabel("Value:", 120, node.pos)
    drawLabel("Is Array:", 150, node.pos)
    drawLabel("Mods:", 180, node.pos)

    // Draw Node Connectors
    //drawDatabox(node, node.format.topConn, {90,90,90,255})
    drawDatabox(node, format.leftConn, {90,90,90,255})
    drawDatabox(node, format.bottomConn, {90,90,90,255})
    drawDatabox(node, format.rightConn, {90,90,90,255})
    drawDatabox(node, format.nextConn, rl.GREEN)
    top := format.topConn
    drawDatabox(node, top, {90,90,90,255})
    top.y += 8
    drawDatabox(node, top, rl.RED)

    // Draw Mods
    for mod in data.mods {
        rl.DrawRectangleRec({mod.rec.x+node.pos.x, mod.rec.y+node.pos.y+mod.rec.height-3, mod.rec.width, 3}, {110,110,110,255})
        //rl.DrawRectangleRec({mod.rec.x+node.pos.x+2, mod.rec.y+node.pos.y+2, mod.rec.width-4, mod.rec.height-4}, {70,70,70,255})
        rl.DrawText(mod.text, i32(mod.rec.x+node.pos.x), i32(mod.rec.y+node.pos.y), 17, {235,235,235,255})
    }
}

// Draw binary op
drawBinaryOpNode :: proc(node: Node, data: ^BinaryOpData, format: ^BinaryOpFormat) {
	rl.DrawRectangleRounded({node.pos.x, node.pos.y, node.size.x, node.size.y}, 0.2, 1, {90,90,90,255})
	drawDatabox(node, format.topConn, {90,90,90,255})
    rl.DrawRectangleRounded({node.pos.x+2, node.pos.y+2, node.size.x-4, node.size.y-4}, 0.2, 1, {255,140,0,255})
    rl.DrawRectangleRounded({node.pos.x+2, node.pos.y+47, node.size.x-4, node.size.y-49}, 0.2, 1, {60,60,60,255})
    rl.DrawRectangleV(node.pos+{2,35}, {node.size.x-4, 20}, {60,60,60,255})
	//rl.DrawRectangleRounded({node.pos.x+2, node.pos.y+2, node.size.x-4, node.size.y-4}, 0.2, 1, {60,60,60,255})

	drawLabel("Binary Operation", 10, node.pos)
	drawLabel("Operation:", 55, node.pos)
}
