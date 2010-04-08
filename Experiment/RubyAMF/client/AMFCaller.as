package
{
    import flash.utils.getTimer;
    import flash.net.NetConnection;
    import flash.net.Responder;
    import flash.net.ObjectEncoding;
    import flash.net.SharedObject;
    import flash.events.Event;
    import flash.events.NetStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.events.AsyncErrorEvent;
    import flash.events.*;
    import mx.utils.ObjectUtil;
    import flash.text.TextField;
    import flash.display.Sprite;
    //import mx.rpc.Responder;

    public class AMFCaller extends Sprite
    {
        public var textArea:TextField = new TextField();

        public function AMFCaller() {
            textArea.text = "default2";
            textArea.width = 500;
            textArea.height = 500;
            addChild(textArea);

            addEventListener(MouseEvent.CLICK, handleClick);
        }

        /**
        * gateway.phpのURL
        */
        public static const GATEWAY_URL:String = "http://localhost:3000/rubyamf/gateway";

        private var netConnection:NetConnection;

        private function handleClick(e:Event):void
        {
            netConnection = new NetConnection();
            //AMFプロトコルのバージョン
            netConnection.objectEncoding = ObjectEncoding.AMF3;
            netConnection.connect(GATEWAY_URL);

            /**
            * 詳細なステータスを所得するハンドラ
            * 以下３つのハンドラはサンプルにはない。
            * @see http://livedocs.adobe.com/flex/3_jp/langref/index.html
            * NetStatusEvent
            */
            netConnection.addEventListener(NetStatusEvent.NET_STATUS,
                function(e:NetStatusEvent):void
                {
                    _trace(ObjectUtil.toString(e));
                });

            /**
            * @see http://livedocs.adobe.com/flex/3_jp/langref/index.html
            * IOErrorEvent
            */
            netConnection.addEventListener(IOErrorEvent.IO_ERROR,
                function(e:IOErrorEvent):void
                {
                    _trace(ObjectUtil.toString(e));
                });

            /**
            * @see http://livedocs.adobe.com/flex/3_jp/langref/index.html
            * ASYNC_ERROR
            */
            netConnection.addEventListener(AsyncErrorEvent.ASYNC_ERROR,
                function(e:AsyncErrorEvent):void
                {
                    _trace(ObjectUtil.toString(e));
                });

            _trace("before getRemote");
            var so:SharedObject = SharedObject.getRemote("sotest", netConnection.uri, true);
            _trace("after getRemote");
            _trace("so:" + ObjectUtil.toString(so));
            if(so) {
                so.addEventListener( SyncEvent.SYNC ,
                    function( evt:SyncEvent ):void
                    {
                        _trace(ObjectUtil.toString(evt));
                        so.connect(netConnection);
                    });
            }

            /**
            MethodTableに登録したサービスをコール
            書式はサ－ビス名.メソッド名
            */
            netConnection.call("MessagesController.hello",
                new Responder(handleResult, handleFault) , "sup");


        }

        /**
        * 成功
        */
        private function handleResult(e:*):void
        {
            _trace("handleResult:" + ObjectUtil.toString(e));
        }

        /**
        * 失敗
        */
        private function handleFault(e:*):void
        {
            _trace("handleFault:" + ObjectUtil.toString(e));
        }

        private function _trace(msg:String):void
        {
            var _msg:String = '[' + getTimer() + ']' + msg;
            textArea.text = _msg ;
            trace(_msg);
        }
    }
}