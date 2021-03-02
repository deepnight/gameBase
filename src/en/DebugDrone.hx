package en;

/**
	This Entity is intended for quick debugging / level exploration.
	Create one by pressing CTRL-SHIFT-D in game, fly around using ARROWS.
**/
class DebugDrone extends Entity {
	public static var ME : DebugDrone;
	static final COLOR = 0xffcc00;

	var ca : dn.heaps.Controller.ControllerAccess;
	var previousCameraTarget : Null<Entity>;

	var g : h2d.Graphics;
	var help : h2d.Text;

	public function new(?nearEntity:Entity) {
		if( ME!=null ) {
			ME.destroy();
			Game.ME.garbageCollectEntities();
		}

		super(0,0);

		ME = this;
		frictX = frictY = 0.86;

		if( nearEntity!=null )
			setPosPixel(nearEntity.attachX, nearEntity.attachY);
		else
			setPosPixel(level.pxWid*0.5, level.pxHei*0.5);

		// Controller
		ca = Main.ME.controller.createAccess("drone", true);

		// Take control of camera
		if( @:privateAccess camera.target!=null )
			previousCameraTarget = @:privateAccess camera.target;
		camera.trackEntity(this,false);

		// Placeholder render
		g = new h2d.Graphics(spr);
		g.beginFill(COLOR);
		g.drawCircle(0,0,6, 16);
		setPivots(0.5);

		help = new h2d.Text(Assets.fontSmall);
		game.root.add(help, Const.DP_TOP);
		help.text = [
			"ESCAPE - kill debug drone",
			"ARROWS - move",
			"PAGE UP/DOWN- zoom",
		].join("\n");
		help.setScale(Const.UI_SCALE);

		// <----- HERE: add your own specific inits, like setting drone gravity to zero, updating collision behaviors etc.
	}


	override function dispose() {
		// Try to restore camera state
		if( previousCameraTarget!=null )
			camera.trackEntity(previousCameraTarget, false);
		previousCameraTarget = null;

		super.dispose();

		// Clean up
		help.remove();
		ca.dispose();
		if( ME==this )
			ME = null;
	}


	override function update() {
		super.update();

		// Movement controls
		var spd = 0.02;

		if( ca.isKeyboardDown(K.LEFT) )
			dx-=spd*tmod;

		if( ca.isKeyboardDown(K.RIGHT) )
			dx+=spd*tmod;

		if( ca.isKeyboardDown(K.UP) )
			dy-=spd*tmod;

		if( ca.isKeyboardDown(K.DOWN) )
			dy+=spd*tmod;

		// Zoom controls
		if( ca.isKeyboardDown(K.PGUP) )
			camera.zoom -= camera.zoom * 0.02*tmod;

		if( ca.isKeyboardDown(K.PGDOWN) )
			camera.zoom += camera.zoom * 0.02*tmod;

		// Destroy
		if( ca.isKeyboardPressed(K.ESCAPE) )
			destroy();

		// Update previous cam target if it changes
		if( @:privateAccess camera.target!=null && @:privateAccess camera.target!=this )
			previousCameraTarget = @:privateAccess camera.target;

		// Display FPS
		debug( M.round(hxd.Timer.fps()) + " FPS" );
	}
}