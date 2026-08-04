class_name Note extends RefCounted

enum Type {LEFT, RIGHT, BOMB}

var time: float
var line: int
var layer: int
var color: Type
var direction: int
# Boilerplate
static func note(a: float, b: int, c: int, d: Type, e: int) -> Note: var x:=Note.new();x.time=(60.0/Map.bpm)*a;x.line=b;x.layer=c;x.color=d;x.direction=e;return x
static func bomb(a: float, b: int, c: int) -> Note: var x:=Note.new();x.time=(60.0/Map.bpm)*a;x.line=b;x.layer=c;x.color=Type.BOMB;return x
