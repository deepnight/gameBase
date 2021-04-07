package gm.en;

/**
	This Entity is intended for quick debugging / level exploration.
	Create one by pressing CTRL-SHIFT-D in game, fly around using ARROWS.
**/
@:access(gm.Camera)
class DebugDrone extends Entity {
	public static var ME : DebugDrone;
	static var DEFAULT_COLOR = 0x00ff00;

	var ca : dn.heaps.Controller.ControllerAccess;
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
		ca = App.ME.controller.createAccess("drone", true);
		ca.setLeftDeadZone(0.3);

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

		help = new h2d.Text(Assets.fontSmall);
		game.root.add(help, Const.DP_TOP);
		help.textColor = DEFAULT_COLOR;
		help.text = [
			"ESCAPE - kill debug drone",
			"ARROWS - move",
			"PAGE UP/DOWN- zoom",
		].join("\n");
		help.setScale(Const.UI_SCALE);

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
		camera.zoom = prevCamZoom;

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
		var spd = 0.02;

		if( !App.ME.anyInputHasFocus() ) {
			if( ca.leftDist()>0 ) {
				var a = ca.leftAngle();
				var d = ca.leftDist();
				droneDx+=Math.cos(a) * d*spd * tmod;
				droneDy+=Math.sin(a) * d*spd * tmod;
			}
			if( ca.isKeyboardDown(K.LEFT) )
				droneDx-=spd*tmod;

			if( ca.isKeyboardDown(K.RIGHT) )
				droneDx+=spd*tmod;

			if( ca.isKeyboardDown(K.UP) )
				droneDy-=spd*tmod;

			if( ca.isKeyboardDown(K.DOWN) )
				droneDy+=spd*tmod;

			// Zoom controls
			if( ca.isKeyboardDown(K.PGUP) )
				camera.zoom -= camera.zoom * 0.02*tmod;

			if( ca.isKeyboardDown(K.PGDOWN) )
				camera.zoom += camera.zoom * 0.02*tmod;

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