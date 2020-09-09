package extension.jsrunner;

@:autoBuild(extension.jsrunner.HandleBuilder.build())
interface JSHandle {
    
    #if html5
    public var so(get, never):Dynamic;
    #end

    #if android
    private var ___returnedBool:Bool;
    private var ___returnedInt:Int;
    private var ___returnedFloat:Float;
    private var ___returnedString:String;
    private function ___returnBool(value:Bool):Void;
    private function ___returnInt(value:Int):Void;
    private function ___returnFloat(value:Float):Void;
    private function ___returnString(value:String):Void;
    #end

    private function onJSRunnerLoaded():Void;

}