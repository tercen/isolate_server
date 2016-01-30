library sci_custom_post_message;

import 'dart:js' as js;

void enableWebWorkerArrayBuffer(){
  _enableVisitMessage();
  _enablePostMessage();
}

void _enableVisitMessage() {
  js.context.callMethod("eval", [
    '''
var stdPostMessage = self.postMessage;

function visitMessage(arrayMsg, buffers){
  for (var i = 0 ; i <  arrayMsg.length ; i++){
    var element = arrayMsg[i];
    if (element instanceof ArrayBuffer){
      buffers.push(element);
    } else if (element instanceof Array) {
      visitMessage(element, buffers);
    }
  }
} 
'''
  ]);
}

void _enablePostMessage() {
  js.context.callMethod("eval", [
    ''' 
function postMessage(obj){
  var buffers = [];
  visitMessage(obj, buffers);
  stdPostMessage(obj, buffers);
} 
'''
  ]);
}
