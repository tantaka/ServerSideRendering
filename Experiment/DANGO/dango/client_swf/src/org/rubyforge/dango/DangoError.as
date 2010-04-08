//参考：http://livedocs.adobe.com/flex/2_jp/docs/wwhelp/wwhimpl/js/html/wwhelp.htm?href=Part5_ProgAS.html

package org.rubyforge.dango {
	import flash.events.*;
	
	public class DangoError extends Error {
		public function DangoError(message:String = "", errorID:int = 0) {
			super(message, errorID);
		}
	}
}
