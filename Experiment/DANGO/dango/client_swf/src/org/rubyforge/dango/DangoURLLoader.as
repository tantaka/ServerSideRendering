package org.rubyforge.dango {
	/**
	 * Dangoで利便性を高めたURLLoader
	 *
	 */

	import flash.net.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.system.*;
		
	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	
	import org.rubyforge.dango.*;
	
	public class DangoURLLoader implements IEventDispatcher {
		
		private var url:String; 									// 取得URL
		private var event_name:String;						// 発生させるイベント名
		private var is_debug:Boolean; 						// Debugモードかどうかのフラグ
		
		private var dispatcher:EventDispatcher; 	// Event送出用
		
		/**
		 * DangoURLLoader
		 * URLから認証情報を取得開始（コンストラクタ）
		 *
		 * @param u:String
		 * @param e:Strin
		 * @param d:Boolean = false
		 */
		public function DangoURLLoader(u:String, e:String, d:Boolean = false){
			if(is_debug){ trace("DangoURLLoader:start"); }
			
			// 初期設定
			url = u;
			event_name = e;
			is_debug = d;
			
			// データ受信準備
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			
			// 各種イベントの登録
			configureListeners(loader);
			
			// Event送出用
			dispatcher = new EventDispatcher(this); 
			
			// データ受信
			var request:URLRequest = new URLRequest(url);
			try {
				loader.load(request);
			} catch (error:Error) {
				var receive_object:Object = {"status":"failed", "data":"Unable to load requested document."};
				this.dispatchEvent(new DangoURLLoaderEvent(event_name, receive_object));
			}
			
		}
		
		private function configureListeners(loader:IEventDispatcher):void {
			loader.addEventListener(Event.COMPLETE, completeHandler);
			loader.addEventListener(Event.OPEN, openHandler);
			loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		private function completeHandler(event:Event):void {
			var loader:URLLoader = URLLoader(event.target);
			if(is_debug){ trace("DangoURLLoader:completeHandler: " + loader.data); }
			
			var receive_object:Object = {"status":"success", "data":loader.data};
			this.dispatchEvent(new DangoURLLoaderEvent(event_name, receive_object));
		}

		private function openHandler(event:Event):void {
			var msg:String = "DangoURLLoader:openHandler: " + event;
			if(is_debug){ trace(msg); }
		}

		private function progressHandler(event:ProgressEvent):void {
			var msg:String = "DangoURLLoader:progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal;
			if(is_debug){ trace(msg); }
		}

		private function securityErrorHandler(event:SecurityErrorEvent):void {
			var msg:String = "DangoURLLoader:securityErrorHandler";
			if(is_debug){ trace(msg); }
			
			var receive_object:Object = {"status":"failed", "data":msg};
			this.dispatchEvent(new DangoURLLoaderEvent(event_name, receive_object));
		}

		private function httpStatusHandler(event:HTTPStatusEvent):void {
			var msg:String = "DangoURLLoader:httpStatusHandler: " + event;
			if(is_debug){ trace(msg); }
		}

		private function ioErrorHandler(event:IOErrorEvent):void {
			var msg:String = "DangoURLLoader:ioErrorHandler" + event;
			if(is_debug){ trace(msg); }
			
			var receive_object:Object = {"status":"failed", "data":msg};
			this.dispatchEvent(new DangoURLLoaderEvent(event_name, receive_object));
		}
		
		// Event送出用
		public function addEventListener(type:String, listener:Function, 
																		 useCapture:Boolean = false, 
																		 priority:int = 0, 
																		 useWeakReference:Boolean = false):void{
			dispatcher.addEventListener(type, listener, useCapture, priority);
		}
		public function dispatchEvent(evt:Event):Boolean{
			return dispatcher.dispatchEvent(evt);
		}
		public function hasEventListener(type:String):Boolean{
			return dispatcher.hasEventListener(type);
		}
		public function removeEventListener(type:String, listener:Function, 
																				useCapture:Boolean = false):void{
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		public function willTrigger(type:String):Boolean {
			return dispatcher.willTrigger(type);
		}
	}
}

