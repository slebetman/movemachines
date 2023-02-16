function parseRAM (txt) {
	let lines = txt.split('\n');

	let data = {};

	for (let line of lines) {
		line = line.replace(/;.*$/,'');
		let cmd = line.match(/\S+/g);
		if (cmd && cmd.length == 2) {
			data[cmd[0]] = parseInt(cmd[1], 16);
		}
	}

	return data;
}

function loadRAM (data) {
	for (let idx in data) {
		setCell(idx, data[idx]);
		updateMem(idx);
	}
}

get('load-ram').onchange = (e) => {
	let file = e.target.files[0];

	let reader = new FileReader();

	reader.readAsText(file);

	reader.onload = function() {
		let instructions = parseRAM(reader.result);
		loadRAM(instructions);
	};

	reader.onerror = function() {
		alert(reader.error);
	};
}