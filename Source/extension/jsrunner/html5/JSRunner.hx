package extension.jsrunner.html5;

#if html5
import js.Browser;

class JSRunner {
    
    public static function init(scripts:Array<Script>, handles:Array<JSHandle>):Void {
        var elm = Browser.document.createScriptElement();
        elm.text = "
            window.JSRunner = {};
            window.JSRunner.trace = function(value) { console.log(value) };
            window.JSRunner.error = function(value) { console.error(value) };
        ";
        Browser.document.head.appendChild(elm);

        for (handle in handles) {
            var className = Type.getClassName(Type.getClass(handle));
            className = className.substr(className.lastIndexOf('.') + 1);
            Reflect.setField(Browser.window, className, handle);
        }

        for (script in scripts) {
            var elm = Browser.document.createScriptElement();
            switch (script) {
                case EXTL(src, defer):
                    elm.src = src;
                    elm.defer = defer;
                case INTL(script):
                    elm.text = script;
            }
            Browser.document.head.appendChild(elm);
        }

        Browser.window.onload = () -> {
            for (handle in handles)
                @:privateAccess handle.onJSRunnerLoaded();
        };
    }

}
#end