package flixel.ui;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxUI.NamedFloat;
import flixel.ui.interfaces.IFlxUIClickable;
import flixel.ui.interfaces.IFlxUIWidget;
import flixel.ui.interfaces.IHasParams;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxStringUtil;

class FlxUINumericStepper extends FlxUIGroup implements IFlxUIWidget implements IFlxUIClickable implements IHasParams
{
	public var button_plus:FlxUITypedButton<FlxSprite>;
	public var button_minus:FlxUITypedButton<FlxSprite>;
	public var text_field:FlxInputText;

	public var stepSize:Float = 0;
	public var defaultValue:Float = 0;
	public var decimals(default, set):Int = 0; // Number of decimals
	public var min(default, set):Float = 0;
	public var max(default, set):Float = 10;
	public var value(default, set):Float = 0;
	public var stack(default, set):Int = STACK_HORIZONTAL;
	public var isPercent(default, set):Bool = false;
	public var callback:String->Float->Void;

	public static inline var STACK_VERTICAL:Int = 0;
	public static inline var STACK_HORIZONTAL:Int = 1;

	public static inline var CLICK_EVENT:String = "click_numeric_stepper"; // click a numeric stepper button
	public static inline var EDIT_EVENT:String = "edit_numeric_stepper"; // edit the numeric stepper text field
	public static inline var CHANGE_EVENT:String = "change_numeric_stepper"; // do either of the above

	var lastText = '';

	public var params(default, set):Array<Dynamic>;

	private function set_params(p:Array<Dynamic>):Array<Dynamic>
	{
		params = p;
		return params;
	}

	public var skipButtonUpdate(default, set):Bool;

	private function set_skipButtonUpdate(b:Bool):Bool
	{
		skipButtonUpdate = b;
		button_plus.skipButtonUpdate = b;
		button_minus.skipButtonUpdate = b;
		// TODO: Handle input text
		return b;
	}

	private override function set_color(Value:Int):Int
	{
		color = Value;
		button_plus.color = Value;
		button_minus.color = Value;
		text_field.backgroundColor = Value;
		return Value;
	}

	private function set_min(f:Float):Float
	{
		min = f;
		if (value < min)
			value = min;
		return min;
	}

	private function set_max(f:Float):Float
	{
		max = f;
		if (value > max)
			value = max;
		return max;
	}

	private function set_value(f:Float):Float
	{
		value = f;
		if (value < min)
			value = min;
		if (value > max)
			value = max;
		value = decimalize(value, decimals);
		if (text_field != null && !text_field.hasFocus)
		{
			var displayValue:Float = value;
			if (isPercent)
			{
				displayValue *= 100;
				text_field.text = Std.string(decimalize(displayValue, decimals)) + "%";
			}
			else
				text_field.text = Std.string(displayValue);
		}
		return value;
	}

	private function set_decimals(i:Int):Int
	{
		decimals = i;
		if (i < 0)
			decimals = 0;
		value = value;
		return decimals;
	}

	private function set_isPercent(b:Bool):Bool
	{
		isPercent = b;
		value = value;
		return isPercent;
	}

	private function set_stack(s:Int):Int
	{
		stack = s;
		var btnSize:Int = 10;
		switch (stack)
		{
			case STACK_HORIZONTAL:
				btnSize = cast text_field.height;
				if (button_plus.height != btnSize)
					button_plus.resize(btnSize, btnSize);
				if (button_minus.height != btnSize)
					button_minus.resize(btnSize, btnSize);
				button_plus.x = text_field.x + text_field.width;
				button_plus.y = text_field.y;
				button_minus.x = button_plus.x + button_plus.width;
				button_minus.y = button_plus.y;
			case STACK_VERTICAL:
				btnSize = cast text_field.height / 2;
				if (button_plus.height != btnSize)
					button_plus.resize(btnSize, btnSize);
				if (button_minus.height != btnSize)
					button_minus.resize(btnSize, btnSize);
				button_plus.x = text_field.x + text_field.width;
				button_plus.y = text_field.y;
				button_minus.x = text_field.x + text_field.width;
				button_minus.y = text_field.y + (text_field.height - button_minus.height);
		}
		return stack;
	}

	private inline function decimalize(f:Float, digits:Int):Float
	{
		var tens:Float = Math.pow(10, digits);
		return Math.round(f * tens) / tens;
	}

