
package org.rubyforge.dango {
	/**
	 * DangoのAS3Mode用のクラス
	 *
	 */
	
	import org.rubyforge.dango.*;
	import flash.events.*;

	public class DangoAS3Mode implements IEventDispatcher {
		
		private var dispatcher:EventDispatcher; 	// Event送出用
		
		private var dango_client:DangoClientFramework;
		public var all_sid_list:Array = []; //接続しているクライアントのsidの一覧
		public var sid:int;
		
		/**
		 * DangoAS3Mode
		 * コンストラクタ
		 *
		 * @param config:*
		 * @return void
		 */
		public function DangoAS3Mode(config:*):void{
			// Event送出用
			dispatcher = new EventDispatcher(this); 
			
			// DangoClientFrameworkコネクション
			try{
				dango_client = new DangoClientFramework(config);
			} catch(error:Error) {
				trace(error.message);
			}
			
			this.sid = dango_client.sid;
			
			// エラー時のイベントリスナー
			dango_client.addEventListener("DangoError", connection_error);
			
			// イベント
			dango_client.addEventListener("dango__connect" , dango__connect);
			dango_client.addEventListener("dango_notice_send_object" , dango_notice_send_object);
			dango_client.addEventListener("dango_notice_current_sids", dango_notice_current_sids);
		}
		
		// 接続エラー
		private function connection_error(evt:DangoErrorEvent):void {
			this.dispatchEvent(new DangoErrorEvent("DangoError", evt.code, evt.message));
		}
		
		/**
		 * send_object
		 * クライアント同士のデータ送信
		 *
		 * @param object:Objcet
		 * @param sids:Array
		 * @return void
		 */
		public function send_object(object:Object, sids:Array):void {
//			dango_client.send_action("send_object", {"object":object, "sids":sids}, true);
			dango_client.send_action("send_object", {"object":object, "sids":sids});
//			dango_client.send_action("send_object", object, true);
		}
		
		/**
		 * dango__connect
		 * 接続しているクライアントのsidの一覧の記録
		 *
		 * @return Array
		 */
		private function dango__connect(evt:DangoReceiveEvent):void {
			this.sid = dango_client.sid;
			this.dispatchEvent(new DangoAS3ModeReceiveEvent("dango__connect", {}));
		}
		
		/**
		 * dango_notice_send_object
		 * 接続しているクライアントのsidの一覧取得
		 *
		 * @return Array
		 */
		private function dango_notice_send_object(evt:DangoReceiveEvent):void {
			var recv_data:Object = evt.receive_data;
			
			this.dispatchEvent(new DangoAS3ModeReceiveEvent("dango_as3mode_receive", recv_data));
		}
		
		/**
		 * dango_notice_current_sids
		 * 接続しているクライアントのsidの一覧の記録
		 *
		 * @return Array
		 */
		private function dango_notice_current_sids(evt:DangoReceiveEvent):void {
			var ret:Object = evt.receive_data;
			all_sid_list = ret["sids"];
			
			var recv_data:Object = {};
			recv_data["_from_sid"] = ret["_from_sid"]
			if(ret["is_connect"]){
				this.dispatchEvent(new DangoAS3ModeReceiveEvent("dango__other_connect", recv_data));
			}
			if(ret["is_close"]){
				this.dispatchEvent(new DangoAS3ModeReceiveEvent("dango__other_close", recv_data));
			}
		}
		
		
		/**
		 * addEventListener
		 * Event送出用
		 *
		 * @param type:String
		 * @param listener:Function
		 * @param useCapture:Boolean = false
		 * @param priority:int = 0
		 * @param useWeakReference:Boolean = false
		 * @return void
		 */
		public function addEventListener(type:String, listener:Function, 
																		 useCapture:Boolean = false, 
																		 priority:int = 0, 
																		 useWeakReference:Boolean = false):void{
			dispatcher.addEventListener(type, listener, useCapture, priority);
		}
		
		/**
		 * dispatchEvent
		 * Event送出用
		 *
		 * @param evt:Event
		 * @return Boolean
		 */
		public function dispatchEvent(evt:Event):Boolean{
			return dispatcher.dispatchEvent(evt);
		}
		
		/**
		 * hasEventListener
		 * Event送出用
		 *
		 * @param type:String
		 * @return Boolean
		 */
		public function hasEventListener(type:String):Boolean{
			return dispatcher.hasEventListener(type);
		}
		
		/**
		 * removeEventListener
		 * Event送出用
		 *
		 * @param type:String
		 * @param listener:Function
		 * @param useCapture:Boolean = false
		 * @return void
		 */
		public function removeEventListener(type:String, listener:Function, 
																				useCapture:Boolean = false):void{
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		/**
		 * willTrigger
		 * Event送出用
		 *
		 * @param type:String
		 * @return Boolean
		 */
		public function willTrigger(type:String):Boolean {
			return dispatcher.willTrigger(type);
		}
		
	}
}
