function popupWindow (title, width, height, content) {
	let w = window.open('',title,`toolbar=no,location=no,menubar=no,status=no,width=${width},height=${height}`);
	let elementCache = {};

	w.get = (id) => {
		if (!elementCache[id]) {
			elementCache[id] = w.document.getElementById(id);
		}
		return elementCache[id];
	}

	w.make = (type, prop) => {
		let e = w.document.createElement(type);
	
		if (prop) {
			for (let p in prop) {
				e[p] = prop[p];
			}
		}
	
		return e;
	}

	if (content) {
		w.document.body.innerHTML = content;
	}

	return w;
}

let toolWindows = {}

function toolWindow (title, width, height, content, init) {
	if (!toolWindows[title]) {
		let w = popupWindow(title, width, height, content);

		if (init) {
			init(w);
		}

		w.onunload = () => {
			if (w.cleanup) {
				w.cleanup();
			}
			delete toolWindows[title];
		}

		toolWindows[title] = w;
	}

	return toolWindows[title];
}

