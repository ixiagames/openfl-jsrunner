package extension.jsrunner;

import haxe.Json;
import openfl.Assets;
import utils.openfl.Assets.AssetType;

typedef _JSRunner =
    #if android
    extension.jsrunner.android.JSRunner;
    #elseif html5
    extension.jsrunner.html5.JSRunner;
    #else
    throw "Target is not supported yet.";
    #end

class JSRunner {

    public static var inited(default, null):Bool = false;

    public static function init(scripts:Array<JSSource>, handles:Array<JSHandle>):Void {
        if (inited) 
            throw "Trying to init JSRunner twice.";
        
        var scripts = scripts.copy();
        scripts.unshift(
            INTL(
                "window.JSRunner.printE = function(e) { " +
                #if html5
                "window.JSRunner.error(e); }"
                #else
                "window.JSRunner.error(e.lineNumber + ' ' + e.name + ': ' + e.message); }"
                #end
            )
        );
        _JSRunner.init(scripts, handles);
    }
    
    #if !html5
    public static inline function execute(js:String):Void {
        #if debug
        #if trace_js
        trace(js);
        #end
        js = 'try { $js } catch(e) { window.JSRunner.printE(e) }';
        #end
        _JSRunner.execute(js);
    }
    #end

}