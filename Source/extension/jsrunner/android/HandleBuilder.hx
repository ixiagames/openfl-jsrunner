package extension.jsrunner.android;

#if android
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;
using StringTools;

class HandleBuilder {
    
    static final typesMap = [
        "Bool"      => "boolean",
        "Int"       => "int",
        "Float"     => "double",
        "String"    => "String",
        "Void"      => "void"
    ];

    public static function build(
        buildFields:Array<Field>, className:String, interfaces:Array<HandleMethod>, calls:Array<HandleMethod>, exportPath:String
    ):Array<Field> {
        for (typeName => type in [
            "Bool" => macro :Bool,
            "Int" => macro :Int,
            "Float" => macro :Float,
            "String" => macro :String,
        ]) {
            buildFields.push({
                name:  "___returned" + typeName,
                access: [ APrivate ],
                kind: FVar(type), 
                pos: Context.currentPos()
            });

            var methodFunc = {
                args: [ { name: "value", type: type } ],
                expr: macro $i{"___returned" + typeName} = value,
                ret: macro :Void
            }
            var methodField = {
                name: "___return" + typeName,
                access: [ APrivate ],
                kind: FFun(methodFunc),
                meta: [ { name: "jsinterface", pos: Context.currentPos() } ],
                pos: Context.currentPos()
            }
            buildFields.push(methodField);
            
            interfaces.push({
                name: methodField.name,
                args: [ "value" ],
                jsonArgs: [],
                ret: "Void",
                func: methodFunc,
                field: methodField
            });
        }

        //

        var javaMethods = new Array<String>();
        var leadingSpaces = "   ";
        var leadingSpaces2x = leadingSpaces + leadingSpaces;

        for (method in interfaces) {
            var s = method.name + '(';
            // The method params.
            for (i in 0...method.func.args.length) {
                s += getJavaType(method.func.args[i].type) + ' ' + method.func.args[i].name;
                if (i < method.func.args.length - 1)
                    s += ", ";
            }

            s += ') {\n$leadingSpaces2x';

            // The inner content.
            s += 'handle.call("${method.name}"';
            if (method.func.args.length > 0) {
                s += ", ";
                for (i in 0...method.func.args.length) {
                    s += method.func.args[i].name;
                    if (i < method.func.args.length - 1)
                        s += ", ";
                }
            }
            
            // Update the inner content to use the correct version of "hxHandle.call".
            var usesCallN:Bool;
            var retString = getJavaType(method.func.ret);
            if (retString == "double") {
                s = s.replace(".call", ".callD");
                if (usesCallN = method.func.args.length <= 3)
                    s = s.replace(".callD", ".callD" + method.func.args.length);
            } else {
                if (usesCallN = method.func.args.length <= 4)
                    s = s.replace(".call", ".call" + method.func.args.length);
            }
            if (!usesCallN) {
                var firstArgName = method.func.args[0].name;
                s = s.replace(', $firstArgName,', ', new Object[] { $firstArgName,');
                s += " }";
            }

            javaMethods.push(retString + ' ' + s + ');\n$leadingSpaces}');
        }
        
        var javaContent =
            "package extension.jsrunner.jsinterfaces;\n\n" +
            "import android.webkit.JavascriptInterface;\n" +
            "import org.haxe.lime.HaxeObject;\n\n" +
            'public class $className extends extension.jsrunner.JSInterface {\n\n' +
            '${leadingSpaces}public static void init(HaxeObject handle) {\n' +
            '${leadingSpaces2x}extension.jsrunner.JSRunner.registerJSInterface(new $className(handle));\n' +
            '$leadingSpaces}\n\n' +
            '${leadingSpaces}public $className(HaxeObject handle) {\n' +
            '${leadingSpaces2x}this.handle = handle;\n' +
            '${leadingSpaces2x}name = "$className";\n' +
            '$leadingSpaces}\n\n';
        for (field in javaMethods)
            javaContent += '${leadingSpaces}@JavascriptInterface\n${leadingSpaces}public $field\n\n';
        javaContent += '}';

        exportPath = Path.join([ exportPath, "android/bin/deps/jsrunner/Source/extension/jsrunner/jsinterfaces" ]);
        if (!FileSystem.exists(exportPath))
            FileSystem.createDirectory(exportPath);
        File.saveContent(Path.join([ exportPath, className + ".java" ]), javaContent);

        //
        
        buildFields.push({
            name: "___getClassName",
            access: [ APrivate ],
            kind: FFun({
                args: [],
                ret: macro :String,
                expr: macro return $v{className}
            }),
            pos: Context.currentPos()
        });

        return buildFields;
    }

    static function getJavaType(type:Null<ComplexType>):String {
        return switch (type) {
            case TPath(p):
                if (p.name == "Array") {
                    return switch(p.params[0]) {
                        case TPType(t): getJavaType(t) + "[]";
                        case TPExpr(e): null;
                    }
                }
                typesMap[p.name];
            case _: null;
        }
    }

}
#end