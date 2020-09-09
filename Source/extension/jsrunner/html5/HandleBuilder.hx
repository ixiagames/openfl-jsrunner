package extension.jsrunner.html5;

#if html5
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

class HandleBuilder {

    public static function build(
        buildFields:Array<Field>, className:String, interfaces:Array<HandleMethod>, calls:Array<HandleMethod>, exportPath:String
    ):Array<Field> {
        #if macro
        var fullClassName = Std.string(Context.getLocalClass());
        Compiler.addMetadata('@:expose("extension.jsrunner.jsinterfaces.$className")', fullClassName);
        #end
        
        var func:Function = { 
            expr: macro return (cast js.Browser.window:Dynamic).$className,
            ret: (macro :Dynamic),
            args: []
        }      
        buildFields.push({
            name:  "so",
            access: [ APublic ],
            kind: FProp("get", "never", func.ret), 
            pos: Context.currentPos()
        });
        buildFields.push({
            name: "get_so",
            access: [ APrivate, AInline ],
            kind: FFun(func),
            pos: Context.currentPos()
        });

        for (method in calls) {
            if (method.field.meta == null)
                method.field.meta = [ { name: "@:extern", pos: method.field.pos } ];
            else
                method.field.meta.push({ name: "@:extern", pos: method.field.pos });

            method.func.expr = switch (method.ret) {
                case "Bool": macro return false;
                case "Int" | "Float": macro return 0;
                case "String": macro return '';
                case _: macro return;
            };
        }

        return buildFields;
    }

}
#end