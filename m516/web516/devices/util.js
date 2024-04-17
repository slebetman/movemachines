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
	let x = Math.floor(windowWidth/2);
	let y = Math.floor(windowHeight/2);

	if (typeof width === 'number') {
		width = `${width}px`;
	}
	if (typeof height === 'number') {
		height = `${height + 18}px`;
	}

	const dragAndDrop = (e) => {
		let origin = {
			x: x,
			y: y,
			clientX: e.clientX,
			clientY: e.clientY,
		}

		if (main.nextElementSibling) {
			document.body.appendChild(main);
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

	let main = make.div({
		className: 'dialog',
		style: {
			width,
			height,
			top: `${y}px`,
			left: `${x}px`,
		},
		close: () => {
			console.log('close!');
			if (main.isConnected) {
				document.body.removeChild(main);
				if (main.onunload) {
					main.onunload();
				}
			}
		}
	},
	[
		make.div({
			className: 'dialog-title',
			onpointerdown: dragAndDrop
		},[
			make('span',{},title),
			make('btn', {
				className: 'dialog-close',
				onpointerdown: (e) => {
					main.close();
					e.stopPropagation();
					e.preventDefault();
				}
			},'×')
		]),
		make.div({
			className: 'dialog-container',
		},content)
	]);

	document.body.appendChild(main);

	return main;
}
