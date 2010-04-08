package {
    import flash.display.*;
    import flash.events.*;
    import flash.media.*;
    import flash.net.*;
    public class WebCamRecorder extends Sprite {
        public function WebCamRecorder() {

            var nc:NetConnection = new NetConnection();
            nc.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent):void{
                if(e.info.code != 'NetConnection.Connect.Success') return;

                var cam:Camera = Camera.getCamera();
                cam.setQuality(0, 80);
                cam.setMode(320, 240, 30, true);

                var mic:Microphone = Microphone.getMicrophone();
                mic.rate = 44;

                var ns:NetStream = new NetStream(nc);
                ns.attachCamera(cam);
                ns.attachAudio(mic);
                ns.publish('video', 'record');

                var v:Video = new Video(320, 240);
                v.attachCamera(cam);
                stage.addChild(v);

                stage.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void{
                    ns.close();
                    ns.attachCamera(null);
                    ns.attachAudio(null);
                    v.attachCamera(null);
                    stage.removeChild(v);
                    stage.removeEventListener(MouseEvent.CLICK, arguments.callee);
                });
            });
            nc.connect('rtmp://localhost/TestRed5');
        }
    }
}
