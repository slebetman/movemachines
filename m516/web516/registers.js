if (typeof require != 'undefined') var hex = require('hex');

function Registers (size) {
	var dummy = {
		read : function () {return 0x0000},
		write : function (val) {},
	};
	
	for (var i=0;i<=size;i++) {
		this[i] = Object.create(dummy); // initialize registers to dummy
		this[i].name = {};
		this[i].name.read = 'unused';
		this[i].name.write = 'unused';
	}
	
	this.address = {};
}
Registers.prototype = [];

Registers.prototype.define = function (addr, type, name, fn) {
	this.address[name] = addr;
	this[addr][type] = fn;
	this[addr].name[type] = name;
}

Registers.prototype.R = function (addr, name, fn) {
	this.define(addr,'read',name,fn);
}

Registers.prototype.W = function (addr, name, fn) {
	let cb = (val) => {
		fn(val);
		if (this.onchange) {
			this.onchange(addr, name, val);
		}
	}
	this.define(addr,'write',name,cb);
}

Registers.prototype.plain = function (addr, name) {
	var r = this;
	this[name] = 0;
	this.R(addr,name,function(){return r[name]});
	this.W(addr,name,function(v){r[name] = v});
}

Registers.prototype.dump = function (from, to) {
	for (var i=from;i<=to;i++) {
		if (this[i].name.write != this[i].name.read) {
			console.log(hex(i,2) + ': ' + this[i].name.write + ' / ' + this[i].name.read);
		}
		else {
			console.log(hex(i,2) + ': ' + this[i].name.write);
		}
	}
}

if (typeof module != 'undefined' && module.exports) module.exports = Registers;