function get (el) {
	if (typeof el == 'string') return document.getElementById(el);
	return el;
}

function all (q) {
	return document.querySelectorAll(q);
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

	var ram = [];
	var size = 1024 * 4;
	for (var x=0; x < size; x++) {
		 ram.push('<div class="ram">' + hexify(x) + ' : 0000 </div>');
	}
	list.innerHTML = ram.join('');
}

highlightRAM = (function(){
	var current = 0;
	
	return function (addr) {
		var list = get('memory');
		all('#memory div')[current].style.backgroundColor = '';
		current = addr;
		
		var el = all('#memory div')[current];
		el.style.backgroundColor = 'cyan';
		
		var y = el.offsetTop;
		var viewY = list.scrollTop + list.offsetTop;
		var h = list.offsetHeight;
		
		if (viewY > y || (viewY + h) < (y + el.offsetHeight)) {
			list.scrollTop = y - (h/2) - list.offsetTop;
		}
	}
})();

window.onload = function () {
	memList();
}
