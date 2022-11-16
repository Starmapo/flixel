package flixel.input;

import lime.app.Application;

class FlxTextInput {
    public var inputText:Array<String> = [];

    public function onTextInput(key:String) {
        inputText.push(key);
    }
    public function new() {
		Application.current.window.onTextInput.add(onTextInput);
    }

    public function reset() {
        inputText = [];
    }
}