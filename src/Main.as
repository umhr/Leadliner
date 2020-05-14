package 
{
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	/**
	 * 引き出し線（leader line）
	 * 「敵機急速接近中！」
	 * 映画とかで見るレーダー画面では、
	 * 敵機の位置を示す点と敵/味方機種名をあらわす文字
	 * がぶつからないようにレイアウトされている。
	 * どういう風に作ったら、計算コストをかけずにそれっぽくなるかなと思って
	 * 作ってみた。
	 * でも却ってあたりまくる時もある。
	 * 「うろうろ逃げ回るよりは当たらんものだ」
	 * 
	 * 現在は、点の位置だけを見ている。
	 * 文字同士の衝突判定は行っていない。
	 * 点の近くに別な点がある場合に、斥力方向に文字が置かれるようにしているだけ。
	 * 距離も固定。
	 * 
	 * 次の三点をやればより適切な位置が導けるが、計算量が大きくなりそうなので工夫が必要。
	 * ・文字同士の衝突判定を行い、衝突しない位置を探す。
	 * ・文字と点の距離を可変にして、密集地でも避けられるように。
	 * ・引き出し線同士がクロスしないように置き換える。
	 * 
	 * 引力、斥力をうまく組み合わせると良いのかもしれないけど、それはまた今度。
	 * 
	 * 実際のレーダではFPSがずっと低そうだけど、どうなんだろう。
	 * 
	 * 参考
	 * http://blog.goo.ne.jp/chickenman_nfc1/e/8cb6035545226e710427cffdea9de3fe
	 * @author umhr
	 */
	[SWF(width = 465, height = 465, backgroundColor = 0x001122, frameRate = 30)]
	public class Main extends Sprite 
	{
		private var _canvas:Sprite = new Sprite();
		private var _count:int;
		private var _nodeList:Vector.<Node> = new Vector.<Node>();
		/**
		 * Nodeにまとめちゃうともっとみやすいコードになりそうだけど、
		 * 計算時間が倍近くかかるので、躊躇
		 */
		private var _pointXList:Vector.<Number> = new Vector.<Number>();
		private var _pointYList:Vector.<Number> = new Vector.<Number>();
		private var _pointList:Vector.<Vector3D> = new Vector.<Vector3D>();
		public function Main() 
		{
			init();
		}
		private function init():void 
		{
			if (stage) onInit();
			else addEventListener(Event.ADDED_TO_STAGE, onInit);
		}
		
		private function onInit(event:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			_canvas.graphics.beginGradientFill(GradientType.RADIAL, [0x001929,0x000909], [1, 1], [0, 255],new Matrix(0.5,0,0,0.5,465*0.5,465*0.5));
			_canvas.graphics.drawRect(0, 0, 465, 465);
			_canvas.graphics.endFill();
			this.addChild(_canvas);
			
			var n:int = 25;
			for (var i:int = 0; i < n; i++) 
			{
				_nodeList[i] = new Node(i);
				_canvas.addChild(_nodeList[i]);
				_pointList[i] = new Vector3D(400 * (Math.random() - 0.5), 400 * (Math.random() - 0.5), 400 * (Math.random() - 0.5));
			}
			//onEnterFrame(null);
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(e:Event):void 
		{
			var matrix3D:Matrix3D = new Matrix3D();
			var vector3D:Vector3D = new Vector3D(0.5, 0.8, 0.4);
			vector3D.normalize();
			matrix3D.appendRotation(_count, vector3D);
			
			var n:int = _pointList.length;
			for (var i:int = 0; i < n; i++) 
			{
				vector3D = pertrans(matrix3D.transformVector(_pointList[i]));
				_pointXList[i] = vector3D.x;
				_pointYList[i] = vector3D.y;
			}
			
			escaper();
			_count ++;
		}
		
		private function pertrans(vector3D:Vector3D):Vector3D {
			var result:Vector3D = new Vector3D();
			var per:Number = 1000 / (1000 + vector3D.z);
			return new Vector3D(vector3D.x * per, vector3D.y * per, per);
		}
		
		/**
		 * 文字がぶつからないように、近くのノードとは反対方向を割り出す。
		 * 10フレームに一度だけにして、計算コストを低減。
		 */
		private function escaper():void {
			//var time:Number = new Date().time;
			var _radianList:Vector.<Number> = new Vector.<Number>();
			var n:int = _pointXList.length;
			var direction:Array = [];
			var i:int;
			var j:int;
			
			if (_count%5 == 0) {
					
				for (i = 0; i < n; i++) 
				{
					//八方向に
					direction = [0, 0, 0, 0, 0, 0, 0, 0];
					for (j = 0; j < n; j++) 
					{
						if (i == j) { continue };
						var px:Number = _pointXList[i] - _pointXList[j];
						var py:Number = _pointYList[i] - _pointYList[j];
						var length:Number = px * px + py * py;
						
						if (length > 2500) { continue };
						var r:int = int((8.5 + 4 * Math.atan2(py, px) / Math.PI) % 8);
						length = 1 / length;
						
						direction[(6 + r) % 8] += length * 0.5;
						direction[(7 + r) % 8] += length * 0.7;
						direction[r] += length;
						direction[(1 + r) % 8] += length * 0.7;
						direction[(2 + r) % 8] += length * 0.5;
					}
					var compass:int = direction.sort(Array.NUMERIC | Array.RETURNINDEXEDARRAY)[7];
					_nodeList[i].radian = Math.PI * compass / 4;
				}
				
			}
			//trace(new Date().time-time);
			
			for (i = 0; i < n; i++) 
			{
				_nodeList[i].draw(_pointXList[i], _pointYList[i]);
			}
		}
	}
	
}

/**
 * ノードです。
 */
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;
class Node extends Sprite {
	private var _radian:Number;
	private var direction:Number = 0;
	private var _textField:TextField = new TextField();
	private var _target:Shape = new Shape();
	public function Node(index:int) {
		_textField.text = "Zaku II";
		_textField.textColor = 0xCCCCFF;
		_textField.autoSize = "left";
		_textField.cacheAsBitmap = true;
		this.addChild(_textField);
		
		if(index == 0){
			_target.graphics.beginFill(0xFF0000, 1);
		}else {
			_target.graphics.beginFill(0x009966, 1);
		}
		_target.graphics.drawCircle(x + 465 * 0.5, y + 465 * 0.5, 2);
		_target.graphics.endFill();
		this.addChild(_target);
	}
	/**
	 * 線を描画し、文字やターゲットの位置を指定します。
	 * @param	graphics
	 * @param	x
	 * @param	y
	 */
	public function draw(x:Number, y:Number):void {
		this.graphics.clear();
		
		direction = radian * 0.1 + direction * 0.9;
		
		var tx:Number = Math.cos(direction) * 30;
		var ty:Number = Math.sin(direction) * 15;
		this.graphics.lineStyle(0, 0xCCCCFF);
		this.graphics.moveTo(x + 465 * 0.5, y + 465 * 0.5);
		//this.graphics.lineTo(tx + x + 465 * 0.5, ty + y + 465 * 0.5);
		this.graphics.lineTo(tx + x + 465 * 0.5-20, ty + y + 465 * 0.5);
		//this.graphics.lineTo(tx + x + 465 * 0.5 + 20, ty + y + 465 * 0.5);
		_textField.x = tx + x + 465 * 0.5 - 20;
		_textField.y = ty + y + 465 * 0.5 - 9;
		_target.x = x;
		_target.y = y;
	}
	
	public function get radian():Number { return _radian; }
	
	public function set radian(value:Number):void 
	{
		if (Math.abs(value-direction) > Math.PI) {
			if (value>direction) {
				value -= Math.PI * 2;
			}else {
				direction -= Math.PI * 2;
			}
		}
		
		_radian = value;
	}
}