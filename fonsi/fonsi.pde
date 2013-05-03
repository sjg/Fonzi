import org.json.JSONObject;
import org.json.JSONException;
import intel.pcsdk.*;
import muthesius.net.*;
import org.webbitserver.*;

import jcifs.util.Base64;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import javax.imageio.ImageIO;

int wsPort = 8888;
WebSocketP5 ws;

PXCUPipeline session;
PImage rgbTexture, blobTexture;
PGraphics blobGraphic;
ArrayList<PVector> fingerTips = new ArrayList<PVector>();
ArrayList<PVector> handPoints = new ArrayList<PVector>();

int[] handLabels = {PXCMGesture.GeoNode.LABEL_BODY_HAND_PRIMARY,
                    PXCMGesture.GeoNode.LABEL_BODY_HAND_SECONDARY};
int[] fingerLabels = {PXCMGesture.GeoNode.LABEL_FINGER_THUMB,
                      PXCMGesture.GeoNode.LABEL_FINGER_INDEX,
                      PXCMGesture.GeoNode.LABEL_FINGER_MIDDLE,
                      PXCMGesture.GeoNode.LABEL_FINGER_RING,
                      PXCMGesture.GeoNode.LABEL_FINGER_PINKY};

void setup(){
  size(640,240);
  session = new PXCUPipeline(this);
  
  session.Init(PXCUPipeline.COLOR_VGA|PXCUPipeline.GESTURE);
  
  rgbTexture = createImage(640,480,RGB);
  blobTexture = createImage(320,240, RGB);
  
  ws = new WebSocketP5(this, wsPort);
}

void draw(){
  if(session.AcquireFrame(false)){
    fingerTips.clear();
    handPoints.clear();
    session.QueryRGB(rgbTexture);
    
    session.QueryLabelMapAsImage(blobTexture);
       
    for(int hand=0; hand<handLabels.length;++hand){
       for(int finger=0; finger<fingerLabels.length; ++finger){
         PXCMGesture.GeoNode node = new PXCMGesture.GeoNode();
         if(session.QueryGeoNode(handLabels[hand] | fingerLabels[finger], node)){
            fingerTips.add(new PVector(node.positionImage.x, node.positionImage.y)); 
         }
       } 
       
       PXCMGesture.GeoNode node = new PXCMGesture.GeoNode();
       if(session.QueryGeoNode(handLabels[hand], node)){
            handPoints.add(new PVector(node.positionImage.x, node.positionImage.y)); 
       }
       
      PXCMGesture.Gesture wave = new PXCMGesture.Gesture();
      if (session.QueryGesture(PXCMGesture.GeoNode.LABEL_BODY_HAND_PRIMARY, wave))
      {
        if (wave.active)
        {
          if (wave.label == PXCMGesture.Gesture.LABEL_HAND_WAVE)
          {
            println("waved");
          }
          else if (wave.label == PXCMGesture.Gesture.LABEL_HAND_CIRCLE)
          {
            println("circle");
          }
          else if (wave.label == PXCMGesture.Gesture.LABEL_POSE_THUMB_UP)
          {
            println("Thumbs up");
            ws.broadcast("{\"thumbs-up\": 1}");
          }
          else if (wave.label == PXCMGesture.Gesture.LABEL_POSE_PEACE)
          {
            println("Peace");
          }
          else if (wave.label == PXCMGesture.Gesture.LABEL_NAV_SWIPE_LEFT)
          {
            println("Swipe left");
            ws.broadcast("{\"swipe-left\": 1}");
          }
          else if (wave.label == PXCMGesture.Gesture.LABEL_NAV_SWIPE_RIGHT)
          {
            println("Swipe right");
            ws.broadcast("{\"swipe-right\": 1}");
          }
          else
          {
            println("Didn't get gesture!");
          }
        }
      }
       
    }
    session.ReleaseFrame();
  }
  
  image(rgbTexture,320,0,320,240);
  image(blobTexture, 0, 0);
  
  for(int finger = 0; finger<fingerTips.size(); ++finger){
    PVector fingerTip = (PVector)fingerTips.get(finger);
    fill(#ffff00);
    ellipse(fingerTip.x, fingerTip.y, 5, 5);
  }  
  
  for(int hands = 0; hands<handPoints.size(); ++hands){
    PVector handPos = (PVector)handPoints.get(hands);
    fill(#ff0000);
    ellipse(handPos.x, handPos.y, 5, 5);
  }
  
  encodeTexture(rgbTexture, "rgb");
  encodeTexture(blobTexture, "blob");

}

void stop() {
  ws.stop();
  super.stop();
}

void websocketOnOpen(WebSocketConnection c) {
  println("Client connected");
}

void websocketOnClosed(WebSocketConnection c) {
  println("Client gone");
}

byte[] int2byte(int[]src) {
        int srcLength = src.length;
        byte[]dst = new byte[srcLength << 2];
   
        for (int i=0; i<srcLength; i++) {
                int x = src[i];
                int j = i << 2;
                dst[j++] = (byte) (( x >>> 0 ) & 0xff);          
                dst[j++] = (byte) (( x >>> 8 ) & 0xff);
                dst[j++] = (byte) (( x >>> 16 ) & 0xff);
                dst[j++] = (byte) (( x >>> 24 ) & 0xff);
        }
        return dst;
}

void encodeTexture(PImage img, String keyName){
        BufferedImage buffimg = new BufferedImage( img.width, img.height, BufferedImage.TYPE_INT_RGB);
        
        buffimg.setRGB( 0, 0, img.width, img.height, img.pixels, 0, img.width );
 
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try {
          ImageIO.write( buffimg, "jpg", baos );
        } catch( IOException ioe ) {
       
        }
        
        String b64image = Base64.encode( baos.toByteArray() );
        try{
            String imageJSON = new JSONObject().put( keyName +"_image", b64image).toString();
            ws.broadcast(imageJSON);
        }catch (JSONException joe){
        
        }
        
     
      
}
