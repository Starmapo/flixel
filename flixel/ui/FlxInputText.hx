package flixel.ui;

import flash.errors.Error;
import flash.events.KeyboardEvent;
import flash.geom.Rectangle;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxPointer;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.ui.FlxUI.NamedString;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.desktop.Clipboard;

/**
 * FlxInputText v1.11, ported to Haxe
 * @author larsiusprime, (Lars Doucet)
 * @link http://github.com/haxeflixel/flixel-ui
 *
 * FlxInputText v1.10, Input text field extension for Flixel
 * @author Gama11, Mr_Walrus, nitram_cero (Martín Sebastián Wain)
 * @link http://forums.flixel.org/index.php/topic,272.0.html
 *
 * Copyright (c) 2009 Martín Sebastián Wain
 * License: Creative Commons Attribution 3.0 United States
 * @link http://creativecommons.org/licenses/by/3.0/us/
 */
class FlxInputText extends FlxSpriteGroup
{
	public static inline var NO_FILTER:Int = 0;
	public static inline var ONLY_ALPHA:Int = 1;
	public static inline var ONLY_NUMERIC:Int = 2;
	public static inline var ONLY_ALPHANUMERIC:Int = 3;
	public static inline var CUSTOM_FILTER:Int = 4;

	public static inline var ALL_CASES:Int = 0;
	public static inline var UPPER_CASE:Int = 1;
	public static inline var LOWER_CASE:Int = 2;

	public static inline var BACKSPACE_ACTION:String = "backspace"; // press backspace
	public static inline var DELETE_ACTION:String = "delete"; // press delete
	public static inline var ENTER_ACTION:String = "enter"; // press enter
	public static inline var INPUT_ACTION:String = "input"; // manually edit

	/**
	 * This regular expression will filter out (remove) everything that matches.
	 * Automatically sets filterMode = FlxInputText.CUSTOM_FILTER.
	 */
	public var customFilterPattern(default, set):EReg;

	function set_customFilterPattern(cfp:EReg)
	{
		customFilterPattern = cfp;
		filterMode = CUSTOM_FILTER;
		return customFilterPattern;
	}

	/**
	 * A function called whenever the value changes from user input, or enter is pressed
	 */
	public var callback:String->String->Void;

	/**
	 * Whether or not the textbox has a background
	 */
	public var background:Bool = false;

	/**
	 * The caret's color. Has the same color as the text by default.
	 */
	public var caretColor(default, set):Int;

	function set_caretColor(i:Int):Int
	{
		caretColor = i;
		dirty = true;
		return caretColor;
	}

	public var caretWidth(default, set):Int = 1;

	function set_caretWidth(i:Int):Int
	{
		caretWidth = i;
		dirty = true;
		return caretWidth;
	}

	public var params(default, set):Array<Dynamic>;

	/**
	 * Whether or not the textfield is a password textfield
	 */
	public var passwordMode(get, set):Bool;

	/**
	 * Whether or not the text box is the active object on the screen.
	 */
	public var hasFocus(default, set):Bool = false;

	/**
	 * The position of the selection cursor. An index of 0 means the carat is before the character at index 0.
	 */
	public var caretIndex(default, set):Int = 0;

	/**
	 * callback that is triggered when this text field gets focus
	 * @since 2.2.0
	 */
	public var focusGained:Void->Void;

	/**
	 * callback that is triggered when this text field loses focus
	 * @since 2.2.0
	 */
	public var focusLost:Void->Void;

	/**
	 * The Case that's being enforced. Either ALL_CASES, UPPER_CASE or LOWER_CASE.
	 */
	public var forceCase(default, set):Int = ALL_CASES;

	/**
	 * Set the maximum length for the field (e.g. "3"
	 * for Arcade type hi-score initials). 0 means unlimited.
	 */
	public var maxLength(default, set):Int = 0;

	/**
	 * Change the amount of lines that are allowed.
	 */
	public var lines(default, set):Int;

	/**
	 * Defines what text to filter. It can be NO_FILTER, ONLY_ALPHA, ONLY_NUMERIC, ONLY_ALPHA_NUMERIC or CUSTOM_FILTER
	 * (Remember to append "FlxInputText." as a prefix to those constants)
	 */
	public var filterMode(default, set):Int = NO_FILTER;

	/**
	 * The color of the fieldBorders
	 */
	public var fieldBorderColor(default, set):Int = FlxColor.BLACK;

