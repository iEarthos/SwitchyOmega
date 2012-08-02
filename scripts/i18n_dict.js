'use strict';

function i18nDict(data) {
  this.data = data;
}

i18nDict.prototype.getValue = function (name) {
  var data = this.data;
  var result = data[name];
  if (typeof result === 'undefined') {
    console.error('Undefined i18n cache entry: ' + name);
    result = '<unknown>';
  }
  return result;
};

i18nDict.prototype.getString = function (name) {
  return this.getValue(name);
};
