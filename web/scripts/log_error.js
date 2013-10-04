(function () {
  'use strict';

  if (window.top == window.self) {
    var first_time = true;
    window.onerror = function (message, url, line) {
      var log = localStorage['log'] || '';
      if (first_time) {
        log += '\n-------------------------------\n';
        first_time = false;
      }
      log += url + ':' + line + '\t' + message + '\n';
      localStorage['log'] = log;
    };
  } else {
    window.onerror = function (message, url, line) {
      window.top.postMessage(JSON.stringify({
        action: 'error.log',
        reqid: Math.random().toString(),
        value: {
          message: message,
          url: url,
          line: line
        }
      }), "*");
    };
  }
})();
