// -----------------------------------------------------------------------
// Serial Terminal
// ---------------
//
// The UART interface uses 3 registers mapped to 3 memory addresses:
// - STATUS
// - TX
// - RX
//
// The status register:
//  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// |_ _ _ _:_ _ _ _|_ _ _ _:_ _ _ _|
//                |               |
//                |               '---- TXF (1 when busy, 0 when ready)
//                '-------------------- RXF (1 when data is available)
//
// When TX is written to TXF will be set to 1 until done transmitting
// When RX is read from RXF is cleared
//
// The STATUS register can also be used to configure interrupts in
// the future.
//
// Note that for both RX and TX only the lower 8 bits are used.
// -----------------------------------------------------------------------

let serialTerminal = (() => {
	let RXDATA = 0;
	let TXDATA = 0;
	let STATUS = 0;

	let KEY_VALUE = {
		Backspace: 8,
		Enter: 10,
		Delete: 127,
		Tab: 9,
		Escape: 27,
	}

	function getRXF () {
		return (STATUS & 0x0100) >> 8;
	}

	function setRXF () {
		STATUS |= 0x0100;
	}

	function clearRXF () {
		STATUS &= 0xfeff;
	}

	function getTXF () {
		return STATUS & 0x0001;
	}

	function setTXF () {
		STATUS |= 0x0001;
	}

	function clearTXF () {
		STATUS &= 0xfffe;
	}

	return (addr) => {
		let interface = {};

		// Stop if something else is already installed!
		if (memDevices[addr]) return;
		if (memDevices[addr+1]) return;
		if (memDevices[addr+2]) return;

		function readSTATUS () {
			return STATUS;
		}

		function writeSTATUS (val) {
			val = (val & 0xfefe) | (STATUS & 0x0101); // TXF and RXF are read-only
			STATUS = val;
		}

		function readRXDATA () {
			clearRXF();
			return RXDATA;
		}

		function writeTXDATA (val) {
			TXDATA = val;
			setTXF();
			sendByte();
		}

		function sendByte () {
			let con = get('con');
			let txt = con.value;

			switch (TXDATA) {
				case 8: { // backspace
					let before = txt.substring(0,con.selectionStart-1);
					let after = txt.substring(con.selectionEnd, txt.length);
					txt = before + after;

					con.selectionStart = before.length;
					con.selectionEnd = con.selectionStart;
					break;
				}

				default: {
					let before = txt.substring(0,con.selectionStart);
					let after = txt.substring(con.selectionEnd, txt.length);
					txt = before + String.fromCharCode(TXDATA) + after;

					con.selectionStart = before.length + 1;
					con.selectionEnd = con.selectionStart;
				}
			}

			con.value = txt;
			con.scrollTop = con.scrollHeight;

			if (Math.random() > 0.9) {
				setTimeout(clearTXF, 0);
			}
			else {
				clearTXF();
			}
		}

		toolWindow('Serial Terminal', 400, 200,`
			<style>
				#con {
					flex: 1;
					width: 100%;
					height: 180px;
					margin: 0;
					padding: 5px;
					overflow-y: auto;
					white-space: pre-wrap;
					background-color: #333;
					color: #cfc;
				}
			</style>
			<textarea id="con"></textarea>
		`,
		(w) => {
			let con = get('con');
			con.focus();

			con.onkeydown = (e) => {
				e.stopPropagation();
				e.preventDefault();

				let input = e.key;

				if (input.length === 1) {
					RXDATA = input.charCodeAt(0);
					setRXF();
				}
				else if (KEY_VALUE[input]) {
					RXDATA = KEY_VALUE[input];
					setRXF();
				}
				else {
					console.log(input);
				}
			}

			attachMemDevice(addr, readSTATUS, writeSTATUS);
			attachMemDevice(addr+1, () => {return TXDATA}, writeTXDATA);
			attachMemDevice(addr+2, readRXDATA, () => {});

			w.cleanup = () => {
				removeMemDevice(addr);
				removeMemDevice(addr+1);
				removeMemDevice(addr+2);

				if (interface.cleanup) {
					interface.cleanup();
				}
			}

			interface.close = w.close;
			interface.read = readRXDATA;
			interface.write = writeTXDATA;
		});

		return interface;
	}
})();