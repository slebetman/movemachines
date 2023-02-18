let toolWindows = {}

function toolWindow (title, width, height, content, init) {
	if (!toolWindows[title]) {
		let w = popupDialog(title, width, height, content);

		if (init) {
			init(w);
		}

		w.onunload = () => {
			if (w.cleanup) {
				w.cleanup();
			}
			delete toolWindows[title];
			eCache = {}
		}

		toolWindows[title] = w;
	}

	return toolWindows[title];
}

function popupDialog (title, width, height, content) {
	let windowWidth = document.body.offsetWidth;
	let windowHeight = document.body.offsetHeight;
	let x = Math.floor(windowWidth/2 - width/2);
	let y = Math.floor(windowHeight/2 - height/2);

	let main = make('div', {
		className: 'dialog',
		style: {
			width: `${width}px`,
			height: `${height + 18}px`,
			top: `${y}px`,
			left: `${x}px`,
		}
	});
	let titleBar = make('div', {
		className: 'dialog-title',
	})
	titleBar.innerHTML = title;
	let closeBtn = make('btn', {
		className: 'dialog-close',
	})
	closeBtn.innerText = '×';
	titleBar.appendChild(closeBtn);
	let container = make('div', {
		className: 'dialog-container',
	})
	if (content) {
		container.innerHTML = content;
	}

	titleBar.onpointerdown = (e) => {
		let origin = {
			x: x,
			y: y,
			clientX: e.clientX,
			clientY: e.clientY,
		}

		window.onpointerup = () => {
			window.onpointermove = undefined;
			window.onpointerup = undefined;
		}

		window.onpointermove = (e) => {
			if (origin) {
				y = origin.y + e.clientY - origin.clientY;
				x = origin.x + e.clientX - origin.clientX;

				main.style.top = `${y}px`;
				main.style.left = `${x}px`;

				e.stopPropagation();
				e.preventDefault();
			}
		}
	}

	closeBtn.onclick = () => {
		document.body.removeChild(main);
		if (main.onunload) {
			main.onunload();
		}
	}

	main.appendChild(titleBar);
	main.appendChild(container);

	document.body.appendChild(main);

	return main;
}