	/**
	 * The thickness of the fieldBorders
	 */
	public var fieldBorderThickness(default, set):Int = 1;

	/**
	 * The color of the background of the textbox.
	 */
	public var backgroundColor(default, set):Int = FlxColor.WHITE;

	public var text(get, set):String;

	public var textSprite:FlxText;

	/**
	 * A FlxSprite representing the background sprite
	 */
	public var backgroundSprite:FlxSprite;

	/**
	 * A timer for the flashing caret effect.
	 */
	var _caretTimer:FlxTimer;

	/**
	 * A FlxSprite representing the flashing caret when editing text.
	 */
	public var caret:FlxSprite;

	/**
	 * A FlxSprite representing the fieldBorders.
	 */
	public var fieldBorderSprite:FlxSprite;

	/**
	 * The left- and right- most fully visible character indeces
	 */
	var _scrollBoundIndeces:{left:Int, right:Int} = {left: 0, right: 0};

	// workaround to deal with non-availability of getCharIndexAtPoint or getCharBoundaries on cpp/neko targets
	var _charBoundaries:Array<FlxRect>;

	/**
	 * Stores last input text scroll.
	 */
	var lastScroll:Int;

	/**
	 * @param	X				The X position of the text.
	 * @param	Y				The Y position of the text.
	 * @param	Width			The width of the text object (height is determined automatically).
	 * @param	Text			The actual text you would like to display initially.
	 * @param   size			Initial size of the font
	 * @param	TextColor		The color of the text
	 * @param	BackgroundColor	The color of the background (FlxColor.TRANSPARENT for no background color)
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not
	 */
	public function new(X:Float = 0, Y:Float = 0, Width:Int = 150, ?Text:String, size:Int = 8, TextColor:Int = FlxColor.BLACK,
			BackgroundColor:Int = FlxColor.WHITE, EmbeddedFont:Bool = true)
	{
		super(X, Y);

		textSprite = new FlxText(X + fieldBorderThickness, Y + fieldBorderThickness, Width, Text, size, EmbeddedFont);
		backgroundColor = BackgroundColor;

		if (BackgroundColor != FlxColor.TRANSPARENT)
			background = true;

		textSprite.color = TextColor;
		caretColor = TextColor;

		caret = new FlxSprite();
		caret.makeGraphic(caretWidth, Std.int(size + 2));
		_caretTimer = new FlxTimer();

		caretIndex = 0;
		hasFocus = false;
		if (background)
		{
			fieldBorderSprite = new FlxSprite(X, Y);
			backgroundSprite = new FlxSprite(X + fieldBorderThickness, Y + fieldBorderThickness);
			
			add(fieldBorderSprite);
			add(backgroundSprite);
		}

		add(textSprite);
		add(caret);

		lines = 1;
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		Application.current.window.onTextInput.add(onTextInput);

		if (Text == null)
			Text = "";

		text = Text; // ensure set_text is called to avoid bugs (like not preparing _charBoundaries on sys target, making it impossible to click)

		regenSprites();
	}

	/**
	 * Clean up memory
	 */
	override public function destroy():Void
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		Application.current.window.onTextInput.remove(onTextInput);

		callback = null;

		#if sys
		if (_charBoundaries != null)
		{
			while (_charBoundaries.length > 0)
			{
				_charBoundaries.pop();
			}
			_charBoundaries = null;
		}
		#end

