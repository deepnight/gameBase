package sample;

/**
	This small class just creates a SamplePlayer instance in current level
**/
class SampleGame extends Game {
	public function new() {
		super();

		new SamplePlayer();
	}
}
