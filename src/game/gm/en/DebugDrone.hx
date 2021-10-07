package gm.en;

/**
	This Entity is intended for quick debugging / level exploration.
	Create one by pressing CTRL-SHIFT-D in game, fly around using ARROWS.
**/
@:access(gm.Camera)
class DebugDrone extends Entity {
	public static var ME : DebugDrone;
	static var DEFAULT_COLOR = 0x00ff00;

	var ca : ControllerAccess<GameAction>;
	var prevCamTarget : Null<Entity>;
	var prevCamZoom : Float;

	var g : h2d.Graphics;
	var help : h2d.Text;

	var droneDx = 0.;
	var droneDy = 0.;
	var droneFrict = 0.86;

	public function new() {
		if( ME!=null ) {
			ME.destroy();
			Game.ME.garbageCollectEntities();
		}

		super(0,0);

		ME = this;
		setPosPixel(camera.rawFocus.levelX, camera.rawFocus.levelY);

		// Controller
		ca = App.ME.controller.createAccess();
		ca.takeExclusivity();

		// Take control of camera
		if( camera.target!=null && camera.target.isAlive() )
			prevCamTarget = camera.target;
		prevCamZoom = camera.zoom;
		camera.trackEntity(this,false);

		// Placeholder render
		g = new h2d.Graphics(spr);
		g.beginFill(0xffffff);
		g.drawCircle(0,0,6, 16);
		setPivots(0.5);
		setColor(DEFAULT_COLOR);

		help = new h2d.Text(Assets.fontPixel);
		game.root.add(help, Const.DP_TOP);
		help.filter = new dn.heaps.filter.PixelOutline();
		help.textColor = DEFAULT_COLOR;
		help.text = [
			"ESCAPE - kill debug drone",
			"ARROWS - move",
			"PAGE UP/DOWN- zoom",
		].join("\n");
		help.setScale(Const.UI_SCALE);
		help.x = 4*Const.UI_SCALE;

		// <----- HERE: add your own specific inits, like setting drone gravity to zero, updating collision behaviors etc.
	}

	inline function setColor(c:Int) {
		g.color.setColor( Color.addAlphaF(c) );
	}

	override function dispose() {
		// Try to restore camera state
		if( prevCamTarget!=null )
			camera.trackEntity(prevCamTarget, false);
		else
			camera.target = null;
		prevCamTarget = null;
		camera.forceZoom( prevCamZoom );

		super.dispose();

		// Clean up
		help.remove();
		ca.dispose();
		if( ME==this )
			ME = null;
	}


	override function update() {
		super.update();

		// Ignore game standard velocities
		cancelVelocities();

		// Movement controls
		var spd = 0.02 * ( ca.isPadDown(X) ? 3 : 1 ); // turbo by holding pad-X

		if( !App.ME.anyInputHasFocus() ) {
			// Fly around
			if( ca.getAnalogDist(MoveX,MoveY) > 0 ) {
				var a = ca.getAnalogAngle(MoveX,MoveY);
				var d = ca.getAnalogDist(MoveX,MoveY);
				droneDx+=Math.cos(a) * d*spd * tmod;
				droneDy+=Math.sin(a) * d*spd * tmod;
			}

			// Zoom controls
			if( ca.isKeyboardDown(K.PGUP) || ca.isPadDown(LT) )
				camera.forceZoom( camera.baseZoom-0.04*camera.baseZoom );

			if( ca.isKeyboardDown(K.PGDOWN) || ca.isPadDown(RT) )
				camera.forceZoom( camera.baseZoom+0.02*camera.baseZoom );

			// Destroy
			if( ca.isKeyboardPressed(K.ESCAPE) ) {
				destroy();
				return;
			}
		}


		// X physics
		xr += droneDx*tmod;
		while( xr>1 ) { xr--; cx++; }
		while( xr<0 ) { xr++; cx--; }
		droneDx*=Math.pow(droneFrict, tmod);

		// Y physics
		yr += droneDy*tmod;
		while( yr>1 ) { yr--; cy++; }
		while( yr<0 ) { yr++; cy--; }
		droneDy*=Math.pow(droneFrict, tmod);

		// Update previous cam target if it changes
		if( camera.target!=null && camera.target!=this && camera.target.isAlive() )
			prevCamTarget = camera.target;

		// Display FPS
		debug( M.round(hxd.Timer.fps()) + " FPS" );

		// Collisions
		if( level.hasCollision(cx,cy) )
			setColor(0xff0000);
		else
			setColor(DEFAULT_COLOR);
	}
}