
package org.rubyforge.dango {
	/**
	 * Dangoのクライアントフレームワーク本体のクラス
	 *
	 */
	
	import flash.net.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.*;
	import flash.system.*;
	import flash.display.*;
	
	import com.adobe.serialization.json.JSON;
	
	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.events.Event;

	import org.rubyforge.dango.DangoUtil;
	import org.rubyforge.dango.DangoErrorCode;

	public class DangoClientFramework implements IEventDispatcher {

		private var socket:Socket;								//ソケット
		private var dispatcher:EventDispatcher; 	// Event送出用
		
		private var default_encode_type:uint = 0;	// 送信データのエンコードタイプはJSON
		
		private var is_connect:Boolean = false; 	// 接続完了しているかどうか
		
		private var frame_rate:uint = 24; 				// デフォルトのフレームレート（想定値）
		
		private var polling_timer:Timer;							 // ポーリング（ハートビート）用タイマーの設定
		private var polling_timer_msec:uint = 5000; 	 // ポーリング（ハートビート）用タイマーのミリ秒
		
		private var delay_send_timer:Timer; 							// 遅延送信用のタイマーの設定
		private var delay_send_timer_msec:uint = 1500;		// 遅延送信用のタイマーのミリ秒
		private var delay_send_cache:Array = [];					// 遅延送信用のキャッシュ
		
		private var receive_cache_byta:ByteArray = new ByteArray; 		// 受信データの保管用のキャッシュ ByteArray
		private var receive_cache_do_phase:uint = 0;									// 受信データをどこまで処理してあるかのキャッシュ
		private var receive_encode_type:uint = 0;											// 受信データのエンコードタイプ
		private var receive_data_size:uint = 0;												// 受信データのデータサイズ
		
		private var recv_wait_do_cache:Array = [];					 // 実行待ち受信キャッシュ
		
		private var recv_do_count_no:uint = 0;						 // 受信実行の回数
		private var recv_do_timer_msec:uint;							 // 受信実行用タイマーの実行間隔
		private var recv_do_timer:Timer;									 // 受信実行用タイマーの追加
		private var recv_do_last_date:Date = new Date();	 // 受信キャッシュ用処理落ちチェック用
		
		private var send_recv_max_size:uint = 1024*1024;	 // データ送受信の最大バイト数
		
		public var server_time:String = "";						 // サーバーの時計
		
		private var server_host:String;
		private var server_port:int;
		private var is_debug:Boolean = false; 						// Debugモードかどうかのフラグ
		private var disp_obj:DisplayObject;
		private var policy_file_protocol:String;
		private var policy_file_host:String;
		private var policy_file_path:String;
		
		public var sid:int;
		private var has_sid:Boolean = false; 	// sidを取得完了しているかどうか
		
		/**
		 * DangoClientFramework
		 * コンストラクタ
		 *
		 * @param config:*
		 * @return void
		 */
		public function DangoClientFramework(config:*){
			trace("DangoClientFramework start...");
			trace("config=" + config);
			
			// 設定ファイルの読み込み
			if(config.hasOwnProperty("server_host")){ server_host = config.server_host; }
			if(config.hasOwnProperty("server_port")){ server_port = config.server_port; }
			if(config.hasOwnProperty("debug"      )){ is_debug    = config.debug;       }
			if(config.hasOwnProperty("disp_obj"   )){ disp_obj    = config.disp_obj;    }
			if(config.hasOwnProperty("policy_file_protocol")){ policy_file_protocol = config.policy_file_protocol; }
			if(config.hasOwnProperty("policy_file_host"    )){ policy_file_host     = config.policy_file_host; }
			if(config.hasOwnProperty("policy_file_path"    )){ policy_file_path     = config.policy_file_path; }
//			is_debug							= true;
			
			if(disp_obj){
				trace("disp_obj: "     + disp_obj);
				frame_rate = disp_obj.stage.frameRate;	 // フレームレート
			}
			
//			var policy_file_protocol:String  = config.policy_file_protocol;
//			var policy_file_host:String      = config.policy_file_host;
//			var policy_file_path:String      = config.policy_file_path;
			
			// 環境情報を出力
			if(is_debug){ trace("flash player: "     + Capabilities.version); }
			if(is_debug){ trace("isDebugger: "       + Capabilities.isDebugger); }
			if(is_debug){ trace("language: "         + Capabilities.language); }
			if(is_debug){ trace("os: "               + Capabilities.os); }
			if(is_debug){ trace("frame_rate: "       + frame_rate); }
			if(is_debug){ trace("Security.sandboxType:" + Security.sandboxType); }
			
			// Event送出用
			dispatcher = new EventDispatcher(this); 
			
			// policy_file
			if(!policy_file_protocol){ policy_file_protocol = "xmlsocket" };
			if(!policy_file_host)    { policy_file_host     = server_host };
			if(!policy_file_path)    { policy_file_path     = "/crossdomain.xml" };
			
			// ソケットの生成
			socket = new Socket();
			
			// ソケットのイベントリスナーの追加
			socket.addEventListener(Event.CONNECT, connectHandler, false);
			socket.addEventListener(Event.CONNECT, connectHandler, true);
			socket.addEventListener(Event.CLOSE, closeHandler, false);
			socket.addEventListener(Event.CLOSE, closeHandler, true);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler, false);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler, true);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler, false);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler, true);
			socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler, false);
			socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler, true);
			if(is_debug){ trace("registered event handling."); }
			
			// ポリシーファイルの読み込み
			var url_load_policy_file:String;
			if(policy_file_protocol == "xmlsocket"){
				url_load_policy_file = "xmlsocket://" + policy_file_host + ":" + policy_file_host;
			} else if(policy_file_protocol == "http"){
				url_load_policy_file = "http://" + policy_file_host + policy_file_path;
			}
			
			if(is_debug){ trace("url_load_policy_file=" + url_load_policy_file); }
			Security.loadPolicyFile(url_load_policy_file);
			
			// 接続
			try{
				if(is_debug){ trace("connectiong... host=" + server_host + " port=" + server_port); }
				socket.connect(server_host, server_port);
				if(is_debug){ trace("connected host=" + server_host + " port=" + server_port); }
			} catch(err:Error){
				if(is_debug){ trace("connect error err=" + err + " name=" + err.name + " message=" + err.message); }
				return(void);
			}
			
			// polling用タイマーの設定
			var polling_timer:Timer = new Timer(polling_timer_msec, 0); 				 // タイマーの追加
			polling_timer.addEventListener(TimerEvent.TIMER, polling_callback);  // イベントリスナーの発行
			polling_timer.start();																							 // タイマーの作動開始
			
			// 遅延送信用タイマーの設定
			var delay_send_timer:Timer = new Timer(delay_send_timer_msec, 0); 				 // タイマーの追加
			delay_send_timer.addEventListener(TimerEvent.TIMER, delay_send_callback);  // イベントリスナーの発行
			delay_send_timer.start(); 																								 // タイマーの作動開始
			
			// 受信実行用タイマーの設定(2フレームごとに動かすよう変更)
			recv_do_timer_msec = uint((1000 * 2) / frame_rate);
			if(is_debug){ trace("DangoClientFramework:recv_do_timer_msec:" + recv_do_timer_msec); }
			recv_do_timer = new Timer(recv_do_timer_msec, 0);													 // タイマーの追加
			recv_do_timer.addEventListener(TimerEvent.TIMER, recv_do_callback); 			 // イベントリスナーの発行
			recv_do_timer.start();																										 // タイマーの作動開始
			
			// 接続完了のときに接続完了をサーバーに通知するためのハートビート送信
			var hb_id:String = make_heartbeat();
