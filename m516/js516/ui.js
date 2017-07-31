function get (el) {
	if (typeof el == 'string') return document.getElementById(el);
	return el;
}

function hexify (n) {
	n = n.toString(16);
	
	while (n.length < 4) {
		n = '0' + n;
	}
	
	return n;
}

function memList (arr) {
	var list = get('memory');

	for (var x=0; x<1024; x++) {
		list.innerHTML += '<div class="ram">' + hexify(x) + ' : 0000 </div>';
	}
}

window.onload = function () {
	memList();
}
