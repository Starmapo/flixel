package flixel.ui.interfaces;

import flixel.ui.FlxUIText;
import flixel.text.FlxText;

/**
 * ...
 * @author Lars Doucet
 */
interface ILabeled
{
	function getLabel():FlxUIText;
	function setLabel(t:FlxUIText):FlxUIText;
}
