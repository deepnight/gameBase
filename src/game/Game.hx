class Game extends AppChildProcess {
	public static var ME : Game;

	/** Game controller (pad or keyboard) **/
	public var ca : ControllerAccess<GameAction>;

	/** Particles **/
	public var fx : Fx;

	/** Basic viewport control **/
	public var camera : Camera;

	/** Container of all visual game objects. Ths wrapper is moved around by Camera. **/
	public var scroller : h2d.Layers;
	public var bg : h2d.Bitmap;

	/** Level data **/
	public var level : Level;

	/** UI **/
	public var hud : ui.Hud;

	var interactive : h2d.Interactive;
	public var mouse : LPoint;
	public var hero : Hero;

	/** Slow mo internal values**/
	var curGameSpeed = 1.0;
	var slowMos : Map<String, { id:String, t:Float, f:Float }> = new Map();
	var gameTimeS = 0.;


	public function new() {
		super();

		ME = this;
		ca = App.ME.controller.createAccess();
		ca.lockCondition = isGameControllerLocked;
		createRootInLayers(App.ME.root, Const.DP_BG);
		dn.Gc.runNow();

		bg = new h2d.Bitmap( h2d.Tile.fromColor(Assets.walls()) );
		root.add(bg,Const.DP_BG);

		scroller = new h2d.Layers();
		root.add(scroller, Const.DP_BG);
		scroller.filter = new h2d.filter.Nothing(); // force rendering for pixel perfect

		fx = new Fx();
		hud = new ui.Hud();
		camera = new Camera();

		interactive = new h2d.Interactive(1,1,root);
		interactive.enableRightButton = true;
		interactive.onMove = onMouseMove;
		interactive.onPush = onMouseDown;
		interactive.onRelease = onMouseUp;
		mouse = new LPoint();

		var start = Assets.worldData.all_levels.Entrance;
		#if debug
		for(l in Assets.worldData.levels)
			if( l.l_Entities.all_DebugStart.length>0 ) {
				var e = l.l_Entities.all_DebugStart[0];
				start = l;
				lastStartX = e.pixelX;
				lastStartY = e.pixelY;
				break;
			}
		#end
		startLevel(start);
	}


	public static function isGameControllerLocked() {
		return !exists() || ME.isPaused() || App.ME.anyInputHasFocus();
	}


	public static inline function exists() {
		return ME!=null && !ME.destroyed;
	}


	public function restartLevel() {
		startLevel(level.data);
	}

	public function exitToLevel(dx:Int, dy:Int) {
		var gx = level.data.worldX + hero.attachX + dx*2*G;
		var gy = level.data.worldY + hero.attachY + dy*2*G;
		for(l in Assets.worldData.levels) {
			if( gx>=l.worldX && gx<l.worldX+l.pxWid && gy>=l.worldY && gy<l.worldY+l.pxHei ) {
				var x = gx-l.worldX;
				var y = gy-l.worldY;
				startLevel(l, x, y);
				return true;
			}
		}
		return false;
	}

	/** Load a level **/
	var lastStartX = -1.;
	var lastStartY = -1.;
	function startLevel(l:World.World_Level, startX=-1., startY=-1.) {
		if( level!=null )
			level.destroy();
		fx.clear();
		for(e in Entity.ALL) // <---- Replace this with more adapted entity destruction (eg. keep the player alive)
			e.destroy();
		garbageCollectEntities();
		gameTimeS = 0;
		cd.unset("gameTimeLock");

		level = new Level(l);
		// camera.rawFocus.setLevelPixel(level.pxWid*0.5, level.pxHei*0.5);

		if( startX<0 && lastStartX<0 ) {
			var d = level.data.l_Entities.all_PlayerStart[0];
			hero = new Hero(d.pixelX, d.pixelY-G*0.5);
		}
		else {
			if( startX<0 ) {
				if( lastStartX<0 ) {
					lastStartX = level.pxWid*0.5;
					lastStartY = level.pxHei*0.5;
				}
				startX = lastStartX;
				startY = lastStartY;
			}
			hero = new Hero(startX, startY);
		}
		lastStartX = hero.attachX;
		lastStartY = hero.attachY;
		camera.trackEntity(hero, true);

		for(d in level.data.l_Entities.all_Destructible) new en.Destructible(d);
		for(d in level.data.l_Entities.all_Door) new en.Door(d);
		for(d in level.data.l_Entities.all_Message) new en.Message(d);
		for(d in level.data.l_Entities.all_Item) new en.Item(d.pixelX, d.pixelY, d.f_type);

		for(d in level.data.l_Entities.all_Mob)
			switch d.f_type {
				case MT_Melee: new en.mob.Melee(d);
				case MT_Gun: new en.mob.Gun(d);
				case MT_Trash: new en.mob.Trash(d);
			}

		camera.centerOnTarget();
		hud.onLevelStart();
		dn.Process.resizeAll();
		dn.Gc.runNow();
	}


	public function nextLevel() {
		var next = false;
		for(l in Assets.worldData.levels) {
			if( l==level.data )
				next = true;
			else if( next ) {
				startLevel(l);
				return true;
			}
		}
		return false;
	}


	/** Called when either CastleDB or `const.json` changes on disk **/
	@:allow(App)
	function onDbReload() {
		hud.notify("DB reloaded");
	}


	/** Called when LDtk file changes on disk **/
	@:allow(assets.Assets)
	function onLdtkReload() {
		hud.notify("LDtk reloaded");
		if( level!=null )
			startLevel( Assets.worldData.getLevel(level.data.uid) );
	}

	/** Window/app resize event **/
	override function onResize() {
		super.onResize();
		interactive.width = w();
		interactive.height = h();
		bg.scaleX = w();
		bg.scaleY = h();
	}


	inline function updateMouse(ev:hxd.Event) {
		mouse.setScreen(ev.relX, ev.relY);
	}

	function onMouseMove(ev:hxd.Event) {
		updateMouse(ev);
	}

	function onMouseDown(ev:hxd.Event) {
		updateMouse(ev);
	}
	function onMouseUp(ev:hxd.Event) {
		updateMouse(ev);
		// switch ev.button {
		// 	case 0: hero.goto(mouse.levelXi, mouse.levelYi);
		// 	case 1:
		// }
	}


	/** Garbage collect any Entity marked for destruction. This is normally done at the end of the frame, but you can call it manually if you want to make sure marked entities are disposed right away, and removed from lists. **/
	public function garbageCollectEntities() {
		if( Entity.GC==null || Entity.GC.allocated==0 )
			return;

		for(e in Entity.GC)
			e.dispose();
		Entity.GC.empty();
	}

	/** Called if game is destroyed, but only at the end of the frame **/
	override function onDispose() {
		super.onDispose();

		fx.destroy();
		for(e in Entity.ALL)
			e.destroy();
		garbageCollectEntities();

		if( ME==this )
			ME = null;
	}


	/**
		Start a cumulative slow-motion effect that will affect `tmod` value in this Process
		and all its children.

		@param sec Realtime second duration of this slowmo
		@param speedFactor Cumulative multiplier to the Process `tmod`
	**/
	public function addSlowMo(id:String, sec:Float, speedFactor=0.3) {
		if( slowMos.exists(id) ) {
			var s = slowMos.get(id);
			s.f = speedFactor;
			s.t = M.fmax(s.t, sec);
		}
		else
			slowMos.set(id, { id:id, t:sec, f:speedFactor });
	}


	/** The loop that updates slow-mos **/
	final function updateSlowMos() {
		// Timeout active slow-mos
		for(s in slowMos) {
			s.t -= utmod * 1/Const.FPS;
			if( s.t<=0 )
				slowMos.remove(s.id);
		}

		// Update game speed
		var targetGameSpeed = 1.0;
		for(s in slowMos)
			targetGameSpeed*=s.f;
		curGameSpeed += (targetGameSpeed-curGameSpeed) * (targetGameSpeed>curGameSpeed ? 0.2 : 0.6);

		if( M.fabs(curGameSpeed-targetGameSpeed)<=0.001 )
			curGameSpeed = targetGameSpeed;
	}


	/**
		Pause briefly the game for 1 frame: very useful for impactful moments,
		like when hitting an opponent in Street Fighter ;)
	**/
	public inline function stopFrame() {
		ucd.setS("stopFrame", 0.2);
	}


	/** Loop that happens at the beginning of the frame **/
	override function preUpdate() {
		super.preUpdate();

		for(e in Entity.ALL) if( !e.destroyed ) e.preUpdate();
	}

	function onCycle() {
		fx.flashBangEaseInS(Blue, 0.2, 0.3);
		hero.hasSuperCharge = true;
		cd.setS("gameTimeLock",1);
		gameTimeS = 0;

		hero.clearAffect(Dodge);
		hero.cancelVelocities();
		hero.dodgeDx = hero.dodgeDy = 0;
		hero.cancelAction();
		hero.dz = M.fmax(0,hero.dz);
		hero.zr*=0.5;
		hero.spr.anim.stopWithStateAnims();

		level.darken();
		for(e in Entity.ALL) e.darken();
		for(e in en.Bullet.ALL) e.destroy();
		hero.undarken();

		for(e in en.Mob.ALL) {
			e.cancelAction();
			e.cancelMove();
			e.lockAiS(1);
			if( e.rageCharges>0 )
				e.undarken();
		}

		hero.clearRage();
		// for(e in en.Item.ALL)
		// 	e.destroy();

		addSlowMo("execute", 1, 0.4);
		hero.chargeAction("execute", 1, ()->{
			addSlowMo("execute", 0.5, 0.2);
			camera.shakeS(1, 0.3);
			camera.bumpZoom(0.2);
			hero.spr.anim.play(D.ent.kSuper_hit);
			for(e in en.Mob.ALL) {
				if( !e.isAlive() )
					continue;

				if( e.rageCharges==0 ) {
					e.bumpAwayFrom(hero, 0.1);
					e.setAffectS(Stun, 0.5);
					continue;
				}

				e.setAffectS(Stun, 2);
				if( e.rageCharges>=e.maxLife ) {
					// Kill
					e.bumpAwayFrom(hero, 0.3);
					e.dz = 0.2;
					e.hit(e.rageCharges, hero);
					fx.dotsExplosionExample(e.centerX, e.centerY, Red);
				}
				else {
					e.popText("Not enough");
					e.bumpAwayFrom(hero, 0.1);
				}
				e.clearRage();
			}

			for(e in Entity.ALL)
				e.undarken();

			level.undarken();

			// Open exits
			if( en.Mob.alives()==0 )
				for(e in en.Door.ALL)
					if( e.data.f_openOnComplete ) {
						e.blink(White);
						e.open();
					}

		});

	}

	/** Loop that happens at the end of the frame **/
	override function postUpdate() {
		super.postUpdate();

		// Update slow-motions
		updateSlowMos();
		baseTimeMul = ( 0.2 + 0.8*curGameSpeed ) * ( ucd.has("stopFrame") ? 0.3 : 1 );
		Assets.tiles.tmod = tmod;

		if( hero.isAlive() && en.Mob.alives()>0 ) {
			if( !cd.has("gameTimeLock") )
				gameTimeS += tmod * 1/Const.FPS;
			if( gameTimeS>=Const.CYCLE_S )
				onCycle();
			hud.setTimeS(gameTimeS);
		}
		else {
			hud.setTimeS(-1);
		}

		// Entities post-updates
		for(e in Entity.ALL) if( !e.destroyed ) e.postUpdate();

		// Entities final updates
		for(e in Entity.ALL) if( !e.destroyed ) e.finalUpdate();

		// Z sort
		if( !cd.hasSetS("zsort",0.1) ) {
			Entity.ALL.bubbleSort( e->e.attachY );
			for(e in Entity.ALL)
				e.over();
		}

		// Dispose entities marked as "destroyed"
		garbageCollectEntities();
	}


	/** Main loop but limited to 30 fps (so it might not be called during some frames) **/
	override function fixedUpdate() {
		super.fixedUpdate();

		// Entities "30 fps" loop
		for(e in Entity.ALL) if( !e.destroyed ) e.fixedUpdate();
	}


	/** Main loop **/
	override function update() {
		super.update();

		// Entities main loop
		for(e in Entity.ALL) if( !e.destroyed ) e.frameUpdate();


		// Global key shortcuts
		if( !App.ME.anyInputHasFocus() && !ui.Modal.hasAny() && !Console.ME.isActive() ) {

			// Exit by pressing ESC twice
			#if hl
			if( ca.isKeyboardPressed(K.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					hud.notify(Lang.t._("Press ESCAPE again to exit."));
				else
					App.ME.exit();
			#end

			// Attach debug drone (CTRL-SHIFT-D)
			#if debug
			if( ca.isPressed(ToggleDebugDrone) )
				new DebugDrone(); // <-- HERE: provide an Entity as argument to attach Drone near it
			if( ca.isKeyboardPressed(K.N) )
				nextLevel();
			#end

			// Restart whole game
			if( ca.isPressed(Restart) ) {
				if( ca.isKeyboardDown(K.SHIFT) )
					App.ME.startGame();
				else
					restartLevel();
			}

		}
	}
}

