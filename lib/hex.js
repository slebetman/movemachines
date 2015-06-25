function hex (n,digits) {
	if (!digits) digits = 4;
	return ('0000' + n.toString(16)).substr(-digits);
}
hex.format = function (digits) {
	return function (n) {
		return hex(n,digits);
	}
};

if (typeof module != 'undefined' && module.exports) module.exports = hex;
