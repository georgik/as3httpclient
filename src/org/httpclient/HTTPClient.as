/**
 * Copyright (c) 2007 Gabriel Handford
 * See LICENSE.txt for full license information.
 */
package org.httpclient {
  
  import com.adobe.net.URI;
  
  import flash.errors.IllegalOperationError;
  import flash.events.Event;
  import flash.events.EventDispatcher;
  import flash.events.IOErrorEvent;
  import flash.events.SecurityErrorEvent;
  
  import org.httpclient.events.HTTPDataEvent;
  import org.httpclient.events.HTTPErrorEvent;
  import org.httpclient.events.HTTPListener;
  import org.httpclient.events.HTTPRequestEvent;
  import org.httpclient.events.HTTPResponseEvent;
  import org.httpclient.events.HTTPStatusEvent;
  import org.httpclient.http.Delete;
  import org.httpclient.http.Get;
  import org.httpclient.http.Head;
  import org.httpclient.http.Post;
  import org.httpclient.http.Put;
  
  //import org.httpclient.http.multipart.Multipart;
  //import org.httpclient.http.multipart.FilePart;
    
  [Event(name=Event.CLOSE, type="flash.events.Event")]  
  
  [Event(name="requestConnect", type="org.httpclient.events.HTTPRequestEvent")]
  [Event(name="responseComplete", type="org.httpclient.events.HTTPResponseEvent")]
  
  [Event(name="httpData", type="org.httpclient.events.HTTPDataEvent")]     
  [Event(name="httpStatus", type="org.httpclient.events.HTTPStatusEvent")]
  [Event(name="requestComplete", type="org.httpclient.events.HTTPRequestEvent")]  
  [Event(name="httpError", type="org.httpclient.events.HTTPErrorEvent")]  
  [Event(name="httpTimeoutError", type="org.httpclient.events.HTTPErrorEvent")]    
  [Event(name="", type="flash.events.IOErrorEvent")]  
  [Event(name="securityError", type="flash.events.SecurityErrorEvent")]  
  
  /**
   * HTTP Client.
   */
  public class HTTPClient extends EventDispatcher {

    private var _socket:HTTPSocket;  
    private var _listener:*;
    private var _timeout:int;
    private var _proxy:URI;
    
    /**
     * Create HTTP client.
     * @param proxy URI
     * @param timeout Default timeout (1 minute)
     */
    public function HTTPClient(proxy:URI = null, timeout:int = 60000) {
      _timeout = timeout;
      _proxy = proxy;
    }
    
    /**
     * Get listener, it will contruct a listener for you if one does not exist.
     * Redirects events to callbacks.
     * You can use this listener, or use the EventDispatcher listener. Your choice.
     *  
     * @return Listener
     */
    public function get listener():HTTPListener {
      if (!_listener) {
        _listener = new HTTPListener();
        _listener.register(this);        
      }
      return _listener;
    }
    
    /**
     * Set the listener.
     * To clear the listener, use client.listener = null;
     * @para listener Listeners to callback on
     */
    public function set listener(listener:HTTPListener):void {
      // Unregister existing listener if one exists
      if (_listener) {
        _listener.unregister(this);
      }
      
      _listener = listener;
      if (_listener)
        _listener.register(this);
    }

    public function set timeout(timeout:int):void { _timeout = timeout; }
    public function get timeout():int { return _timeout; }

    /**
     * Cancel current request by closing the socket.
     */
    public function cancel():void {
      _socket.close();
    }
    
    /**
     * Cancels the current connection and removes any listeners.
     */
    public function close():void {
      cancel();
      this.listener = null;
    }
    
    /**
     * Load a generic request.
     *  
     * @param uri URI
     * @param request HTTP request
     * @param timeout Timeout (in millis)
     * @param listener HTTP listener to handle events, if null, the http client will handle events.
     */
    public function request(uri:URI, request:HTTPRequest, timeout:int = -1, listener:HTTPListener = null):void {
      if (timeout == -1) timeout = _timeout;
      var dispatcher:EventDispatcher = null;
      if (listener != null) dispatcher = listener.register();
      else dispatcher = this;
      _socket = new HTTPSocket(dispatcher, timeout, _proxy);
      _socket.request(uri, request);
    }
    
    /**
     * Upload file to URI. In the Flash/AIR VM, there is no way to determine when packets leave the computer, since
     * the Socket#flush call is not blocking and there is no output progress events to monitor.
     *  
     *  var client:HTTPClient = new HTTPClient();
     *  
     *  client.listener.onComplete = function(e:HTTPResponseEvent):void { ... };
     *  client.listener.onStatus = function(e:HTTPStatusEvent):void { ... };
     * 
     *  var uri:URI = new URI("http://http-test.s3.amazonaws.com/test_put.png");
     *  var testFile:File = new File("app:/test/assets/test.png");
     * 
     *  client.upload(uri, testFile);
     *  
     * @param uri
     * @param file (Should be flash.filesystem.File; Not typed for compatibility with Flash)
     * @param method PUT or POST
     * @param 
     */
    public function upload(uri:URI, file:*, method:String = "PUT"):void {
      var httpRequest:HTTPRequest = null;
      if (method == "PUT") httpRequest = new Put();
      else if (method == "POST") httpRequest = new Post();
      else throw new ArgumentError("Method must be PUT or POST");
            
      //httpRequest.setMultipart(new Multipart([ new FilePart(file) ]));    
      throw new IllegalOperationError("Not supported, comment out the line above");
      request(uri, httpRequest);      
    }
    
    /**
     * Get request.
     * @param uri
     * @param listener Listener (if null, the client is the listener)
     */
    public function fetch(uri:URI, listener:HTTPListener = null):void {
      request(uri, new Get(), -1, listener);
    }
    
    /**
     * Post with form data.
     *  
     *   var variables:Array = [ 
     *    { name: "fname", value: "FirstName1" }, 
     *    { name: "lname", value: "LastName1" } 
     *   ];
     *  
     *   client.postFormData(new URI("http://foo.com/"), variables);
     *  
     * @param uri
     * @param variables
     */
    public function postFormData(uri:URI, variables:Array):void {
      request(uri, new Post(variables));
    }
    
    /**
     * Post with multipart.
     *  
     * @param uri
     * @param multipart
    x
    public function postMultipart(uri:URI, multipart:Multipart):void {
      var post:Post = new Post();
      post.setMultipart(multipart);
      request(uri, post);
    }
    */
	 
    /**
     * Post with raw data.
     *  
     * @param uri
     * @param body
     * @param contentType
     *  
     * The request body can be anything but should respond to:
     *  - readBytes(bytes:ByteArray, offset:uint, length:uint)
     *  - length
     *  - bytesAvailable
     *  - close
     */
    public function post(uri:URI, body:*, contentType:String = null):void {
      var post:Post = new Post();
      post.body = body;
      post.contentType = contentType;
      request(uri, post);
    }
    
    /**
     * Put with raw data.
     *  
     * @param uri
     * @param body
     * @param contentType
     *  
     * The request body can be anything but should respond to:
     *  - readBytes(bytes:ByteArray, offset:uint, length:uint)
     *  - length
     *  - bytesAvailable
     *  - close
     */ 
    public function put(uri:URI, body:*, contentType:String = null):void {
      var put:Put = new Put();
      put.body = body;
      put.contentType = contentType;
      request(uri, put);
    }
    
    /**
     * Put with form data.
     *  
     *   var variables:Array = [ 
     *    { name: "fname", value: "FirstName1" }, 
     *    { name: "lname", value: "LastName1" } 
     *   ];
     *  
     *   client.putFormData(new URI("http://foo.com/"), variables);
     *  
     * @param uri
     * @param variables
     */
    public function putFormData(uri:URI, variables:Array):void {
      var put:Put = new Put();
      put.setFormData(variables);
      request(uri, put);
    }
    
    /**
     * Head.
     * @param uri
     */    
    public function head(uri:URI):void {
      request(uri, new Head());
    }
    
    /**
     * Delete.
     * (Delete is a keyword; which is why this method signature is inconsistent)
     * @param uri
     */
    public function del(uri:URI):void {
      request(uri, new Delete());
    }
  }

}