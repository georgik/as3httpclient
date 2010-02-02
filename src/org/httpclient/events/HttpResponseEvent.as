package org.httpclient.events {
  
  import flash.events.Event;
  
  import org.httpclient.HTTPResponse;
  
  public class HttpResponseEvent extends Event {
    
    public static const COMPLETE:String = "responseComplete";
    
    private var _response:HTTPResponse;
    
    public function HttpResponseEvent(response:HTTPResponse, type:String = COMPLETE, bubbles:Boolean = false, cancelable:Boolean = false):void {
      super(type, bubbles, cancelable);
      _response = response;
    }
    
    public function get response():HTTPResponse {
      return _response;
    }
    
  }
}