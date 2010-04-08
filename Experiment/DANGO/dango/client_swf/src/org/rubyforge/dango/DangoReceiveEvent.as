
package org.rubyforge.dango {
	import flash.events.*;
	
	public class DangoReceiveEvent extends Event {
		private var dango_type:String;
		public var receive_data:Object;
		public var receive_count_no:uint;
		
		public function DangoReceiveEvent(type:String, 
																			receive_data_orig:Object, 
																			receive_count_no_orig:uint, 
																			bubbles:Boolean = false, 
																			cancelable:Boolean = false) {
			dango_type = type;
			receive_data = receive_data_orig;
			receive_count_no = receive_count_no_orig;
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event {
			return(new DangoReceiveEvent(dango_type, receive_data, receive_count_no));
		}
	}
}
