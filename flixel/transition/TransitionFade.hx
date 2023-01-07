package flixel.transition;

import flash.display.BitmapData;
import flixel.FlxSprite;
import flixel.transition.FlxTransitionSprite.TransitionStatus;
import flixel.transition.TransitionEffect;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BitmapDataChannel;
import openfl.geom.Matrix;
import openfl.geom.Point;

@:keep @:bitmap("assets/images/transitions/diagonal_gradient.png")
private class GraphicDiagonalGradient extends BitmapData {}

/**
 *
 * @author larsiusprime
 */
class TransitionFade extends TransitionEffect
{
	var gradient:FlxSprite;
	var back:FlxSprite;
	var tweenStr:String = "";
	var tweenStr2:String = "";
	var tweenValStart:Float = 0;
	var tweenValStart2:Float = 0;
	var tweenValEnd:Float = 0;
	var tweenValEnd2:Float = 0;

	public function new(data:TransitionData)
	{
		super(data);

		var region = _data.region;

		var dirX = _data.direction.x;
		var dirY = _data.direction.y;
		if (dirX == 0 && dirY != 0)
		{
			// vertical wipe
			back = new FlxSprite(region.x, region.y).makeGraphic(Std.int(region.width), Std.int(region.height), _data.color);
			add(back);
			gradient = new FlxSprite(region.x, region.y);
			var angle = dirY > 0 ? 90 : 270;
			gradient.pixels = FlxGradient.createGradientBitmapData(1, Std.int(region.height), [_data.color, FlxColor.TRANSPARENT], 1, angle);
			gradient.scale.x = region.width;
			gradient.updateHitbox();
			add(gradient);
		}
		else if (dirX != 0 && dirY == 0)
		{
			// horizontal wipe
			back = new FlxSprite(region.x, region.y).makeGraphic(Std.int(region.width), Std.int(region.height), _data.color);
			add(back);
			gradient = new FlxSprite(region.x, region.y);
			var angle = dirX > 0 ? 0 : 180;
			gradient.pixels = FlxGradient.createGradientBitmapData(Std.int(region.width), 1, [_data.color, FlxColor.TRANSPARENT], 1, angle);
			gradient.scale.y = region.height;
			gradient.updateHitbox();
			add(gradient);
		}
		else if (dirX != 0 && dirY != 0)
		{
			gradient = new FlxSprite(region.x, region.y);
			gradient.loadGraphic(getGradient());
			gradient.flipX = dirX < 0;
			gradient.flipY = dirY < 0;
			add(gradient);
		}
		else
		{
			back = new FlxSprite(region.x, region.y).makeGraphic(Std.int(region.width), Std.int(region.height), _data.color);
			add(back);
		}
	}

	public override function destroy():Void
	{
		super.destroy();
		back = null;
		gradient = null;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (back != null && gradient != null)
		{
			if (_data.direction.x > 0)
			{
				back.x = gradient.x - back.width;
			}
			else if (_data.direction.x < 0)
			{
				back.x = gradient.x + gradient.width;
			}
			if (_data.direction.y > 0)
			{
				back.y = gradient.y - back.height;
			}
			else if (_data.direction.y < 0)
			{
				back.y = gradient.y + gradient.height;
			}
		}
	}

	public override function start(NewStatus:TransitionStatus):Void
	{
		super.start(NewStatus);

		setTweenValues(NewStatus, _data.direction.x, _data.direction.y);

		var mainSprite = (gradient == null) ? back : gradient;
		switch (tweenStr)
		{
			case "alpha":
				mainSprite.alpha = tweenValStart;
			case "x":
				mainSprite.x = tweenValStart;
			case "y":
				mainSprite.y = tweenValStart;
		}
		switch (tweenStr2)
		{
			case "alpha":
				mainSprite.alpha = tweenValStart2;
			case "x":
				mainSprite.x = tweenValStart2;
			case "y":
				mainSprite.y = tweenValStart2;
		}

		var Values:Dynamic = {};
		Reflect.setField(Values, tweenStr, tweenValEnd);
		if (tweenStr2 != "")
		{
			Reflect.setField(Values, tweenStr2, tweenValEnd2);
		}
		_data.tweenOptions.onComplete = finishTween;
		FlxTween.tween(mainSprite, Values, _data.duration, _data.tweenOptions);
	}

