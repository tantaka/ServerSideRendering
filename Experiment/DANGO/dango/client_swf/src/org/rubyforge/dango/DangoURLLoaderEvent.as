
package org.rubyforge.dango {
	/**
	 * Dangoで利便性を高めたURLLoaderのイベントクラス
	 *
	 */
	import flash.net.*;
	import flash.events.*;

	import org.rubyforge.dango.*;
	
	public class DangoURLLoaderEvent extends Event {
		private var dango_type:String;
		public var receive_object:Object;
		
		public function DangoURLLoaderEvent(type:String, receive_object_orig:Object, 
																			bubbles:Boolean = false, 
																			cancelable:Boolean = false) {
			dango_type = type;
			receive_object = receive_object_orig;
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event {
			return(new DangoURLLoaderEvent(dango_type, receive_object));
		}
	}
}

