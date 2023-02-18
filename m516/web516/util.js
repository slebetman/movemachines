let eCache = {};

function make (type, prop) {
    let e = document.createElement(type);

    if (prop) {
        for (let p in prop) {
            if (p === 'style') {
                let propStyle = prop[p];
                for (let s in propStyle) {
                    e.style[s] = propStyle[s];
                }
            }
            else {
                e[p] = prop[p];
            }
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
