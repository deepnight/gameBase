package solv;

//* @author Eugene Zatepyakin
//* @link http://blog.inspirit.ru/?p=248
//* @link http://code.google.com/p/in-spirit/source/browse/#svn/trunk/projects/FluidSolver

/*
   haXe port
   Andy Li

   public static var FLUID_DEFAULT_NX:Float						= 50;
   public static var FLUID_DEFAULT_NY:Float						= 50;
   public static var FLUID_DEFAULT_DT:Float						= 1.0;
   public static var FLUID_DEFAULT_VISC:Float					= 0.0001;
   public static var FLUID_DEFAULT_COLOR_DIFFUSION:Float 		= 0.0;
   public static var FLUID_DEFAULT_FADESPEED:Float				= 0.3;
   public static var FLUID_DEFAULT_SOLVER_ITERATIONS:Int		= 10;
   public static var FLUID_DEFAULT_VORTICITY_CONFINEMENT:Bool 	= false;
*/

class FluidSolver 
{
   public static var FLUID_DEFAULT_NX:Float						= 50;
   public static var FLUID_DEFAULT_NY:Float						= 50;
   public static var FLUID_DEFAULT_DT:Float						= 0.5/Const.FIXED_UPDATE_FPS;//1.0;
   public static var FLUID_DEFAULT_VISC:Float					= 0.0000003;
   public static var FLUID_DEFAULT_COLOR_DIFFUSION:Float 		= 0.0;
   public static var FLUID_DEFAULT_FADESPEED:Float				= 0.05;
   public static var FLUID_DEFAULT_SOLVER_ITERATIONS:Int		= 1;
   public static var FLUID_DEFAULT_VORTICITY_CONFINEMENT:Bool 	= true;
   public static var FLUID_DEFAULT_BOUNDARY_OFFSET              = 2;


   public var u:Array<Float>;
   public var v:Array<Float>;
   
   public var uOld:Array<Float>;
   public var vOld:Array<Float>;
   
   public var curl_abs:Array<Float>;
   public var curl_orig:Array<Float>;
   
   public var width(default, null):Int;
   public var height(default, null):Int;
   
   public var numCells(default, null):Int;
   
   public var deltaT:Float;			// for monochrome, only update r
   public var solverIterations:Int;		// number of iterations for solver (higher is slower but more accurate) 
   public var vorticityConfinement:Bool;
   
   public var wrapX(default, null):Bool;
   public var wrapY(default, null):Bool;
   
   public var viscosity:Float;
   public var fadeSpeed:Float; //0...1
   
   public var avgDensity(default, null):Float;			// this will hold the average color of the last frame (how full it is)
   public var uniformity(default, null):Float;			// this will hold the uniformity of the last frame (how uniform the color is);
   public var avgSpeed(default, null):Float;
   
   private var _NX:Int;
   private var _NY:Int;
   private var _NX2:Int;
   private var _NY2:Int;
   private var _invNumCells:Float;
   
   private var _tmp:Array<Float>;
   
   public function new(NX:Int, NY:Int)
   {
       wrapX = wrapY = false;
       setup(NX, NY);
   }
   
   public function setup(NX:Int, NY:Int):Void
   {
       deltaT =  FLUID_DEFAULT_DT;
       fadeSpeed = FLUID_DEFAULT_FADESPEED;
       solverIterations = FLUID_DEFAULT_SOLVER_ITERATIONS;
       vorticityConfinement = FLUID_DEFAULT_VORTICITY_CONFINEMENT;
       
       _NX = NX;
       _NY = NY;
       _NX2 = _NX ;//+ FLUID_DEFAULT_BOUNDARY_OFFSET;
       _NY2 = _NY ;//+ FLUID_DEFAULT_BOUNDARY_OFFSET;
       
       numCells = _NX2 * _NY2;
       
       _invNumCells = 1.0 / numCells;
       
       width = _NX2;

       height = _NY2;
       
       reset();
   }
   
