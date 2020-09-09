package extension.jsrunner;

import haxe.macro.Expr;

typedef HandleMethod = {

    name:String,
    args:Array<String>,
    jsonArgs:Map<Int, String>,
    ret:String,
    func:Function,
    field:Field,
    ?altName:String

}