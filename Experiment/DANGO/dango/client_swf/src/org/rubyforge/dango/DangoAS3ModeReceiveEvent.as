
package org.rubyforge.dango {
	import flash.events.*;
	
	public class DangoAS3ModeReceiveEvent extends Event {
		private var dango_type:String;
		public var receive_data:Object;
		public var receive_count_no:uint;
		
		public function DangoAS3ModeReceiveEvent(type:String, 
																			receive_data_orig:Object, 
																			bubbles:Boolean = false, 
																			cancelable:Boolean = false) {
			dango_type = type;
			receive_data = receive_data_orig;
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event {
			return(new DangoAS3ModeReceiveEvent(dango_type, receive_data));
		}
	}
}