   public function reset():Void 
   {	
       
       u    = new Array<Float>();
       uOld = new Array<Float>();
       v    = new Array<Float>();
       vOld = new Array<Float>();
       
       curl_abs = new Array<Float>();
       curl_orig = new Array<Float>();
       
       var i:Int = numCells;
       while ( --i > -1 ) {
           u[i] = uOld[i] = v[i] = vOld[i] = 0.0;
           curl_abs[i] = curl_orig[i] = 0;
       }
   }	
   
   
   /**
    * this must be called once every frame to move the solver one step forward 
    */
   public function update():Void {
       addSourceUV();
       
       if( vorticityConfinement ){
           calcVorticityConfinement(uOld, vOld);
           addSourceUV();
       }
       
       swapUV();
       
       diffuseUV(viscosity);
       
       project(u, v, uOld, vOld);
       
       swapUV();
       
       advect(1, u, uOld, uOld, vOld); 
       advect(2, v, vOld, uOld, vOld);
       
       project(u, v, uOld, vOld);
       
   }
   
   private function calcVorticityConfinement(_x:Array<Float>, _y:Array<Float>):Void
   {
       var dw_dx:Float, dw_dy:Float;
       var i:Int, j:Int;
       var length:Float;
       var index:Int;
       var vv:Float;
       
       // Calculate magnitude of (u,v) for each cell. (|w|)
       j = _NY;
       while (j > 0)
       {
           index = FLUID_IX(_NX, j);
           i = _NX;
           while (i > 0)
           {
               dw_dy = u[index + _NX2] - u[index - _NX2];
               dw_dx = v[index + 1] - v[index - 1];
               
               vv = (dw_dy - dw_dx) * .5;
               
               curl_orig[ index ] = vv;
               curl_abs[ index ] = vv < 0 ? -vv : vv;
               
               --index;
               --i;
           }
           --j;
       }
       
       j = _NY-1;
       while (j > 1)
       {
           index = FLUID_IX(_NX-1, j);
           i = _NX-1;
           while (i > 1)
           {
               dw_dx = curl_abs[index + 1] - curl_abs[index - 1];
               dw_dy = curl_abs[index + _NX2] - curl_abs[index - _NX2];
               
               length = Math.sqrt(dw_dx * dw_dx + dw_dy * dw_dy) + 0.000001;
               
               length = 2 / length;
               dw_dx *= length;
               dw_dy *= length;
               
               vv = curl_orig[ index ];
               
               _x[ index ] = dw_dy * -vv;
               _y[ index ] = dw_dx * vv;
               
               --index;
               --i;
           }
           --j;
       }
   }
   
  
   private function addSourceUV():Void 
   {
       var i:Int = numCells;
       while ( --i > -1 ) {
           u[i] += deltaT * uOld[i];
           v[i] += deltaT * vOld[i];
       }
   }
   
   private function addSource(x:Array<Float>, x0:Array<Float>):Void 
   {
       var i:Int = numCells;
       while ( --i > -1 ) {
           x[i] += deltaT * x0[i];
       }
   }
   
   private function advect(b:Int, _d:Array<Float>, d0:Array<Float>, du:Array<Float>, dv:Array<Float>):Void 
   {
       var i:Int, j:Int, i0:Int, j0:Int, i1:Int, j1:Int, index:Int;
       var x:Float, y:Float, s0:Float, t0:Float, s1:Float, t1:Float, dt0x:Float, dt0y:Float;
       
       dt0x = deltaT * _NX;
       dt0y = deltaT * _NY;

       j = _NY;
       while (j > 0) {
           i = _NX;
           while (i > 0) {
               
               index = FLUID_IX(i, j);
               
               x = i - dt0x * du[index];
               y = j - dt0y * dv[index];
               
               if (x > _NX + 0.5) x = _NX + 0.5;
               if (x < 0.5) x = 0.5;
               
               i0 = Std.int(x);
               i1 = i0 + 1;
               
               if (y > _NY + 0.5) y = _NY + 0.5;
               if (y < 0.5) y = 0.5;
               
               j0 = Std.int(y);
               j1 = j0 + 1;
               
               s1 = x - i0;
               s0 = 1 - s1;
               t1 = y - j0;
               t0 = 1 - t1;
               
               _d[index] = s0 * (t0 * d0[FLUID_IX(i0, j0)] + t1 * d0[FLUID_IX(i0, j1)]) + s1 * (t0 * d0[FLUID_IX(i1, j0)] + t1 * d0[FLUID_IX(i1, j1)]);

               --i;
           }
           --j;
       }
       setBoundary(b, _d);
   }
   
  
   private function diffuse(b:Int, c:Array<Float>, c0:Array<Float>, _diff:Float):Void 
   {
       var a:Float = deltaT * _diff * _NX * _NY;
       linearSolver(b, c, c0, a, 1.0 + 4 * a);
   }
   
