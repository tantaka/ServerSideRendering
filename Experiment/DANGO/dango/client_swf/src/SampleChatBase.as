package {
  import flash.events.*;
  import flash.display.*;
  import mx.utils.ObjectUtil;
  import org.rubyforge.dango.*;

  public class SampleChatBase {
    private var sprite_app:Object;
    private var dango_client:DangoClientFramework;

    //コンストラクタ
    public function SampleChatBase(t:Object) {
      sprite_app = t;    // tは、呼び出し元のFlex自身

      //dangoの接続処理
      var config:DangoConfig = new DangoConfig();    // dangoの設定情報(接続先サーバー情報)を読込
      try {
        dango_client = new DangoClientFramework(config);    // サーバーとの接続
      } catch(err:DangoError) {
        trace("接続エラー:failed to socket initialize.");
      }

      //エラー時のイベントリスナ
      dango_client.addEventListener("dangoError", connection_error);

      //データ受信時のイベントリスナーの追加
      dango_client.addEventListener("dango_notice_message", dango_notice_message);
    }

    //接続エラー
    private function connection_error(evt:DangoErrorEvent):void {
      trace("FrameworkError:code=" + evt.code + ":message=" + evt.message);
    }

    //チャット送信処理
    public function send_message(message:String):void {
      if(message == "") { return; }
      var send_obj:Object = { "message":message };
      try {
        dango_client.send_action("send_message", send_obj);
        trace("送信:" + ObjectUtil.toString(send_obj));
      } catch(err:DangoError) {
        trace("データ送信失敗");
      }
    }

    //データ受信 dango_notice_message
    private function dango_notice_message(evt:DangoReceiveEvent):void {
      trace("dango_notice_message");
      var ret:Object = evt.receive_data;
      sprite_app.add_text_log(ret["message"]);
    }
  }
}