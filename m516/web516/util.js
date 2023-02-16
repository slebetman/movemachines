let eCache = {};

function get (id) {
	if (!eCache[id]) {
		eCache[id] = document.getElementById(id);
	}
	return eCache[id];
}

function formatCell (value) {
	return `0x${value.toString(16).padStart(4,'0')}`;
}
