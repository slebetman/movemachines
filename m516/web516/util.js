let eCache = {};

function make (type, prop) {
    let e = document.createElement(type);

    if (prop) {
        for (let p in prop) {
            e[p] = prop[p];
        }
    }

    return e;
}

function get (id) {
	if (!eCache[id]) {
		eCache[id] = document.getElementById(id);
	}
	return eCache[id];
}

function formatCell (value) {
	return `0x${value.toString(16).padStart(4,'0')}`;
}
