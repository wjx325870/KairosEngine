package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.transition.FlxTransitionableState;
import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
	// 左侧菜单项（完全对应你的文件）
	var menuItems:Array<String> = [
		'Gameplay',
		'Graphics',
		'Audio',
		'Controls',
		'Visuals',
		'Mods',
		'Language'
	];

	var grpMenu:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;

	// 右侧内容容器
	var rightPanel:FlxSprite;
	var currentSubState:MusicBeatSubState;

	public static var onPlayState:Bool = false;

	override function create()
	{
		super.create();

		// 背景（沿用原版）
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		add(bg);

		// 创建左侧菜单
		grpMenu = new FlxTypedGroup<Alphabet>();
		add(grpMenu);

		for (i => item in menuItems)
		{
			var menuText:Alphabet = new Alphabet(0, 0, item, true);
			menuText.x = 50; // 固定在左侧
			menuText.y = 100 + i * 80; // 垂直间距
			menuText.ID = i;
			grpMenu.add(menuText);
		}

		// 右侧面板背景
		rightPanel = new FlxSprite(400, 50).makeGraphic(850, 550, 0xFF2A2A2A);
		rightPanel.alpha = 0.9;
		add(rightPanel);

		// 初始化显示第一个菜单项
		changeSelection(0);

		ClientPrefs.saveSettings();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			openSelectedSubState(menuItems[curSelected]);
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else
				MusicBeatState.switchState(new MainMenuState());
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);

		for (i => item in grpMenu.members)
		{
			item.alpha = (i == curSelected) ? 1.0 : 0.6;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));
		openSelectedSubState(menuItems[curSelected]);
	}

	function openSelectedSubState(selected:String)
	{
		if (currentSubState != null)
		{
			remove(currentSubState);
			currentSubState.destroy();
		}

		switch (selected)
		{
			case 'Gameplay':
				currentSubState = new options.GameplaySettingsSubState();
			case 'Graphics':
				currentSubState = new options.GraphicsSettingsSubState();
			case 'Audio':
				currentSubState = new options.AudioSettingsSubState();
			case 'Controls':
				currentSubState = new options.ControlsSubState();
			case 'Visuals':
				currentSubState = new options.VisualsSettingsSubState();
			case 'Mods':
				// Mods 是一个完整状态，直接切换
				MusicBeatState.switchState(new options.ModSettingsSubState());
				return;
			case 'Language':
				currentSubState = new options.LanguageSubState();
			default:
				return;
		}

		if (currentSubState != null)
		{
			currentSubState.setPosition(410, 60);
			currentSubState.setGraphicSize(830, 530);
			currentSubState.camera = null;
			add(currentSubState);
		}
	}

	override function destroy()
	{
		super.destroy();
		ClientPrefs.loadPrefs();
	}
}