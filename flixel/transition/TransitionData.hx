package flixel.transition;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

@:enum
abstract TransitionType(String)
{
	var NONE = "none";
	var TILES = "tiles";
	var FADE = "fade";
}

typedef TransitionTileData =
{
	asset:FlxGraphicAsset,
	width:Int,
	height:Int,
	?frameRate:Int
}

/**
 * @author larsiusprime
 */
class TransitionData implements IFlxDestroyable
{
	public var type:TransitionType;
	public var tileData:TransitionTileData;
	public var color:FlxColor;
	public var duration:Float = 1.0;
	public var direction:FlxPoint;
	public var tweenOptions:TweenOptions;
	public var region:FlxRect;

	public function destroy():Void
	{
		tileData = null;
		direction = FlxDestroyUtil.put(direction);
		tweenOptions.onComplete = null;
		tweenOptions.ease = null;
		tweenOptions = null;
		region = FlxDestroyUtil.put(region);
	}

	public function new(TransType:TransitionType = FADE, Color:FlxColor = FlxColor.WHITE, Duration:Float = 1.0, ?Direction:FlxPoint,
			?TileData:TransitionTileData, ?Region:FlxRect)
	{
		type = TransType;
		tileData = TileData;
		duration = Duration;
		color = Color;
		direction = Direction;
		if (direction == null)
		{
			direction = FlxPoint.get(0, 0);
		}
		direction.x = FlxMath.bound(direction.x, -1, 1);
		direction.y = FlxMath.bound(direction.y, -1, 1);
		tweenOptions = {onComplete: null};
		region = Region;
		if (Region == null)
		{
			region = FlxRect.get(0, 0, FlxG.width, FlxG.height);
		}
	}
}