		super.destroy();
	}

	/**
	 * Draw the caret in addition to the text.
	 */
	override public function draw():Void
	{
		// In case caretColor was changed
		if (caret != null && caretColor != caret.color || caret.height != textSprite.size + 2)
			caret.color = caretColor;

		super.draw();
	}

	/**
	 * Check for mouse input every tick.
	 */
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if FLX_MOUSE
		// Set focus and caretIndex as a response to mouse press
		if (FlxG.mouse.justPressed)
		{
			var hadFocus:Bool = hasFocus;
			var overlap = false;
			if (visible)
			{
				for (camera in cameras)
				{
					if (checkInput(FlxG.mouse, camera))
					{
						overlap = true;
						break;
					}
				}
			}
			if (overlap)
			{
				FlxG.mouse.onPress();
				caretIndex = getCaretIndex();
				hasFocus = true;
				if (!hadFocus && focusGained != null)
					focusGained();
			}
			else
			{
				hasFocus = false;
				if (hadFocus && focusLost != null)
					focusLost();
			}
		}
		#end
		if (hasFocus && FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.V)
			{
				var text = Clipboard.generalClipboard.getData(TEXT_FORMAT);
				if (text != null)
					onTextInput(text);
			}
			else if (FlxG.keys.justPressed.C)
				Clipboard.generalClipboard.setData(TEXT_FORMAT, text);
		}
	}

	function checkInput(pointer:FlxPointer, camera:FlxCamera):Bool
	{
		return textSprite.overlapsPoint(pointer.getWorldPosition(camera, _point), true, camera);
	}

	function onTextInput(text:String)
	{
		if (!hasFocus)
			return;
		var newText = this.text.substr(0, caretIndex) + text + this.text.substr(caretIndex);
		this.text = newText;
		caretIndex += text.length;
		onChange(INPUT_ACTION);
	}

	/**
	 * Handles keypresses generated on the stage.
	 */
	function onKeyDown(e:KeyboardEvent):Void
	{
		if (hasFocus)
		{
			var key:Int = e.keyCode;

			// Left arrow
			if (key == 37)
			{
				if (caretIndex > 0)
				{
					caretIndex--;
					text = text; // forces scroll update
				}
			}
			// Right arrow
			else if (key == 39)
			{
				if (caretIndex < text.length)
				{
					caretIndex++;
					text = text; // forces scroll update
				}
			}
			// End key
			else if (key == 35)
			{
				caretIndex = text.length;
				text = text; // forces scroll update
			}
			// Home key
			else if (key == 36)
			{
				caretIndex = 0;
				text = text;
			}
			// Backspace
			else if (key == 8)
			{
				if (caretIndex > 0)
				{
					caretIndex--;
					text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
					onChange(BACKSPACE_ACTION);
				}
			}
			// Delete
			else if (key == 46)
			{
				if (text.length > 0 && caretIndex < text.length)
				{
					text = text.substring(0, caretIndex) + text.substring(caretIndex + 1);
					onChange(DELETE_ACTION);
				}
			}
			// Enter
			else if (key == 13)
			{
				if (lines == -1)
					onTextInput("\n");
				else
				{
					hasFocus = false;
					if (focusLost != null)
						focusLost();
				}
				onChange(ENTER_ACTION);
			}
		}
	}

	function onChange(action:String):Void
	{
		if (callback != null)
			callback(text, action);
	}

	/**
	 * Inserts a substring into a string at a specific index
	 *
	 * @param	Insert			The string to have something inserted into
	 * @param	Insert			The string to insert
	 * @param	Index			The index to insert at
	 * @return					Returns the joined string for chaining.
	 */
	function insertSubstring(Original:String, Insert:String, Index:Int):String
	{
		if (Index != Original.length)
			Original = Original.substring(0, Index) + (Insert) + (Original.substring(Index));
		else
			Original = Original + (Insert);
		return Original;
	}

	/**
	 * Gets the index of the character in this box under the mouse cursor
	 * @return The index of the character.
	 *         between 0 and the length of the text
	 */
	function getCaretIndex():Int
	{
		#if FLX_MOUSE
		var hit = FlxPoint.get(FlxG.mouse.x - textSprite.x, FlxG.mouse.y - textSprite.y);
		return getCharIndexAtPoint(hit.x, hit.y);
		#else
		return 0;
		#end
	}

	function getCharBoundaries(charIndex:Int):Rectangle
	{
		if (_charBoundaries != null && charIndex >= 0 && _charBoundaries.length > 0)
		{
			var r:Rectangle = new Rectangle();
			if (charIndex >= _charBoundaries.length)
				_charBoundaries[_charBoundaries.length - 1].copyToFlash(r);
			else
				_charBoundaries[charIndex].copyToFlash(r);
			return r;
		}
		return null;
	}

	function getCharIndexAtPoint(X:Float, Y:Float):Int
	{
		var i:Int = 0;
		#if !js
		X += textSprite.textField.scrollH + 2;
		#end

		// offset X according to text alignment when there is no scroll.
		if (_charBoundaries != null && _charBoundaries.length > 0)
		{
			if (textSprite.textField.textWidth <= textSprite.textField.width)
			{
				switch (getAlignStr())
				{
					case RIGHT:
						X = X - textSprite.textField.width + textSprite.textField.textWidth;
					case CENTER:
						X = X - textSprite.textField.width / 2 + textSprite.textField.textWidth / 2;
					default:
				}
			}
		}

		// place caret at matching char position
		if (_charBoundaries != null)
		{
			for (r in _charBoundaries)
			{
				if (X >= r.left && X <= r.right)
				{
					return i;
				}
				i++;
			}
		}

		// place caret at rightmost position
		if (_charBoundaries != null && _charBoundaries.length > 0)
		{
			if (X > textSprite.textField.textWidth)
			{
				return _charBoundaries.length;
			}
		}

		// place caret at leftmost position
		return 0;
	}

	function prepareCharBoundaries(numChars:Int):Void
	{
		if (_charBoundaries == null)
			_charBoundaries = [];

		if (_charBoundaries.length > numChars)
		{
			var diff:Int = _charBoundaries.length - numChars;
			for (i in 0...diff)
				_charBoundaries.pop();
		}

		for (i in 0...numChars)
		{
			if (_charBoundaries.length - 1 < i)
				_charBoundaries.push(FlxRect.get(0, 0, 0, 0));
		}
	}

	/**
	 * Called every time the text is changed (for both flash/cpp) to update scrolling, etc
	 */
	function onSetTextCheck():Void
	{
		#if !js
		var boundary:Rectangle = null;
		if (caretIndex == -1)
			boundary = getCharBoundaries(text.length - 1);
		else
			boundary = getCharBoundaries(caretIndex);

		if (boundary != null)
		{
			// Checks if carret is out of textfield bounds
			// if it is update scroll, otherwise maintain the same scroll as last check.
			var diffW:Int = lastScroll;
			if (boundary.right > lastScroll + textSprite.textField.width - 2)
				diffW = -Std.int((textSprite.textField.width - 2) - boundary.right); // caret to the right of textfield.
			else if (boundary.left < lastScroll)
				diffW = Std.int(boundary.left) - 2; // caret to the left of textfield

			textSprite.textField.scrollH = diffW;
			regenSprites();
		}
		#end
	}

	/**
	 * Turns the caret on/off for the caret flashing animation.
	 */
	function toggleCaret(timer:FlxTimer):Void
	{
		caret.visible = !caret.visible;
	}

	/**
	 * Checks an input string against the current
	 * filter and returns a filtered string
	 */
	function filter(text:String):String
	{
		if (forceCase == UPPER_CASE)
			text = text.toUpperCase();
		else if (forceCase == LOWER_CASE)
			text = text.toLowerCase();

		if (filterMode != NO_FILTER)
		{
			var pattern:EReg;
			switch (filterMode)
			{
				case ONLY_ALPHA:
					pattern = ~/[^a-zA-Z]*/g;
				case ONLY_NUMERIC:
					pattern = ~/[^0-9]*/g;
				case ONLY_ALPHANUMERIC:
					pattern = ~/[^a-zA-Z0-9]*/g;
				case CUSTOM_FILTER:
					pattern = customFilterPattern;
				default:
					throw new Error("FlxInputText: Unknown filterMode (" + filterMode + ")");
			}
			text = pattern.replace(text, "");
		}
		return text;
	}

	function set_params(p:Array<Dynamic>):Array<Dynamic>
	{
		params = p;
		if (params == null)
			params = [];
		var namedValue:NamedString = {name: "value", value: text};
		params.push(namedValue);
		return p;
	}

	function set_hasFocus(newFocus:Bool):Bool
	{
		if (newFocus)
		{
			if (hasFocus != newFocus)
			{
				_caretTimer = new FlxTimer().start(0.5, toggleCaret, 0);
				caret.visible = true;
				caretIndex = text.length;
			}
		}
		else
		{
			// Graphics
			caret.visible = false;
			if (_caretTimer != null)
				_caretTimer.cancel();
		}

		if (newFocus != hasFocus)
			regenSprites();
		return hasFocus = newFocus;
	}

	function getAlignStr():FlxTextAlign
	{
		var alignStr:FlxTextAlign = LEFT;
		if (textSprite.alignment != null)
			alignStr = textSprite.alignment;
		return alignStr;
	}

	function set_caretIndex(newCaretIndex:Int):Int
	{
		var offx:Float = 0;

		var alignStr:FlxTextAlign = getAlignStr();

		switch (alignStr)
		{
			case RIGHT:
				offx = textSprite.textField.width - 2 - textSprite.textField.textWidth - 2;
				if (offx < 0)
					offx = 0; // hack, fix negative offset.

			case CENTER:
				#if !js
				offx = (textSprite.textField.width - 2 - textSprite.textField.textWidth) / 2 + textSprite.textField.scrollH / 2;
				#end
				if (offx <= 1)
					offx = 0; // hack, fix ofset rounding alignment.

			default:
				offx = 0;
		}

		caretIndex = newCaretIndex;

		// If caret is too far to the right something is wrong
		if (caretIndex > (text.length + 1))
			caretIndex = -1;

		// Caret is OK, proceed to position
		if (caretIndex != -1)
		{
			var boundaries:Rectangle = null;

			// Caret is not to the right of text
			if (caretIndex < text.length)
			{
				boundaries = getCharBoundaries(caretIndex);
				if (boundaries != null)
				{
					caret.x = offx + boundaries.left + textSprite.x;
					caret.y = boundaries.top + textSprite.y;
				}
			}
			// Caret is to the right of text
			else
			{
				boundaries = getCharBoundaries(caretIndex - 1);
				if (boundaries != null)
				{
					caret.x = offx + boundaries.right + textSprite.x;
					caret.y = boundaries.top + textSprite.y;
				}
				// Text box is empty
				else if (text.length == 0)
				{
					// 2 px gutters
					caret.x = textSprite.x + offx + 2;
					caret.y = textSprite.y + 2;
				}
			}
		}

		#if !js
		caret.x -= textSprite.textField.scrollH;
		#end

		// Make sure the caret doesn't leave the textfield on single-line input texts
		if ((lines == 1) && (caret.x + caret.width) > (textSprite.x + textSprite.width))
			caret.x = textSprite.x + textSprite.width - 2;

		return caretIndex;
	}

	function set_forceCase(Value:Int):Int
	{
		forceCase = Value;
		text = filter(text);
		return forceCase;
	}

	public function changeSize(Value:Int):Int
	{
		textSprite.size = Value;
		caret.makeGraphic(1, Std.int(textSprite.size + 2));
		return Value;
	}

	function set_maxLength(Value:Int):Int
	{
		maxLength = Value;
		if (text.length > maxLength)
			text = text.substring(0, maxLength);
		return maxLength;
	}

	function set_lines(Value:Int):Int
	{
		if (Value == 0)
			return 0;

		if (Value > 1 || Value == -1)
		{
			textSprite.textField.wordWrap = true;
			textSprite.textField.multiline = true;
		}
		else
		{
			textSprite.textField.wordWrap = false;
			textSprite.textField.multiline = false;
		}

		lines = Value;
		regenSprites();
		return lines;
	}

	function get_passwordMode():Bool
	{
		return textSprite.textField.displayAsPassword;
	}

	function set_passwordMode(value:Bool):Bool
	{
		textSprite.textField.displayAsPassword = value;
		regenSprites();
		return value;
	}

	function set_filterMode(Value:Int):Int
	{
		filterMode = Value;
		text = filter(text);
		return filterMode;
	}

	function set_fieldBorderColor(Value:Int):Int
	{
		fieldBorderColor = Value;
		regenSprites();
		return fieldBorderColor;
	}

	function set_fieldBorderThickness(Value:Int):Int
	{
		fieldBorderThickness = Value;
		regenSprites();
		return fieldBorderThickness;
	}

	function set_backgroundColor(Value:Int):Int
	{
		backgroundColor = Value;
		regenSprites();
		return backgroundColor;
	}

	public function regenSprites()
	{
		if (fieldBorderSprite != null)
		{
			if (fieldBorderThickness > 0)
			{
				fieldBorderSprite.makeGraphic(Std.int(textSprite.width + fieldBorderThickness * 2), Std.int(textSprite.height + fieldBorderThickness * 2),
					fieldBorderColor);
				fieldBorderSprite.x = x;
				fieldBorderSprite.y = y;
			}
			else if (fieldBorderThickness == 0)
				fieldBorderSprite.visible = false;
		}

		if (backgroundSprite != null)
		{
			if (background)
			{
				backgroundSprite.makeGraphic(Std.int(textSprite.width), Std.int(textSprite.height), backgroundColor);
				backgroundSprite.x = x + fieldBorderThickness;
				backgroundSprite.y = y + fieldBorderThickness;
			}
			else
				backgroundSprite.visible = false;
		}

		if (textSprite != null)
		{
			textSprite.updateHitbox();
			textSprite.updateFramePixels();
			textSprite.x = x + fieldBorderThickness;
			textSprite.y = y + fieldBorderThickness;
		}

		if (caret != null)
		{
			// Generate the properly sized caret and also draw a border that matches that of the textfield (if a border style is set)
			// borderQuality can be safely ignored since the caret is always a rectangle

			var cw:Int = caretWidth; // Basic size of the caret
			var ch:Int = Std.int(textSprite.size + 2);

			// Make sure alpha channels are correctly set
			var borderC:Int = (0xff000000 | (textSprite.borderColor & 0x00ffffff));
			var caretC:Int = (0xff000000 | (caretColor & 0x00ffffff));

			// Generate unique key for the caret so we don't cause weird bugs if someone makes some random flxsprite of this size and color
			var caretKey:String = "caret" + cw + "x" + ch + "c:" + caretC + "b:" + textSprite.borderStyle + "," + textSprite.borderSize + "," + borderC;
			switch (textSprite.borderStyle)
			{
				case NONE:
					// No border, just make the caret
					caret.makeGraphic(cw, ch, caretC, false, caretKey);
					caret.offset.x = caret.offset.y = 0;

				case SHADOW:
					// Shadow offset to the lower-right
					cw += Std.int(textSprite.borderSize);
					ch += Std.int(textSprite.borderSize); // expand canvas on one side for shadow
					caret.makeGraphic(cw, ch, FlxColor.TRANSPARENT, false, caretKey); // start with transparent canvas
					var r:Rectangle = new Rectangle(textSprite.borderSize, textSprite.borderSize, caretWidth, Std.int(textSprite.size + 2));
					caret.pixels.fillRect(r, borderC); // draw shadow
					r.x = r.y = 0;
					caret.pixels.fillRect(r, caretC); // draw caret
					caret.offset.x = caret.offset.y = 0;

				case OUTLINE_FAST, OUTLINE:
					// Border all around it
					cw += Std.int(textSprite.borderSize * 2);
					ch += Std.int(textSprite.borderSize * 2); // expand canvas on both sides
					caret.makeGraphic(cw, ch, borderC, false, caretKey); // start with borderColor canvas
					var r = new Rectangle(textSprite.borderSize, textSprite.borderSize, caretWidth, Std.int(textSprite.size + 2));
					caret.pixels.fillRect(r, caretC); // draw caret
					// we need to offset caret's drawing position since the caret is now larger than normal
					caret.offset.x = caret.offset.y = textSprite.borderSize;
			}
			// Update width/height so caret's dimensions match its pixels
			caret.width = cw;
			caret.height = ch;

			caretIndex = caretIndex; // force this to update
		}
	}

	function get_text()
	{
		return textSprite.text;
	}

	function set_text(Text:String)
	{
		#if !js
		if (textSprite.textField != null)
		{
			lastScroll = textSprite.textField.scrollH;
		}
		#end
		var return_text:String = textSprite.text = Text;

		if (textSprite.textField == null)
			return return_text;

		var numChars:Int = Text.length;
		prepareCharBoundaries(numChars);
		textSprite.textField.text = "";
		var textH:Float = 0;
		var textW:Float = 0;
		var lastW:Float = 0;

		// Flash textFields have a "magic number" 2 pixel gutter all around
		// It does not seem to vary with font, size, border, etc, and does not seem to be customizable.
		// We simply reproduce this behavior here
		var magicX:Float = 2;
		var magicY:Float = 2;

		for (i in 0...numChars)
		{
			textSprite.textField.appendText(Text.substr(i, 1)); // add a character
			textW = textSprite.textField.textWidth; // count up total text width
			if (i == 0)
				textH = textSprite.textField.textHeight; // count height after first char
			_charBoundaries[i].x = magicX + lastW; // place x at end of last character
			_charBoundaries[i].y = magicY; // place y at zero
			_charBoundaries[i].width = (textW - lastW); // place width at (width so far) minus (last char's end point)
			_charBoundaries[i].height = textH;
			lastW = textW;
		}
		textSprite.textField.text = Text;
		onSetTextCheck();
		return return_text;
	}

	public function resize(w:Float, h:Float):Void
	{
		textSprite.fieldWidth = w;
		textSprite.updateHitbox();
		regenSprites();
	}
}