	function setTweenValues(NewStatus:TransitionStatus, DirX:Float, DirY:Float):Void
	{
		var region = _data.region;
		if (DirX == 0 && DirY == 0)
		{
			// no direction
			tweenStr = "alpha";
			tweenValStart = NewStatus == IN ? 0.0 : 1.0;
			tweenValEnd = NewStatus == IN ? 1.0 : 0.0;
		}
		else if (DirX != 0 && DirY == 0)
		{
			// horizontal wipe
			tweenStr = "x";
			if (DirX > 0)
			{
				tweenValStart = NewStatus == IN ? region.x - gradient.width : region.x + region.width;
				tweenValEnd = NewStatus == IN ? region.x + region.width : region.x - gradient.width;
			}
			else
			{
				tweenValStart = NewStatus == IN ? region.x + region.width : region.x - gradient.width;
				tweenValEnd = NewStatus == IN ? region.x - gradient.width : region.x + region.width;
			}
		}
		else if ((DirX == 0 && DirY != 0))
		{
			// vertical wipe
			tweenStr = "y";
			if (DirY > 0)
			{
				tweenValStart = NewStatus == IN ? region.y - gradient.height : region.y + region.height;
				tweenValEnd = NewStatus == IN ? region.y + region.height : region.y - gradient.height;
			}
			else
			{
				tweenValStart = NewStatus == IN ? region.y + region.height : region.y - gradient.height;
				tweenValEnd = NewStatus == IN ? region.y - gradient.height : region.y + region.height;
			}
		}
		else if (DirX != 0 && DirY != 0)
		{
			// diagonal wipe
			tweenStr = "x";
			tweenStr2 = "y";
			if (DirX > 0)
			{
				tweenValStart = NewStatus == IN ? region.x - gradient.width : region.x;
				tweenValEnd = NewStatus == IN ? region.x : region.x - gradient.width;
			}
			else
			{
				tweenValStart = NewStatus == IN ? region.x + region.width : region.x - gradient.width * (2 / 3);
				tweenValEnd = NewStatus == IN ? region.x - gradient.width * (2 / 3) : region.x + region.width;
			}
			if (DirY > 0)
			{
				tweenValStart2 = NewStatus == IN ? region.y - gradient.height : region.y;
				tweenValEnd2 = NewStatus == IN ? region.y : region.y - gradient.height;
			}
			else
			{
				tweenValStart2 = NewStatus == IN ? region.y + region.height : region.y - gradient.height * (2 / 3);
				tweenValEnd2 = NewStatus == IN ? region.y - gradient.height * (2 / 3) : region.y + region.height;
			}
		}
	}

	function getGradient():BitmapData
	{
		// TODO: this could perhaps be optimized a lot by creating a single-pixel wide sprite, rotating it, scaling it super big, and positioning it properly
		var region = _data.region;
		var rawBmp = new GraphicDiagonalGradient(0, 0);
		var gdiag:BitmapData = cast rawBmp;
		var gdiag_scaled:BitmapData = new BitmapData(Std.int(region.width * 2), Std.int(region.height * 2), true, FlxColor.TRANSPARENT);
		var m:Matrix = new Matrix();
		m.scale(gdiag_scaled.width / gdiag.width, gdiag_scaled.height / gdiag.height);
		gdiag_scaled.draw(gdiag, m, null, null, null, true);
		var theColor:FlxColor = _data.color;
		var final_pixels:BitmapData = new BitmapData(Std.int(region.width * 3), Std.int(region.height * 3), true, theColor);
		final_pixels.copyChannel(gdiag_scaled, gdiag_scaled.rect,
			new Point(final_pixels.width - gdiag_scaled.width, final_pixels.height - gdiag_scaled.height), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		gdiag.dispose();
		gdiag_scaled.dispose();
		return final_pixels;
	}

	function finishTween(f:FlxTween):Void
	{
		delayThenFinish();
	}
}
