
package org.rubyforge.dango {
	/**
	 * Dangoで使っているユーティリティクラス
	 *
	 */
	
	import flash.utils.*;
	
	public class DangoUtil {
		
		/**
		 * array_delete
		 * Arrayから特定アイテムを削除した結果を返す
		 *
		 * @param arr:Array
		 * @param delete_item:*
		 * @return Array
		 */
		public static function array_delete(arr:Array, delete_item:*):Array {

			// filterメソッドだと「ABC データは破損しているため、境界外の読み取りが試行されました。」が
			// Flashバージョンによって出るのでforループで作り直し
/*
			var filter_function:Function = function filter_function(item:*, idx:int, arr:Array):Boolean {
				return(item != delete_item);
			};
			return(arr.filter(filter_function));
*/
			var temp_arr:Array = [];
			for (var i:uint = 0; i < arr.length; i ++) {
				var item:* = arr[i];
				if (item != delete_item){
					temp_arr.push(item);
				}
			}
			return(temp_arr);
		}
		
		/**
		 * string_byte_length
		 * Stringのバイト数を返す
		 *
		 * @param str:String
		 * @return uint
		 */
		public static function string_byte_length(str:String):uint {
			var str_size_ba:ByteArray = new ByteArray();
			str_size_ba.writeUTFBytes(str);
			var size:uint = str_size_ba.length;
			return(size);
		}
		
		/**
		 * date2str
		 * Date型から日時のStringにして返す
		 *
		 * @param date:Date
		 * @return String
		 */
		public static function date2str(date:Date):String {
//			var df:DateFormatter = new DateFormatter();
//			df.formatString = "YYYY-MM-DD HH:NN:SS";
//			var str:String = df.format(date);

			var str:String = "" + 
											 date.getFullYear() + "-" + 
											 (date.getMonth() + 1) + "-" + 
											 date.getDate() + " " + 
											 date.getHours() + ":" + 
											 date.getMinutes() + ":" + 
											 date.getSeconds() + "." + 
											 date.getMilliseconds() + " TZ=" + 
											 (date.getTimezoneOffset() / 60);
			return(str);
		}
		
		/**
		 * now2str
		 * 現在時間を返す
		 *
		 * @return String
		 */
		public static function now2str():String {
			return(date2str(new Date()));
		}
		
		/**
		 * parse_query
		 * URLのQUERY_STRINGのparse
		 *
		 * @param query:String
		 * @param parse1:String = "&"
		 * @param parse2:String = "="
		 * @return Object
		 */
		public static function parse_query(query:String, parse1:String = "&", parse2:String = "="):Object {
			// 受信データの分解
			var arr_split_equal:Array;
			var ret_object:Object = {};
			
			var regex1:RegExp = new RegExp(parse1);
			var regex2:RegExp = new RegExp(parse2);
			
			var arr_split_and:Array = query.split(regex1);
			
			for (var i:uint = 0; i < arr_split_and.length; i++) {
				arr_split_equal = arr_split_and[i].split(regex2);
				ret_object[String(arr_split_equal[0])] = String(arr_split_equal[1]);
			}
			
			return(ret_object);
		}
		
		/**
		 * get_flashvars
		 * parametersからflashvarsを分解してobjectに入れて返す
		 *
		 * @param app:Object
		 * @return Object
		 */
		public static function get_flashvars(app:Object):Object {
			var flash_vars:Object = {};
			var value:String;
			for (var key:String in app.parameters) {
				value = app.parameters[key];
				flash_vars[key] = value;
			}
			
			return(flash_vars);
		}
		
		/**
		 *  オブジェクトの深いコピーを行う
		 * 
		 *  @param value 元になるObject
		 *  @return	コピーされたObject
		 */ 
		public static function deep_copy(obj:Object):Object {
			var byta:ByteArray = new ByteArray();
			byta.writeObject(obj);
			byta.position = 0;
			var result:Object = byta.readObject();
			return result;
		}
		
		/**
		 *  オブジェクトを読みやすい形式に変換
		 * 
		 *  @param obj 元になるObject
		 *  @return	String
		 */ 
		public static function toString(obj:Object):String {
			var str:String = parse_obj(obj, 0);
			return str;
		}
		
		private static function parse_obj(obj:Object, indent:uint):String{
			var str:String = "";
			
			if(obj == null){ 
				str += indent_str(indent) + "null" + "\n";
			} else {
				var type:String = typeof(obj);
				if(type == "boolean" || type == "number"){
					str += indent_str(indent) + obj.toString() + "\n";
					
				} else if(type == "string"){
						str += indent_str(indent) + "\"" + obj.toString() + "\"" + "\n";
						
				} else if(type == "object"){
					for(var i:String in obj) {
						str += indent_str(indent) + i + "=>\n";
						str += parse_obj(obj[i], indent + 1);
					}
					
				} else {
					str += indent_str(indent) + "(" + type + ")" + "\n";
				}
			}
			return str;
		}
		
		private static function indent_str(indent:uint):String{
			var str:String = "";
			for (var j:uint = 0; j < indent * 2; j++) {
				str += " ";
			}
			return str;
		}
		
	}
}