   private function diffuseUV(_diff:Float):Void 
   {
       var a:Float = deltaT * _diff * _NX * _NY;
       linearSolverUV(a, 1.0 + 4 * a);
   }
   
   private function project(x:Array<Float>, y:Array<Float>, p:Array<Float>, div:Array<Float>):Void 
   {
       var i:Int, j:Int;
       var index:Int;
       
       var h:Float = -0.5 / _NX;

       j = _NY;
       while (j > 0) 
       {
           index = FLUID_IX(_NX, j);
           
           i = _NX;
           while (i > 0)
           {
               div[index] = h * ( x[index+1] - x[index-1] + y[index+_NX2] - y[index-_NX2] );
               p[index] = 0;
               --index;
               --i;
           }
           --j;
       }
       
       setBoundary(0, div);
       setBoundary(0, p);
       
       linearSolver(0, p, div, 1, 4);
       
       var fx:Float = 0.5 * _NX;
       var fy:Float = 0.5 * _NY;
       j = _NY;
       while (j > 0) 
       {
           index = FLUID_IX(_NX, j);
           i = _NX;
           while (i > 0)
           {
               x[index] -= fx * (p[index+1] - p[index-1]);
               y[index] -= fy * (p[index+_NX2] - p[index-_NX2]);
               --index;
               --i;
           }
           --j;
       }
       
       setBoundary(1, x);
       setBoundary(2, y);
   }
   
   private function linearSolver(b:Int, x:Array<Float>, x0:Array<Float>, a:Float, c:Float):Void 
   {
       var k:Int, i:Int, j:Int;
       
       var index:Int;
       
       if( a == 1 && c == 4 )
       {
           k = 0;
           while (k < solverIterations) 
           {
               j = _NY;
               while (j > 0) 
               {
                   index = FLUID_IX(_NX, j);
                   i = _NX;
                   while (i > 0)
                   {
                       x[index] = ( x[index-1] + x[index+1] + x[index - _NX2] + x[index + _NX2] + x0[index] ) * .25;
                       --index;
                       --i;                               
                   }
                   --j;
               }
               setBoundary( b, x );
               ++k;
           }
       }
       else
       {
           c = 1 / c;
           k = 0;
           while (k < solverIterations) 
           {
               j = _NY;
               while (j > 0) 
               {
                   index = FLUID_IX(_NX, j);
                   i = _NX;
                   while (i > 0)
                   {
                       x[index] = ( ( x[index-1] + x[index+1] + x[index - _NX2] + x[index + _NX2] ) * a + x0[index] ) * c;
                       --index;
                       --i;
                   }
                   --j;
               }
               setBoundary( b, x );
               ++k;
           }
       }
   }
   
   
   private function linearSolverUV(a:Float, c:Float):Void 
   {    
       //a = viscosity ; c = nb magique
       var index:Int;
       var k:Int, i:Int, j:Int;
       c = 1 / c;
       k = 0;
       while (k < solverIterations) {
           j = _NY;
           while (j > 0) {
               index = FLUID_IX(_NX, j);
               i = _NX;
               while (i > 0) {
                   u[index] = ( ( u[index-1] + u[index+1] + u[index - _NX2] + u[index + _NX2] ) * a  +  uOld[index] ) * c;
                   v[index] = ( ( v[index-1] + v[index+1] + v[index - _NX2] + v[index + _NX2] ) * a  +  vOld[index] ) * c;
                   --index;
                   --i;
               }
               --j;
           }
           setBoundary( 1, u );
           setBoundary( 2, v );
           ++k;
       }
   }
   

