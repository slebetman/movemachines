if (typeof require != 'undefined') var hex = require('hex');
if (typeof require != 'undefined') require('array.stride');

function Memory () {}

Memory.prototype = Object.create(Array.prototype);
Memory.prototype.clear = function () {
	for (var i=0; i<=0xffff; i++) {
		this.set(i,0);
	}
};
Memory.prototype.set = function (i,v) {
	i = i & 0xffff;
	this[i] = v;
	if (i >= this.length) this.length = i+1;
	this.onchange(i,v);
};
Memory.prototype.get = function (i) {
	return this[i];
};
Memory.prototype.onchange = function (i,v) {};

Memory.prototype.load = function (arr) {
	for (var i=0; i<arr.length; i++) {
		this.set(i,arr[i]);
	}
};

Memory.prototype.dump = function (from,to) {
	return this.slice(from,to+1).map(hex.format(4)).stride(function(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p) {
		return [hex(this*16+from) + ':',a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p].join(' ');
	}).join("\n");
}

if (typeof module != 'undefined' && module.exports) module.exports = Memory;
