package extension.jsrunner;

import haxe.ds.ReadOnlyArray;
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;

class HandleBuilder {

    static final acceptedTypes:ReadOnlyArray<String> = [ "Bool", "Int", "Float", "String" ];
    static final acceptedTypesText:String = {
        var text = acceptedTypes[0];
        for (i in 1...acceptedTypes.length)
            text += ", " + acceptedTypes[i];
        text + " and arrays of those types.";
    }
    static var builtClasses:Array<String> = [];

    macro static public function build():Array<Field> {
        var localClass = Std.string(Context.getLocalClass());
        var className = localClass.substr(localClass.lastIndexOf('.') + 1);
        if (builtClasses.indexOf(className) > -1)
            Context.error('Different handles cannot have a same class name ($className).', Context.currentPos());

        builtClasses.push(className);

        //

        if (!FileSystem.exists("./project.xml"))
            Context.error("Cannot find project.xml", Context.currentPos());

        var exportPath:String = null;
        var projectXML = Xml.parse(File.getContent('./project.xml'));
        for (projectElement in projectXML.elementsNamed("project")) {
            for (element in projectElement.elementsNamed("app")) {
                exportPath = element.get("path");
                break;
            }
            if (exportPath != null)
                break;
        }
        if (exportPath == null)
            Context.error("Cannot find export path in project.xml.", Context.currentPos());
        
        //

        var interfaces = new Array<HandleMethod>();
        var calls = new Array<HandleMethod>();
        var fields = Context.getBuildFields();
        for (field in fields) {
            var meta = findFieldMetaOfName(field, "jsinterface");
            if (meta != null) {
                if (findFieldMetaOfName(field, "jscall") != null)
                    Context.error("Cannot use @jsinterface & @jscall on a same method.", field.pos);

                interfaces.push(getHandleMethod(field, meta));

            } else {
                var meta = findFieldMetaOfName(field, "jscall");
                if (meta != null)
                    calls.push(getHandleMethod(field, meta));
            }
        }

        for (method in calls) {
            var methodName = method.altName != null ? method.altName : method.name;
            var js = 'window.$className.$methodName(';
            js = method.ret == "Void" ? js : 'window.$className.___return${method.ret}($js';
            var expr = macro $v{js};
            for (i in 0...method.args.length) {
                expr = {
                    expr: EBinop(
                        OpAdd, expr, 
                        method.jsonArgs.exists(i) ?
                            macro haxe.Json.stringify($i{method.args[i]}) :
                            {
                                var expr = macro $i{method.args[i]};
                                expr = method.args[i] == "String" ? expr : macro '"' + ${expr} + '"';
                                i == method.args.length - 1 ? expr : macro ${expr} + ", ";
                            }
                    ),
                    pos: Context.currentPos()
                }
            }
            expr = {
                expr: EBinop(OpAdd, expr, macro $v{method.ret == "Void" ? ')' : "))"}),
                pos: Context.currentPos()
            }
            expr = macro extension.jsrunner.JSRunner.execute(${expr});
            method.func.expr =
                method.ret == "Void" ?
                    expr :
                    macro $b{[ expr,  macro return $i{"___returned" + method.ret} ]};
        }

        //

        #if android
        return extension.jsrunner.android.HandleBuilder.build(fields, className, interfaces, calls, exportPath);
        #elseif html5
        return extension.jsrunner.html5.HandleBuilder.build(fields, className, interfaces, calls, exportPath);
        #else
        throw "Target platform not supported yet.";
        #end
    }

    static function getHandleMethod(field:Field, meta:MetadataEntry):HandleMethod {
        var metaName = meta.name;
        return switch (field.kind) {
            case FFun(f):
                if (f.params != null && f.params.length > 0)
                    Context.error('Method with @$metaName cannot have type parameters.', field.pos);

                if (f.ret != null) {
                    if (switch (f.ret) {
                        case TPath(p): p.name == "Void" ? false : !checkType(f.ret);
                        case _: true;
                    })
                        Context.error('Method with @$metaName cannot have returned type outside of Void, $acceptedTypesText.', field.pos);
                }
            
                var jsonArgs = metaName == "jscall" ? new Map<Int, String>() : null;
                for (i in 0...f.args.length) {
                    if (metaName == "jsinterface" && (f.args[i].opt || f.args[i].value != null))
                        Context.error("Method with @jsinterface cannot have optional args.", field.pos);

                    for (argMeta in f.args[i].meta) {
                        if (argMeta.name == "json") {
                            if (metaName == "jscall") {
                                jsonArgs[i] = "haxe.Json.stringify(f.args[i].name)";
                                break;
                            }
                            
                            Context.error("@json cannot be used on args of methods delcared without @jscall.", field.pos);
                        }
                    }

                    if (metaName == "jsinterface" || !jsonArgs.exists(i)) {
                        if (!checkType(f.args[i].type))
                            Context.error('Method with @jsinterface cannot have args outside of types $acceptedTypesText unless the arg is declared with @json.', field.pos);
                    }
                }

                var altName:String = null;
                if (metaName == "jscall") {
                    if (meta.params.length > 1)
                        Context.error("Invalid number of params for @jscall.", field.pos);

                    for (param in meta.params) {
                        switch(param.expr) {
                            case EConst(c):
                                switch(c) {
                                    case CString(s, kind):
                                        altName = s;
                                    case _:
                                        Context.error("Invalid param for @jscall.", param.pos);
                                }
                            case _:
                                Context.error("Invalid param for @jscall.", param.pos);
                        }
                    }

                    if (f.expr != null) {
                        switch (f.expr.expr) {
                            case EBlock(exprs):
                                if (exprs.length > 0)
                                    Context.error("@jscall method requires an empty body.", f.expr.pos);
                            case _:
                                Context.error("@jscall method requires an empty body.", f.expr.pos);
                        }
                    }
                }

                {
                    name: field.name,
                    altName: altName,
                    args: [ for (arg in f.args) arg.name ],
                    jsonArgs: jsonArgs,
                    ret: switch (f.ret) { case TPath(p): p.name; case _: null; },
                    func: f,
                    field: field
                };
                
            case _:
                Context.error('@$metaName cannot be used on a non-method.', field.pos);
                null;
        }
    }

    static function findFieldMetaOfName(field:Field, name:String):MetadataEntry {
        if (field.meta == null || field.meta.length == 0)
            return null;
        for (meta in field.meta) {
            if (meta.name == name)
                return meta;
        }
        return null;
    }

    static function checkType(type:ComplexType):Bool {
        return switch (type) {
            case TPath(p):
                p.name == "Array" ?
                    switch(p.params[0]) {
                        case TPType(t): checkType(t);
                        case TPExpr(e): false;
                    } :
                    acceptedTypes.indexOf(p.name) > -1;
            case _: false;
        }
    }

}