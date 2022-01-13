package sample;

/**
	This small class just creates a SamplePlayer instance in current level
**/
class SampleGame extends Game {



	public function new() {
		super();
		//createRootInLayers(scroller, Const.DP_FRONT);

		//Solver init
	}
	
	override function startLevel(l:World_Level) {
		super.startLevel(l);
		new SamplePlayer();

		for (i in 0...25){
			for( j in 0...25){
			new Bullet(5+i*2,5+ j*2);
			}
		}

	}
}

