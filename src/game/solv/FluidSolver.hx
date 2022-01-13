package solv;

//* @author Eugene Zatepyakin
//* @link http://blog.inspirit.ru/?p=248
//* @link http://code.google.com/p/in-spirit/source/browse/#svn/trunk/projects/FluidSolver

/*
   haXe port
   Andy Li
*/
class FluidSolver 
{
   public static var FLUID_DEFAULT_NX:Float						= 50;
   public static var FLUID_DEFAULT_NY:Float						= 50;
   public static var FLUID_DEFAULT_DT:Float						= 1.0;
   public static var FLUID_DEFAULT_VISC:Float					= 0.0001;
   public static var FLUID_DEFAULT_COLOR_DIFFUSION:Float 		= 0.0;
   public static var FLUID_DEFAULT_FADESPEED:Float				= 0.3;
   public static var FLUID_DEFAULT_SOLVER_ITERATIONS:Int		= 10;
   public static var FLUID_DEFAULT_VORTICITY_CONFINEMENT:Bool 	= false;

   public var r:Array<Float>;
   public var g:Array<Float>;
   public var b:Array<Float>;
   
   public var u:Array<Float>;
   public var v:Array<Float>;

   public var rOld:Array<Float>;
   public var gOld:Array<Float>;
   public var bOld:Array<Float>;
   
   public var uOld:Array<Float>;
   public var vOld:Array<Float>;
   
   public var curl_abs:Array<Float>;
   public var curl_orig:Array<Float>;
   
   public var width(default, null):Int;
   public var height(default, null):Int;
   
   public var numCells(default, null):Int;
   
   public var deltaT:Float;
   public var isRGB:Bool;				// for monochrome, only update r
   public var solverIterations:Int;		// number of iterations for solver (higher is slower but more accurate) 
   public var colorDiffusion:Float;
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
       colorDiffusion = FLUID_DEFAULT_COLOR_DIFFUSION;
       vorticityConfinement = FLUID_DEFAULT_VORTICITY_CONFINEMENT;
       
       _NX = NX;
       _NY = NY;
       _NX2 = _NX + 2;
       _NY2 = _NY + 2;
       
       numCells = _NX2 * _NY2;
       
       _invNumCells = 1.0 / numCells;
       
       width = _NX2;
       height = _NY2;
       
       isRGB = false;
       