   private function setBoundary(bound:Int, x:Array<Float>):Void 
   {
       var dst1:Int, dst2:Int, src1:Int, src2:Int;
       var i:Int;
       var step:Int = FLUID_IX(0, 1) - FLUID_IX(0, 0);

       dst1 = FLUID_IX(0, 1);
       src1 = FLUID_IX(1, 1);
       dst2 = FLUID_IX(_NX+1, 1 );
       src2 = FLUID_IX(_NX, 1);
       
       if( wrapX ) {
           src1 ^= src2;
           src2 ^= src1;
           src1 ^= src2;
       }
       if( bound == 1 && !wrapX ) {
           i = _NY;
           while (i > 0)
           {
               x[dst1] = -x[src1];     dst1 += step;   src1 += step;   
               x[dst2] = -x[src2];     dst2 += step;   src2 += step;  
               --i; 
           }
       } else {
           i = _NY;
           while (i > 0)
           {
               x[dst1] = x[src1];      dst1 += step;   src1 += step;   
               x[dst2] = x[src2];      dst2 += step;   src2 += step;
               --i;   
           }
       }
       
       dst1 = FLUID_IX(1, 0);
       src1 = FLUID_IX(1, 1);
       dst2 = FLUID_IX(1, _NY+1);
       src2 = FLUID_IX(1, _NY);
       
       if( wrapY ) {
           src1 ^= src2;
           src2 ^= src1;
           src1 ^= src2;
       }
       if( bound == 2 && !wrapY ) {
           i = _NX;
           while (i > 0)
           {
                   x[dst1++] = -x[src1++]; 
                   x[dst2++] = -x[src2++]; 
                   --i;
           }
       } else {
           i = _NX;
           while (i > 0)
           {
                   x[dst1++] = x[src1++];
                   x[dst2++] = x[src2++];
                   --i;  
           }
       }
       
       x[FLUID_IX(  0,   0)] = 0.5 * (x[FLUID_IX(1, 0  )] + x[FLUID_IX(  0, 1)]);
       x[FLUID_IX(  0, _NY+1)] = 0.5 * (x[FLUID_IX(1, _NY+1)] + x[FLUID_IX(  0, _NY)]);
       x[FLUID_IX(_NX+1,   0)] = 0.5 * (x[FLUID_IX(_NX, 0  )] + x[FLUID_IX(_NX+1, 1)]);
       x[FLUID_IX(_NX+1, _NY+1)] = 0.5 * (x[FLUID_IX(_NX, _NY+1)] + x[FLUID_IX(_NX+1, _NY)]);
        
   }
   
  
   private function swapUV():Void
   {
       _tmp = u; 
       u = uOld; 
       uOld = _tmp;
       
       _tmp = v; 
       v = vOld; 
       vOld = _tmp; 
   }
   
  
   inline private function FLUID_IX(i:Int, j:Int):Int
   { 
       return i + _NX2 * j;
   }
   
    // nx => nx2 le debug draw repose sur cette fonction      
   inline public function getIndexForCellPosition(i:Int, j:Int):Int 
   {
       if(i <= 0) i=0; else if(i > _NX2) i = _NX2;
       if(j <= 0) j=0; else if(j > _NY2) j = _NY2;
       return FLUID_IX(i, j);
   }
   
   inline public function getIndexForNormalizedPosition(x:Float, y:Float):Int 
   {
       return getIndexForCellPosition(Std.int(x * _NX2), Std.int(y * _NY2));
   }
   
   public function setWrap(x:Bool = false, y:Bool = false):Void
   {
       wrapX = x;
       wrapY = y;
   }
}