package freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.Song;
import backend.WeekData;
import backend.Highscore;
import objects.HealthIcon;
import states.MainMenuState;
import ui.Mobilecontrols; // 引入手机触控

class FreeplayState extends MusicBeatState
{
	// 歌曲数据
	var songs:Array<SongMetadata> = [];
	var curSelected:Int = 0;
	var curDifficulty:Int = 1; // 默认 Normal
	
	// UI 组件
	var grpSongs:FlxTypedGroup<Alphabet>;
	var songIcons:FlxTypedGroup<HealthIcon>;
	
	// 难度选择条
	var diffBar:FlxSprite;
	var diffTexts:FlxTypedGroup<FlxText>;
	
	// 手机触控按钮
	var mobileControls:Mobilecontrols;
	
	// 左下角版本信息
	var versionText:FlxText;
	
	override function create()
	{
		super.create();
		
		// 加载歌曲列表
		loadSongs();
		
		// 背景
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);
		
		// 创建歌曲列表
		grpSongs = new FlxTypedGroup<Alphabet>();
		songIcons = new FlxTypedGroup<HealthIcon>();
		add(grpSongs);
		add(songIcons);
		
		for (i => song in songs)
		{
			var songText:Alphabet = new Alphabet(100, 0, song.songName, true);
			songText.targetY = i;
			songText.y = 150 + i * 100;
			grpSongs.add(songText);
			
			var icon:HealthIcon = new HealthIcon(song.icon);
			icon.sprTracker = songText;
			icon.x = 600;
			songIcons.add(icon);
		}
		
		// 创建难度选择条（顶部）
		diffBar = new FlxSprite(0, 30).makeGraphic(FlxG.width, 60, 0xFF2A2A2A);
		diffBar.alpha = 0.8;
		add(diffBar);
		
		diffTexts = new FlxTypedGroup<FlxText>();
		add(diffTexts);
		
		var difficulties = ['EASY', 'NORMAL', 'HARD'];
		var diffX:Float = FlxG.width / 2 - 200;
		for (i => diff in difficulties)
		{
			var txt:FlxText = new FlxText(diffX + i * 180, 45, 0, diff, 28);
			txt.setFormat(Paths.font("vcr.ttf"), 28, (i == curDifficulty) ? 0xFF00C8B0 : FlxColor.WHITE);
			diffTexts.add(txt);
		}
		
		// 创建手机触控按钮
		#if mobile
		mobileControls = new Mobilecontrols();
		mobileControls.mode = HITBOX; // 或者 VIRTUALPAD_RIGHT，根据你想要的模式
		mobileControls.scrollFactor.set();
		add(mobileControls);
		#end
		
		// 左下角版本信息
		versionText = new FlxText(10, FlxG.height - 30, 0, 
			"Kairos Engine V1   Psych Engine 1.0.4   Friday Night Funkin' v0.2.8", 12);
		versionText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.LIGHT_GRAY);
		versionText.scrollFactor.set();
		add(versionText);
		
		changeSelection(0);
	}
	
	function loadSongs()
	{
		// 从 WeekData 加载歌曲（原版逻辑）
		var weeks:Array<WeekData> = WeekData.loadWeeks();
		for (week in weeks)
		{
			for (song in week.songs)
			{
				songs.push(new SongMetadata(song[0], week.weekCharacters[0], song[1]));
			}
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		// 键盘控制（保留，方便调试）
		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);
		if (controls.UI_LEFT_P)
			changeDifficulty(-1);
		if (controls.UI_RIGHT_P)
			changeDifficulty(1);
		
		// 手机触控按钮：A 确认，B 返回
		#if mobile
		if (mobileControls != null)
		{
			if (mobileControls.buttonA != null && mobileControls.buttonA.justPressed)
				selectSong();
			if (mobileControls.buttonB != null && mobileControls.buttonB.justPressed)
				goBack();
		}
		#end
		
		// 键盘 Enter 和 Backspace 备用
		if (controls.ACCEPT)
			selectSong();
		if (controls.BACK)
			goBack();
	}
	
	function changeSelection(change:Int)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		
		for (i => item in grpSongs.members)
		{
			item.alpha = (i == curSelected) ? 1.0 : 0.6;
		}
		
		// 重置难度为 Normal（可选）
		curDifficulty = 1;
		updateDifficultyDisplay();
		
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	
	function changeDifficulty(change:Int)
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, 2);
		updateDifficultyDisplay();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	
	function updateDifficultyDisplay()
	{
		for (i => txt in diffTexts.members)
		{
			txt.color = (i == curDifficulty) ? 0xFF00C8B0 : FlxColor.WHITE;
		}
	}
	
	function selectSong()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		var song = songs[curSelected];
		var diffName = ['easy', 'normal', 'hard'][curDifficulty];
		
		PlayState.SONG = Song.loadFromJson(song.songName.toLowerCase() + '-' + diffName, song.songName.toLowerCase());
		PlayState.storyDifficulty = curDifficulty;
		PlayState.storyWeek = song.week;
		PlayState.isStoryMode = false;
		
		LoadingState.loadAndSwitchState(new PlayState());
	}
	
	function goBack()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		MusicBeatState.switchState(new MainMenuState());
	}
}

class SongMetadata
{
	public var songName:String;
	public var icon:String;
	public var week:Int;
	
	public function new(songName:String, icon:String, week:Int)
	{
		this.songName = songName;
		this.icon = icon;
		this.week = week;
	}
}