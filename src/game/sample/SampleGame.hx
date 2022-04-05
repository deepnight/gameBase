package sample;

/**
	This small class just creates a SamplePlayer instance in current level
**/
class SampleGame extends Game {
	public function new() {
		super();
	}

	override function startLevel(l:World_Level) {
		super.startLevel(l);
		new SamplePlayer();
	}
}