       reset();
   }
   
   public function reset():Void 
   {	
       r    = new Array<Float>();
       rOld = new Array<Float>();
       
       g    = new Array<Float>();
       gOld = new Array<Float>();
       
       b    = new Array<Float>();
       bOld = new Array<Float>();
       
       u    = new Array<Float>();
       uOld = new Array<Float>();
       v    = new Array<Float>();
       vOld = new Array<Float>();
       
       curl_abs = new Array<Float>();
       curl_orig = new Array<Float>();
       
       var i:Int = numCells;
       while ( --i > -1 ) {
           u[i] = uOld[i] = v[i] = vOld[i] = 0.0;
           r[i] = rOld[i] = g[i] = gOld[i] = b[i] = bOld[i] = 0;
           curl_abs[i] = curl_orig[i] = 0;
       }
   }	
   
   
   /**
    * this must be called once every frame to move the solver one step forward 
    */
   public function update():Void 
   {
       addSourceUV();
       
       if( vorticityConfinement )
       {
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
       
       if(isRGB) {
           addSourceRGB();
           swapRGB();
           
           if( colorDiffusion != 0 && deltaT != 0 )
           {
               diffuseRGB(colorDiffusion);
               swapRGB();
           }
           
           advectRGB(u, v);
           
           fadeRGB();
       } else {
           addSource(r, rOld);
           swapR();
           
           if( colorDiffusion != 0 && deltaT != 0 )
           {
               diffuse(0, r, rOld, colorDiffusion);
               swapRGB();
           }
           
           advect(0, r, rOld, u, v);	
           fadeR();
       }
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
   
   private function fadeR():Void 
   {
       var holdAmount:Float = 1 - fadeSpeed;
       
       avgDensity = 0;
       avgSpeed = 0;
       
       var totalDeviations:Float = 0;
       var currentDeviation:Float;
       var tmp_r:Float;
       
       var i:Int = numCells;
       while ( --i > -1 ) {
           // clear old values
           uOld[i] = vOld[i] = 0; 
           rOld[i] = 0;
           
           // calc avg speed
           avgSpeed += u[i] * u[i] + v[i] * v[i];
           
           // calc avg density
           tmp_r = Math.min(1.0, r[i]);
           avgDensity += tmp_r;	// add it up
           
           // calc deviation (for uniformity)
           currentDeviation = tmp_r - avgDensity;
           totalDeviations += currentDeviation * currentDeviation;
           
           // fade out old
           r[i] = tmp_r * holdAmount;
       }
       avgDensity *= _invNumCells;
       
       uniformity = 1.0 / (1 + totalDeviations * _invNumCells);		// 0: very wide distribution, 1: very uniform
   }
   
   private function fadeRGB():Void 
   {
       var holdAmount:Float = 1 - fadeSpeed;
       
       avgDensity = 0;
       avgSpeed = 0;
       
       var totalDeviations:Float = 0;
       var currentDeviation:Float;
       var density:Float;
       
       var tmp_r:Float, tmp_g:Float, tmp_b:Float;
       
       var i:Int = numCells;
       while ( --i > -1 ) {
           // clear old values
           uOld[i] = vOld[i] = 0; 
           rOld[i] = 0;
           gOld[i] = bOld[i] = 0;
           
           // calc avg speed
           avgSpeed += u[i] * u[i] + v[i] * v[i];
           
           // calc avg density
           tmp_r = Math.min(1.0, r[i]);
           tmp_g = Math.min(1.0, g[i]);
           tmp_b = Math.min(1.0, b[i]);
           
           density = Math.max(tmp_r, Math.max(tmp_g, tmp_b));
           avgDensity += density;	// add it up
           
           // calc deviation (for uniformity)
           currentDeviation = density - avgDensity;
           totalDeviations += currentDeviation * currentDeviation;
           
           // fade out old
           r[i] = tmp_r * holdAmount;
           g[i] = tmp_g * holdAmount;
           b[i] = tmp_b * holdAmount;
           
       }
       avgDensity *= _invNumCells;
       avgSpeed *= _invNumCells;
       
       uniformity = 1.0 / (1 + totalDeviations * _invNumCells);		// 0: very wide distribution, 1: very uniform
   }
   
   private function addSourceUV():Void 
   {
       var i:Int = numCells;
       while ( --i > -1 ) {
           u[i] += deltaT * uOld[i];
           v[i] += deltaT * vOld[i];
       }
   }
   
   private function addSourceRGB():Void 
   {
       var i:Int = numCells;
       while ( --i > -1 ) {
           r[i] += deltaT * rOld[i];
           g[i] += deltaT * gOld[i];
           b[i] += deltaT * bOld[i];		
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
   
   private function advectRGB(du:Array<Float>, dv:Array<Float>):Void 
   {
       var i:Int, j:Int, i0:Int, j0:Int;
       var x:Float, y:Float, s0:Float, t0:Float, s1:Float, t1:Float, dt0x:Float, dt0y:Float;
       var index:Int;
       
       dt0x = deltaT * _NX;
       dt0y = deltaT * _NY;
       
       j = _NY;
       while (j > 0) 
       {
           i = _NX;
           while (i > 0)
           {
               index = FLUID_IX(i, j);
               x = i - dt0x * du[index];
               y = j - dt0y * dv[index];
               
               if (x > _NX + 0.5) x = _NX + 0.5;
               if (x < 0.5)     x = 0.5;
               
               i0 = Std.int(x);
               
               if (y > _NY + 0.5) y = _NY + 0.5;
               if (y < 0.5)     y = 0.5;
               
               j0 = Std.int(y);
               
               s1 = x - i0;
               s0 = 1 - s1;
               t1 = y - j0;
               t0 = 1 - t1;
               
               
               i0 = FLUID_IX(i0, j0);
               j0 = i0 + _NX2;
               r[index] = s0 * ( t0 * rOld[i0] + t1 * rOld[j0] ) + s1 * ( t0 * rOld[i0+1] + t1 * rOld[j0+1] );
               g[index] = s0 * ( t0 * gOld[i0] + t1 * gOld[j0] ) + s1 * ( t0 * gOld[i0+1] + t1 * gOld[j0+1] );                  
               b[index] = s0 * ( t0 * bOld[i0] + t1 * bOld[j0] ) + s1 * ( t0 * bOld[i0+1] + t1 * bOld[j0+1] );	

               --i;			
           }
           --j;
       }
       setBoundaryRGB();
   }
   
   private function diffuse(b:Int, c:Array<Float>, c0:Array<Float>, _diff:Float):Void 
   {
       var a:Float = deltaT * _diff * _NX * _NY;
       linearSolver(b, c, c0, a, 1.0 + 4 * a);
   }
   
   private function diffuseRGB(_diff:Float):Void 
   {
       var a:Float = deltaT * _diff * _NX * _NY;
       linearSolverRGB(a, 1.0 + 4 * a);
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
   
   private function linearSolverRGB(a:Float, c:Float):Void 
   {
       var k:Int, i:Int, j:Int;	
       var index3:Int, index4:Int, index:Int;
       
       c = 1 / c;

       k = 0;
       while (k < solverIterations)
       {     
           j = _NY;
           while (j > 0)
           {
                   index = FLUID_IX(_NX, j );
                   index3 = index - _NX2;
                   index4 = index + _NX2;
                   i = _NX;
                   while (i > 0)
                   {       
                       r[index] = ( ( r[index-1] + r[index+1]  +  r[index3] + r[index4] ) * a  +  rOld[index] ) * c;
                       g[index] = ( ( g[index-1] + g[index+1]  +  g[index3] + g[index4] ) * a  +  gOld[index] ) * c;
                       b[index] = ( ( b[index-1] + b[index+1]  +  b[index3] + b[index4] ) * a  +  bOld[index] ) * c;                                
                       
                       --index;
                       --index3;
                       --index4;
                       --i;
                   }
                   --j;
           }
           setBoundaryRGB();
           ++k;
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
   
   private function setBoundaryRGB():Void 
   {
       if( !wrapX && !wrapY ) return;
       
       var dst1:Int, dst2:Int, src1:Int, src2:Int;
       var i:Int;
       var step:Int = FLUID_IX(0, 1) - FLUID_IX(0, 0);
       
       if ( wrapX ) {
           dst1 = FLUID_IX(0, 1);
           src1 = FLUID_IX(1, 1);
           dst2 = FLUID_IX(_NX+1, 1 );
           src2 = FLUID_IX(_NX, 1);
           
           src1 ^= src2;
           src2 ^= src1;
           src1 ^= src2;

           i = _NY;
           while (i > 0)
           {
               r[dst1] = r[src1]; g[dst1] = g[src1]; b[dst1] = b[src1]; dst1 += step;   src1 += step;   
               r[dst2] = r[src2]; g[dst2] = g[src2]; b[dst2] = b[src2]; dst2 += step;   src2 += step;   
               --i;
           }
       }
       
       if ( wrapY ) {
           dst1 = FLUID_IX(1, 0);
           src1 = FLUID_IX(1, 1);
           dst2 = FLUID_IX(1, _NY+1);
           src2 = FLUID_IX(1, _NY);
           
           src1 ^= src2;
           src2 ^= src1;
           src1 ^= src2;

           i = _NX;
           while (i > 0)
           {
               r[dst1] = r[src1]; g[dst1] = g[src1]; b[dst1] = b[src1];  ++dst1; ++src1;   
               r[dst2] = r[src2]; g[dst2] = g[src2]; b[dst2] = b[src2];  ++dst2; ++src2;   
               --i;
           }
       }
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
   
   private function swapR():Void
   { 
       _tmp = r;
       r = rOld;
       rOld = _tmp;
   }
   
   private function swapRGB():Void
   { 
       _tmp = r;
       r = rOld;
       rOld = _tmp;
       
       _tmp = g;
       g = gOld;
       gOld = _tmp;
       
       _tmp = b;
       b = bOld;
       bOld = _tmp;
   }
   
   inline private function FLUID_IX(i:Int, j:Int):Int
   { 
       return i + _NX2 * j;
   }
   
   public function shiftLeft():Void
   {                
       var j:Int = _NX2 - 1, k:Int, ind:Int;
       for (i in 0..._NY2)
       {
           k = i * _NX2 + j;
           ind = k - j;

           r.insert(k, r.splice(ind, 1)[0]);
           g.insert(k, g.splice(ind, 1)[0]);
           b.insert(k, b.splice(ind, 1)[0]);
           
           u.insert(k, u.splice(ind, 1)[0]);
           v.insert(k, v.splice(ind, 1)[0]);
           
           rOld.insert(k, rOld.splice(ind, 1)[0]);
           gOld.insert(k, gOld.splice(ind, 1)[0]);
           bOld.insert(k, bOld.splice(ind, 1)[0]);
           
           uOld.insert(k, uOld.splice(ind, 1)[0]);
           vOld.insert(k, vOld.splice(ind, 1)[0]);
       }
   }
   
   public function shiftRight():Void
   {                
       var j:Int = _NX2 - 1, k:Int, ind:Int;
       for (i in 0..._NY2)
       {
           k = i * _NX2 + j;
           ind = k - j;

           r.insert(ind, r.splice(k, 1)[0]);
           g.insert(ind, g.splice(k, 1)[0]);
           b.insert(ind, b.splice(k, 1)[0]);

           u.insert(ind, u.splice(k, 1)[0]);
           v.insert(ind, v.splice(k, 1)[0]);

           rOld.insert(ind, rOld.splice(k, 1)[0]);
           gOld.insert(ind, gOld.splice(k, 1)[0]);
           bOld.insert(ind, bOld.splice(k, 1)[0]);

           uOld.insert(ind, uOld.splice(k, 1)[0]);
           vOld.insert(ind, vOld.splice(k, 1)[0]);
       }
   }
   
   public function shiftUp():Void
   {
       r = r.concat(r.slice(0, _NX2));
       r.splice(0, _NX2);
       
       g = g.concat(g.slice(0, _NX2));
       g.splice(0, _NX2);
       
       b = b.concat(b.slice(0, _NX2));
       b.splice(0, _NX2);
       
       u = u.concat(u.slice(0, _NX2));
       u.splice(0, _NX2);
       
       v = v.concat(v.slice(0, _NX2));
       v.splice(0, _NX2);
       
       rOld = rOld.concat(rOld.slice(0, _NX2));
       rOld.splice(0, _NX2);
       
       gOld = gOld.concat(gOld.slice(0, _NX2));
       gOld.splice(0, _NX2);
       
       bOld = bOld.concat(bOld.slice(0, _NX2));
       bOld.splice(0, _NX2);
       
       uOld = uOld.concat(uOld.slice(0, _NX2));
       uOld.splice(0, _NX2);
       
       vOld = vOld.concat(vOld.slice(0, _NX2));
       vOld.splice(0, _NX2);
   }
   
   public function shiftDown():Void
   {
       var offset:Int = (_NY2 - 1) * _NX2;
       var offset2:Int = offset + _NX2;
        
       r = r.slice(offset, offset2).concat(r);
       r.splice(numCells, _NX2);
       
       g = g.slice(offset, offset2).concat(g);
       g.splice(numCells, _NX2);
       
       b = b.slice(offset, offset2).concat(b);
       b.splice(numCells, _NX2);
       
       u = u.slice(offset, offset2).concat(u);
       u.splice(numCells, _NX2);
       
       v = v.slice(offset, offset2).concat(v);
       v.splice(numCells, _NX2);
       
       rOld = rOld.slice(offset, offset2).concat(rOld);
       rOld.splice(numCells, _NX2);
       
       gOld = gOld.slice(offset, offset2).concat(gOld);
       gOld.splice(numCells, _NX2);
       
       bOld = bOld.slice(offset, offset2).concat(bOld);
       bOld.splice(numCells, _NX2);
       
       uOld = uOld.slice(offset, offset2).concat(uOld);
       uOld.splice(numCells, _NX2);
       
       vOld = vOld.slice(offset, offset2).concat(vOld);
       vOld.splice(numCells, _NX2);
   }
   
   public function randomizeColor():Void 
   {
       var index:Int;
       for(i in 0...width) {
           for(j in 0...height) {
               index = FLUID_IX(i, j);
               r[index] = rOld[index] = Math.random();
               if(isRGB) {
                   g[index] = gOld[index] = Math.random();
                   b[index] = bOld[index] = Math.random();
               }
           } 
       }
   }
           
   inline public function getIndexForCellPosition(i:Int, j:Int):Int 
   {
       if(i < 1) i=1; else if(i > _NX) i = _NX;
       if(j < 1) j=1; else if(j > _NY) j = _NY;
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