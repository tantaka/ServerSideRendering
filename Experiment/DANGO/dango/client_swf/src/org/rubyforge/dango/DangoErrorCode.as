package org.rubyforge.dango {
	public class DangoErrorCode {
		public static var CloseError:uint = 1;		// 接続が切れたときのエラーコード
		public static var SecurityError:uint = 2; // セキュリティエラー(crossdomainとか)のエラーコード
		public static var IOError:uint = 3; 			// IOの失敗時のエラーコード
	}
}