	/**
	 * This creates a new dropdown menu.
	 *
	 * @param	X					x position of the dropdown menu
	 * @param	Y					y position of the dropdown menu
	 * @param	StepSize			How big is the step
	 * @param	DefaultValue		Optional default numerical value for the stepper to display
	 * @param	Min					Optional Minimum values for the stepper
	 * @param	Max					Optional Maximum and Minimum values for the stepper
	 * @param	Decimals			Optional # of decimal places
	 * @param	Stack				Stacking method
	 * @param	TextField			Optional text field
	 * @param	ButtonPlus			Optional button to use for plus
	 * @param	ButtonMinus			Optional button to use for minus
	 * @param	IsPercent			Whether to portray the number as a percentage
	 */
	public function new(X:Float = 0, Y:Float = 0, StepSize:Float = 1, DefaultValue:Float = 0, Min:Float = -999, Max:Float = 999, Decimals:Int = 0,
			Stack:Int = STACK_HORIZONTAL, ?TextField:FlxInputText, ?ButtonPlus:FlxUITypedButton<FlxSprite>, ?ButtonMinus:FlxUITypedButton<FlxSprite>,
			IsPercent:Bool = false)
	{
		super(X, Y);

		if (TextField == null)
			TextField = new FlxUIInputText(0, 0, 25);
		TextField.x = 0;
		TextField.y = 0;
		text_field = TextField;
		text_field.text = Std.string(DefaultValue);
		text_field.lines = 1;
		text_field.focusLost = _onInputTextEvent; // internal communication only

		if ((text_field is FlxUIInputText))
		{
			var fuit:FlxUIInputText = cast text_field;
			fuit.broadcastToFlxUI = false;
		}

		stepSize = StepSize;
		defaultValue = DefaultValue;
		decimals = Decimals;
		min = Min;
		max = Max;
		value = DefaultValue;
		isPercent = IsPercent;

		var btnSize:Int = 1 + cast TextField.height;

		if (ButtonPlus == null)
		{
			ButtonPlus = new FlxUITypedButton<FlxSprite>(0, 0);
			ButtonPlus.loadGraphicSlice9([FlxUIAssets.IMG_BUTTON_THIN], btnSize, btnSize, [FlxStringUtil.toIntArray(FlxUIAssets.SLICE9_BUTTON_THIN)],
				FlxUI9SliceSprite.TILE_NONE, -1, false, FlxUIAssets.IMG_BUTTON_SIZE, FlxUIAssets.IMG_BUTTON_SIZE);
			ButtonPlus.label = new FlxSprite(0, 0, FlxUIAssets.IMG_PLUS);
		}
		if (ButtonMinus == null)
		{
			ButtonMinus = new FlxUITypedButton<FlxSprite>(0, 0);
			ButtonMinus.loadGraphicSlice9([FlxUIAssets.IMG_BUTTON_THIN], btnSize, btnSize, [FlxStringUtil.toIntArray(FlxUIAssets.SLICE9_BUTTON_THIN)],
				FlxUI9SliceSprite.TILE_NONE, -1, false, FlxUIAssets.IMG_BUTTON_SIZE, FlxUIAssets.IMG_BUTTON_SIZE);
			ButtonMinus.label = new FlxSprite(0, 0, FlxUIAssets.IMG_MINUS);
		}

		button_plus = ButtonPlus;
		button_minus = ButtonMinus;

		add(text_field);
		add(button_plus);
		add(button_minus);

		button_plus.onUp.callback = _onPlus;
		button_plus.broadcastToFlxUI = false;

		button_minus.onUp.callback = _onMinus;
		button_minus.broadcastToFlxUI = false;

		stack = Stack;

		lastText = text_field.text;
	}

	private function _onInputTextEvent():Void
	{
		var text = text_field.text;
		if (text == lastText)
			return; // dont continue if nothing actually changed

		var numDecimals:Int = 0;
		for (i in 0...text.length)
		{
			var char = text.charAt(i);
			if (char == ".")
			{
				numDecimals++;
			}
		}

		var justAddedDecimal = (numDecimals == 1 && text.indexOf(".") == text.length - 1);

		// if I just added a decimal don't treat that as having changed the value just yet
		if (!justAddedDecimal)
		{
			var realValue = Std.parseFloat(text);
			if (Math.isNaN(realValue))
				realValue = defaultValue;
			else if (isPercent)
				realValue /= 100;

			value = realValue;
			_doCallback(EDIT_EVENT);
			_doCallback(CHANGE_EVENT);
		}

		lastText = text_field.text;
	}

	private function _onPlus():Void
	{
		value += stepSize * (FlxG.keys.pressed.SHIFT ? 10 : 1);
		_doCallback(CLICK_EVENT);
		_doCallback(CHANGE_EVENT);
	}

	private function _onMinus():Void
	{
		value -= stepSize * (FlxG.keys.pressed.SHIFT ? 10 : 1);
		_doCallback(CLICK_EVENT);
		_doCallback(CHANGE_EVENT);
	}

	private function _doCallback(event_name:String):Void
	{
		if (callback != null)
			callback(event_name, value);
		
		if (broadcastToFlxUI)
			FlxUI.event(event_name, this, value, params);
	}
}