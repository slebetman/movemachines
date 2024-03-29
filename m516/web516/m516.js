function makeCell (index, value) {
    let v = make('input',{
        id: `_${index}`,
        className: 'cell',
        value: formatCell(value),
        onchange: (e) => {
		    let inst = e.target.value.match(/\S+/g);
		    let val;
		    if (inst.length == 1) {
			    val = parseInt(inst[0],16);
			    if (isNaN(val)) val = 0;
		    }
		    else if (inst.length == 2) {
			    val = asm(inst[0],inst[1]);
		    }
		    else if (inst.length == 3 && inst[1] == 'lit') {
			    val = asmlit(inst[0],inst[2]);
		    }
		    else if (inst.length == 4) {
			    val = asmpack(inst[0],inst[1],inst[2],inst[3]);
		    }
		    else {
			    val = 0;
		    }
		    e.target.value = formatCell(val);
		    updateMem(index);
	    }
    });
	let c = make('div',{
        innerHTML: `${index.toString(16).padStart(4,'0')}: `
    });
	c.appendChild(v);
	return c;
}

function setCell (index, value) {
	let cell = get(`_${index}`);
	if (cell) {
		cell.value = formatCell(value);
	}
}

function getCell (index) {
	let cell = get(`_${index}`);
	if (cell) {
		return parseInt(cell.value, 16);
	}
	return 0;
}

function showCell (index) {
	let all = Array.from(document.getElementsByClassName('cell'));
	all.forEach(x => x.style.backgroundColor = '');
	let c = get(`_${index}`);
	c.style.backgroundColor = 'yellow';
	if (c.scrollIntoViewIfNeeded) {
		c.scrollIntoViewIfNeeded();
	}
	else {
		c.scrollIntoView();
	}
}

let ram = get('ram');

for (let i=0; i<=0x7ff; i++) {
	ram.appendChild(makeCell(i, 0));
}

let runInterval;

function step () {
	get('step').innerText = 'Step [↓]';
	if (runInterval) {
		clearInterval(runInterval);
		runInterval = null;
	}
	exec();
	updatePC();
}

let speedupOptions = [
    1,
    109,
    601,
    14741,
    47629,
    115249,
];

let SPEEDUP = 14741;

for (let s of speedupOptions) {
    let o = make('option',{
        value: s,
        innerText: s
    });
    if (s === SPEEDUP) {
        o.selected = true;
    }
    get('speedup').appendChild(o);
}

get('speedup').onchange = (e) => {
    SPEEDUP = parseInt(e.target.value);
}

function run () {
	get('step').innerText = 'Pause [↓]';
	if (!runInterval) {
		runInterval = setInterval(() => {
			for (let i=0; i<SPEEDUP; i++) {
				exec()
			}
			updatePC();
		},0);
	}
}

function stop () {
	get('step').innerText = 'Step [↓]';
	if (runInterval) {
		clearInterval(runInterval);
		runInterval = null;
	}
	PC = 0;
	updatePC();
}

get('step').onclick = step;
get('run').onclick =  run;
get('stop').onclick = stop;

get('device-manager-btn').onclick = () => deviceManager();

document.body.onkeyup = (e) => {
	switch (e.key) {
		case 'ArrowLeft': stop(); break;
		case 'ArrowRight': run(); break;
		case 'ArrowDown': step(); break;
	}
}

showCell(0);

setInterval(() => {
	if (runInterval) {
		let hz = instCount;
		let speedHz;
		if (hz < 1000) {
			speedHz = `${hz} Hz`;
		} else if (hz < 1000000) {
			speedHz = `${(hz/1000).toFixed(3)} kHz`;
		} else {
			speedHz = `${(hz/1000000).toFixed(3)} MHz`;
		}
		get('mhz').innerText = speedHz;
		instCount = 0;
	}
	else {
		get('mhz').innerText = '0.00 Hz';
	}
}, 1000);
