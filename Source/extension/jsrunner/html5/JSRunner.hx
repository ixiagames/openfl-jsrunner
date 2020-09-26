package extension.jsrunner.html5;

#if html5
import js.Browser;

class JSRunner {
    
    public static function init(scripts:Array<JSSource>, handles:Array<JSHandle>):Void {
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

        var documentReady = Browser.document.readyState == "complete";
        var loadedIndices = new Array<Int>();
        var checkDispatchLoaded = () -> {
            if (documentReady && loadedIndices.length == scripts.length) {
                for (handle in handles)
                    @:privateAccess handle.onJSRunnerReady();
            }
        }

        if (!documentReady) {
            Browser.document.onreadystatechange = () -> {
                documentReady = Browser.document.readyState == "complete";
                checkDispatchLoaded();
            }
        }

        for (i in 0...scripts.length) {
            var elm = Browser.document.createScriptElement();
            switch (scripts[i]) {
                case EXTL(src, defer):
                    elm.onload = (_) -> {
                        loadedIndices.push(i);
                        checkDispatchLoaded();
                    };
                    elm.defer = defer;
                    elm.src = src;
                case INTL(script):
                    elm.text = script;
                    loadedIndices.push(i);
            }
            Browser.document.head.appendChild(elm);
        }
    }

}
#end