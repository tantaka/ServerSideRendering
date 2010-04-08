
package org.rubyforge.dango {
	import flash.events.*;
	
	public class DangoErrorEvent extends Event {
		private var dango_type:String;
		public var code:uint;
		public var message:String;
		
		public function DangoErrorEvent(type:String, code_orig:uint, message_orig:String, 
																			bubbles:Boolean = false, 
																			cancelable:Boolean = false) {
			dango_type = type;
			code = code_orig;
			message = message_orig;
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event {
			return(new DangoErrorEvent(dango_type, code, message));
		}
	}
}
