package flixel.transition;

import flixel.transition.TransitionData.TransitionType;
import flixel.transition.TransitionEffect;
import flixel.transition.TransitionFade;
import flixel.transition.TransitionTiles;
import flixel.transition.FlxTransitionSprite.TransitionStatus;
import flixel.FlxSubState;
import flixel.util.FlxColor;

/**
 * This substate is automatically created to play the actual transition visuals inside a FlxTransitionState.
 * To achieve a specific effect, you should use a sub-class of this such as TileTransition or FadeTransition
 * @author Tim Hely, larsiusprime
 */
class Transition extends FlxSubState
{
	public var finishCallback(get, set):Void->Void;

	var _effect:TransitionEffect;

	public function new(data:TransitionData)
	{
		var cam = new FlxCamera(0, 0, Std.int(data.region.width), Std.int(data.region.height));
		cam.bgColor = 0;
		cam.setSize(Std.int(data.region.width), Std.int(data.region.height));
		FlxG.cameras.add(cam, false);
		cameras = [cam];

		super(FlxColor.TRANSPARENT);
		_effect = createEffect(data);
		_effect.scrollFactor.set(0, 0);
		add(_effect);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		_effect.update(elapsed);
	}

	public override function destroy():Void
	{
		super.destroy();
		finishCallback = null;
		_effect.destroy();
		_effect = null;
	}

	public function start(NewStatus:TransitionStatus):Void
	{
		_effect.start(NewStatus);
	}

	public function setStatus(NewStatus:TransitionStatus):Void
	{
		_effect.setStatus(NewStatus);
	}

	function createEffect(Data:TransitionData):TransitionEffect
	{
		switch (Data.type)
		{
			case TransitionType.TILES:
				return new TransitionTiles(Data);
			case TransitionType.FADE:
				return new TransitionFade(Data);
			default:
				return null;
		}
	}

	function get_finishCallback():Void->Void
	{
		if (_effect != null)
		{
			return _effect.finishCallback;
		}
		return null;
	}

	function set_finishCallback(f:Void->Void):Void->Void
	{
		if (_effect != null)
		{
			_effect.finishCallback = f;
			return f;
		}
		return null;
	}
}
