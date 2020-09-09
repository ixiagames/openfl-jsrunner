package extension.jsrunner.android;

#if android
#if !macro
import haxe.Json;
import openfl.Assets;
import utils.openfl.Assets.AssetType;
#if (openfl < "4.0.0")
import openfl.utils.JNI;
#else
import lime.system.JNI;
#end
#end

class JSRunner {

    #if !macro
    public static function init(scripts:Array<Script>, handles:Array<JSHandle>):Void {
        JNI.createStaticMethod("extension/jsrunner/JSRunner", "init", "()V")();
        for (handle in handles) {
            var className = Reflect.callMethod(handle, Reflect.field(handle, "___getClassName"), []);
            JNI.createStaticMethod("extension/jsrunner/jsinterfaces/" + className, "init", "(Lorg/haxe/lime/HaxeObject;)V")(handle);
        }
        
        var html = "<html><head>\n";
        for (script in scripts) {
            html += (switch(script) {
                case EXTL(src, defer): '<script ${defer ? "defer" : ''}src="$src">';
                case INTL(script): '<script>$script';
            }) + "</script>";
        }
        html += "</html></head>";
        JNI.createStaticMethod("extension/jsrunner/JSRunner", "load", "(Ljava/lang/String;)V")(html);
    }
    #end
    
    public static final execute:(js:String)->Void = JNI.createStaticMethod("extension/jsrunner/JSRunner", "execute", "(Ljava/lang/String;)V");

}
#end