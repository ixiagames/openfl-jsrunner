# openfl-jsrunner

This lets you use JS codes & libraries in your native OpenFL Android apps. The trick? An invisble webview!

**Something to know:**

- Source codes are under [MIT license](https://github.com/ixiagames/openfl-jsrunner/blob/master/LICENSE).

- This was created for experimental purposes and now its job was done, I probably won't be able to maintain or give support for it.

- This can be used for the HTML5 target (so you can use the exact same Haxe codes across the targets).

**How to use:**

- Clone this somewhere and use add `<include path="cloned_path/openfl-jsrunner" />` to your `project.xml`.

- Create a class implementing `extension.jsrunner.JSHandle`.

- Init JSRunner with your JS sources (internal or external) and an instance of the created class.

- Method `onJSRunnerReady` is required and will be called when all the JS sources are loaded and started running.

- Member methods with `@jsinterface` can be called in our JS sources through `window.ClassName.methodName()`.

- Member methods with `@jscall` (requires empty bodies) can be used in Haxe to call functions in JS sources if they are properties of `window.ClassName`.

- `@jsinterface` and `@jscall` methods allow usage of `Bool`, `Int`, `Float`, `String` and `Array` of these types.


***Example:***

```haxe
class Main extends openfl.display.DisplayObjectContainer implements extension.jsrunner.JSHandle {

    public function new() {
        super();

        var js = "
            window.Main.getWelcomeMsg = function() { return 'Our JS started running successfully...'; }
            window.Main.signIn = function(email) {
                window.JSRunner.trace('Signing in with ' + email + '...');
                firebase.auth().signInWithEmailAndPassword(email, window.Main.getPassword()).then(function() {
                    FirebaseHandle.onSignedIn('Successfully signed in!');
                }).catch(function(e) {
                    window.JSRunner.printE(e);
                });
            }
        ";
        JSRunner.init([
            EXTL("https://www.gstatic.com/firebasejs/7.19.0/firebase-app.js", false), // External source.
            EXTL("https://www.gstatic.com/firebasejs/7.19.0/firebase-auth.js", false),
            INTL(js) // Internal source.
        ], [ this ]); // Using multiple handles is supported.
    }

    function onJSRunnerReady():Void {
        trace(getWelcomeMsg());
        signIn("mail@mail.mail");
    }

    @jscall function getWelcomeMsg():String;
    @jscall function signIn(email:String):Void;
    @jscall function getPassword():String return "hunter2";
    @jsinterface function onSignedIn(message:String):Void trace(message);

}
```