//			if(is_debug){ trace("DangoClientFramework:send _notice_heart_beat:" + hb_id + ":" + DangoUtil.now2str()); }
			this.send_action("_notice_heart_beat", { "_hb_id": hb_id}); // ハートビート送信
		}
		
		/**
		 * connectHandler
		 * 接続イベントの処理
		 *
		 * @param evt:Event
		 * @return void
		 */
		private function connectHandler(evt:Event):void {
			is_connect = true;
			var msg:String = "DangoClientFramework:connectHandler:" + DangoUtil.now2str();
			if(is_debug){ trace(msg); }
		}
		
		/**
		 * closeHandler
		 * 切断イベントの処理
		 *
		 * @param evt:Event
		 * @return void
		 */
		private function closeHandler(evt:Event):void {
			// タイマーが動いていれば止める
			if(polling_timer != null && polling_timer.running){ polling_timer.stop(); }
			
			is_connect = false;
			var msg:String = "DangoClientFramework:closeHandler:" + DangoUtil.now2str();
			if(is_debug){ trace(msg); }
			this.dispatchEvent(new DangoErrorEvent("DangoError", DangoErrorCode.CloseError, msg));
		}
		
		/**
		 * securityErrorHandler
		 * セキュリティエラーイベントの処理
		 *
		 * @param evt:Event
		 * @return void
		 */
		private function securityErrorHandler(evt:SecurityErrorEvent):void {
			// タイマーが動いていれば止める
			if(polling_timer != null && polling_timer.running){ polling_timer.stop(); }
			
			is_connect = false;
			var msg:String = "DangoClientFramework:securityErrorHandler:text=" + evt.text + ":" + DangoUtil.now2str();
			
			if(is_debug){ trace(msg); }
			this.dispatchEvent(new DangoErrorEvent("DangoError", DangoErrorCode.SecurityError, msg));
		}
		
		/**
		 * ioErrorHandler
		 * IOエラーイベントの処理
		 *
		 * @param evt:Event
		 * @return void
		 */
		private function ioErrorHandler(evt:IOErrorEvent):void {
			// タイマーが動いていれば止める
			if(polling_timer != null && polling_timer.running){ polling_timer.stop(); }
			
			is_connect = false;
			var msg:String = "DangoClientFramework:ioErrorHandler:" + DangoUtil.now2str();
			if(is_debug){ trace(msg); }
			this.dispatchEvent(new DangoErrorEvent("DangoError", DangoErrorCode.IOError, msg));
		}
		
		/**
		 * socketDataHandler
		 * プログレスイベントの処理：実体はsocket_read_push_cache
		 *
		 * @param evt:Event
		 * @return void
		 */
		private function socketDataHandler(evt:ProgressEvent):void {
			socket_read_push_cache();
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
		
		/**
		 * socket_read_push_cache
		 * socketDataHandlerの実体処理
		 * データ受信、データのパース、実行待ちキャッシュに保存
		 *
		 * @param void
		 * @return void
		 */
		private function socket_read_push_cache():void{
			if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:" + DangoUtil.now2str()); }
			
			var crlf:String = "";
			var temp_byta:ByteArray = new ByteArray;
			
			socket.readBytes(receive_cache_byta, receive_cache_byta.length, socket.bytesAvailable); // データ読み込み
			
//			while(true){
			for(var j:uint = 0; j < 5; j++){
				// 長さ取得処理
				if(receive_cache_do_phase == 0){ 
					if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:receive_cache_do_phase == 0:" + DangoUtil.now2str()); }
					if(receive_cache_byta.length < 6){ break; } // 長さの読み込みが終わっていなければ
					
					try{
						if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:receive_cache_do_phase == 0:start read"); }
						receive_encode_type = receive_cache_byta.readByte(); // エンコードタイプ
						receive_data_size = receive_cache_byta.readUnsignedInt(); // データサイズ
						crlf = receive_cache_byta.readUTFBytes(1);
						
						if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:receive_encode_type=" + receive_encode_type); }
						if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:receive_data_size=" + receive_data_size); }
						
						if(receive_data_size > send_recv_max_size){ throw new DangoError("recv data size is max size over. maybe data broken."); }
						
						// receive_cache_bytaの不要な部分を削除
						if(receive_cache_byta.length - receive_cache_byta.position > 0){
							receive_cache_byta.readBytes(temp_byta, 0, receive_cache_byta.length - receive_cache_byta.position);
							receive_cache_byta = temp_byta;
							receive_cache_byta.position = 0;
						} else {
							receive_cache_byta = new ByteArray;
						}
						
						if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:receive_cache_do_phase == 0:end read:length=" + receive_cache_byta.length); }
						
						receive_cache_do_phase = 1; // データ受信に行く
						
					} catch(err:Error){
//						this.dispatchEvent(new DangoErrorEvent("DangoError", DangoErrorCode.IOError, "failed in DangoClientFramework:socket_read_push_cache:receive_cache_do_phase == 0"));
						
						// キャッシュに残っているデータを消して再度初めから受信できるようにする
						trace("DangoClientFramework:socket_read_push_cache:receive_cache_do_phase==0:err=" + err);
						receive_cache_do_phase = 0; // 長さから取得する
						receive_cache_byta = new ByteArray; // キャッシュを空にする
						break;
					}
					
				}
				
				// データ取得処理
				if(receive_cache_do_phase == 1){ 
					if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:receive_cache_do_phase == 1:" + DangoUtil.now2str()); }
					if(receive_cache_byta.length < receive_data_size){ break; } // データの読み込みが終わっていなければ
					
					try{
						if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:receive_cache_do_phase == 1:start read"); }
						var recv_data:String = receive_cache_byta.readUTFBytes(receive_data_size); // データ取得
						if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:recv_data=" + recv_data); }
						
						// データのパースと実行待ち受信キャッシュにデータを入れる
						var ret_obj_data:Array;
						if(recv_data != "" && recv_data != "\n"){	// データが空じゃないならdecode
							ret_obj_data = JSON.decode(recv_data) as Array;
							for(var i:uint = 0; i < ret_obj_data.length; i++){
								var notice_name:String      = ret_obj_data[i]["_notice_name"];
								var recv_server_time:String = ret_obj_data[i]["_server_time"];
								
								if(is_debug){ trace("DangoClientFramework:push recv_wait_do_cache:dango_" + notice_name + " i=" + i + " recv_server_time=" + recv_server_time); }
								recv_wait_do_cache.push([notice_name, ret_obj_data[i], recv_server_time, recv_do_count_no]);
								recv_do_count_no ++;
								if(is_debug){ trace("DangoClientFramework:pushed recv_wait_do_cache:recv_do_count_no=" + recv_do_count_no); }
							}
						} else {							// データが空なら空データを作ってreturn
							if(is_debug){ trace("DangoClientFramework:ret_obj_data is empty." + DangoUtil.now2str()); }
						}
						
						// receive_cache_bytaの不要な部分を削除
						if(receive_cache_byta.length - receive_cache_byta.position > 0){
							receive_cache_byta.readBytes(temp_byta, 0, receive_cache_byta.length - receive_cache_byta.position);
							receive_cache_byta = temp_byta;
							receive_cache_byta.position = 0;
						} else {
							receive_cache_byta = new ByteArray;
						}
						if(is_debug){ trace("DangoClientFramework:socket_read_push_cache:receive_cache_do_phase == 1:end read:length=" + receive_cache_byta.length); }
						
						receive_cache_do_phase = 0; // データ受信に行く
						
					} catch(err:Error){
//						this.dispatchEvent(new DangoErrorEvent("DangoError", DangoErrorCode.IOError, "failed in DangoClientFramework:socket_read_push_cache:receive_cache_do_phase == 1"));
						
						// キャッシュに残っているデータを消して再度初めから受信できるようにする
						trace("DangoClientFramework:socket_read_push_cache:receive_cache_do_phase==1:err=" + err);
						receive_cache_do_phase = 0; // 長さから取得する
						receive_cache_byta = new ByteArray; // キャッシュを空にする
						break;
					}
				}
			}
			
		}
		
		/**
		 * recv_do_callback
		 * 受信データの実行する処理
		 *
		 * @param evt:TimerEvent
		 * @return void
		 */
		public function recv_do_callback(evt:TimerEvent):void {
//			if(is_debug){ trace("DangoClientFramework:recv_do_callback:" + DangoUtil.now2str()); }
			
			// 前回から時間がかかりすぎている（処理落ちしかけている場合は）スキップ
//			var start_date:Date = new Date();
//			if(recv_do_last_date.time > start_date.time - (Number(recv_do_timer_msec) * 1.4)){ 
				
				if(recv_wait_do_cache.length > 0){
					var recv_arr:Array = recv_wait_do_cache.shift();
					var notice_name:String = recv_arr[0];
					var recv_data:Object   = recv_arr[1];
					server_time            = recv_arr[2];
					var count_no:uint      = recv_arr[3];
					
					if(notice_name == "_notice_sid"){ // 接続直後のsid通知なら
						this.sid = recv_data["_sid"];
						has_sid = true;
						if(is_debug){ trace("DangoClientFramework:this.sid=" + this.sid + " server_time=" + server_time); }
						this.dispatchEvent(new DangoReceiveEvent("dango__connect", {}, count_no));
						
					} else {													// 通常のデータならイベント発生
						if(is_debug){ trace("DangoClientFramework:dispatchEvent:dango_" + notice_name + " server_time=" + server_time); }
						this.dispatchEvent(new DangoReceiveEvent("dango__before_filter", recv_data, count_no));
						this.dispatchEvent(new DangoReceiveEvent("dango_" + notice_name, recv_data, count_no));
						this.dispatchEvent(new DangoReceiveEvent("dango__after_filter", recv_data, count_no));
					}
				}
//			}
			
//			recv_do_last_date = new Date(); // 前回の実行の終了時間の保持
		}
		
		
		/**
		 * polling_callback
		 * ハートビート用タイマーコールバック
		 *
		 * @param evt:TimerEvent
		 * @return void
		 */
		public function polling_callback(evt:TimerEvent):void {
//			if(is_debug){ trace("DangoClientFramework:polling_callback:" + DangoUtil.now2str() ); }
			if(socket.connected){
				var hb_id:String = make_heartbeat();
//				if(is_debug){ trace("DangoClientFramework:send _notice_heart_beat:" + hb_id + ":" + DangoUtil.now2str()); }
				this.send_action("_notice_heart_beat", { "_hb_id": hb_id}); // ハートビート送信
			}
		}
		
		/**
		 * polling_callback
		 * ハートビートの作成
		 *
		 * @return String
		 */
		public function make_heartbeat():String {
			return(String((new Date()).time) + String(this.sid));
		}
		
		/**
		 * delay_send_callback
		 * 遅延送信用タイマーコールバック
		 *
		 * @param evt:TimerEvent
		 * @return void
		 */
		public function delay_send_callback(evt:TimerEvent):void {
//			if(is_debug){ trace("DangoClientFramework:delay_send_callback:evt:" + evt); }
			if(!is_connect){ return(void); }
			if(!socket.connected){ return(void); }
			if(!has_sid){ return(void); }
			
			var send_obj_dup:Array;
			var i:uint;
			
			for (i = 0; i < 5; i++) {
				if(delay_send_cache.length == 0) { break; }
				
				// データをすぐ送信
				send_obj_dup = delay_send_cache.shift();
				this.send_data_to_server(send_obj_dup);
				if(is_debug){ trace("DangoClientFramework:delay_send_callback:sent:" + send_obj_dup[0]["_action_name"] + ":" + has_sid + ":" + DangoUtil.now2str()); }
			}
		}
		
		/**
		 * send data to server.
		 * クライアント側から使うサーバーへのデータ送信メソッド
		 *
		 * @param action_name:String
		 * @param send_obj:Object
		 * @param delay:Boolean=false
		 * @return void
		 */
		public function send_action(action_name:String, send_obj:Object, delay:Boolean=false):void {
			if(is_debug){ trace("DangoClientFramework:send_action:start:action_name=" + action_name + ":delay=" + delay + ":is_connect=" + is_connect + ":has_sid=" + has_sid + ":" + DangoUtil.now2str()); }
			
//			if(!is_connect){ throw new DangoError("error:not connect"); } // 接続されていない場合はエラー
			
			// 送信データの作成
			var send_obj_dup:Object = DangoUtil.deep_copy(send_obj);
			send_obj_dup["_action_name"] = action_name;
			send_obj_dup["_return_id"] = (new Date()).time;
			
			// delayフラグがあったり、接続がまだなら、遅延送信用のキャッシュにデータを入れる
			if(delay || !is_connect || (action_name != "_notice_heart_beat" && !has_sid)){
				delay_send_cache.push([send_obj_dup]);
				
				if(is_debug){ trace("DangoClientFramework:send_action:delay_pull:" + action_name + ":" + DangoUtil.now2str()); }
				return(void);
			}
			
			// データをすぐ送信
			this.send_data_to_server([send_obj_dup]);
//			if(is_debug){ trace("DangoClientFramework:send_action:end:" + action_name + ":" + DangoUtil.now2str()); }
		}
		
		/**
		 * send data to server.
		 * フレームワーク側のデータ送信の一般処理
		 *
		 * @param send_obj:Array
		 * @return void
		 */
		public function send_data_to_server( send_obj:Array ):void {
			var encode_type:uint = default_encode_type;
			
			// データが空ならJSONencodeしない
			var send_obj_str:String;
			if(send_obj == null){
				send_obj_str = "\n";
			} else {
				send_obj_str = JSON.encode(send_obj) + "\n";
			}

			var send_obj_size:int = DangoUtil.string_byte_length(send_obj_str);
			
//			if(is_debug){ trace("DangoClientFramework:send:" + encode_type + ":" + send_obj_size + ":" + send_obj_str); }

			// 長さ送信
			var byte_array:ByteArray = new ByteArray;
			byte_array.writeByte(encode_type);
			byte_array.writeUnsignedInt(send_obj_size);

			socket.writeBytes(byte_array, 0, 5);
			socket.writeUTFBytes("\n");
			socket.flush();

			// データ送信
			socket.writeUTFBytes(send_obj_str);
			socket.flush();
			
//			if(is_debug){ trace("DangoClientFramework:send_obj_str:" + send_obj_str + ":" + DangoUtil.now2str()); }
		}
		
		/**
		 * dango__connect の雛形
		 * すべてのdango通知の前処理用のメソッド
		 * オーバーライドして使うもの
		 *
		 * @param evt:DangoReceiveEvent
		 * @return void
		protected function dango__connect(evt:Object):void {
			trace("DangoClientFramework:receive dango__connect");
		}
		 */
		
		/**
		 * dango__after_filter の雛形
		 * すべてのdango通知の前処理用のメソッド
		 * オーバーライドして使うもの
		 *
		 * @param evt:DangoReceiveEvent
		 * @return void
		protected function dango__after_filter(evt:Object):void {
			trace("DangoClientFramework:receive dango__after_filter");
		}
		 */
		
	}
}
