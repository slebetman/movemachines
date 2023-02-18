// -----------------------------------------------
// Interface:
// Each segment of the 7 segment digit is wired
// directly to a bit. The advantage is you have
// full control of what to write to the display.
// The following is how the 7 segments are wired:

//     0
//   1   2
//     3
//   4   5
//     6

// The 7th bit is mapped to the dot.
// But this means you need a font table to write
// numbers. The following is the font table for
// a 7 segment digit:
// 	0	0x77
// 	1	0x24
// 	2	0x5d
// 	3	0x6d
// 	4	0x2e
// 	5	0x6b
// 	6	0x7b
// 	7	0x25
// 	8	0x7f
// 	9	0x2f
// 	A	0x3f
// 	b	0x7a
// 	C	0x53
// 	d	0x7c
// 	E	0x5b
// 	F	0x1b
// -----------------------------------------------

let led7ON = '#000';
let led7OFF = '#ddd';

function LED7draw (id) {
	return `
	<svg
		width="34"
		height="64"
		viewBox="0 0 34 64"
		id="led7seg-${id}"
		class="led7seg"
	>
		<path
			class="segment" style="stroke: ${led7OFF};"
			d="M 8.2645,3.2645 H 26.298174"
			id="led7seg-${id}-0" />
		<path
			class="segment" style="stroke: ${led7OFF};"
			d="m 31.2645,26.2645 v -18"
			id="led7seg-${id}-2" />
		<path
			class="segment" style="stroke: ${led7OFF};"
			d="m 3.2645,26.2645 v -18"
			id="led7seg-${id}-1" />
		<path
			class="segment" style="stroke: ${led7OFF};"
			d="m 31.2645,56.2645 v -18"
			id="led7seg-${id}-5" />
		<path
			class="segment" style="stroke: ${led7OFF};"
			d="m 3.2645,56.2645 v -18"
			id="led7seg-${id}-4" />
		<path
			class="segment" style="stroke: ${led7OFF};"
			d="M 8.2645,32.264499 H 26.399955"
			id="led7seg-${id}-3" />
		<path
			class="segment" style="stroke: ${led7OFF};"
			d="M 8.2645,61.264501 H 26.399955"
			id="led7seg-${id}-6" />
	</svg>
	`
}

function led7seg (addr) {
	let interface = {}

	toolWindow('7 Segment LED', 210, 90, `
		<style>
			svg.led7seg path.segment {
				fill:none;
				stroke-width: 6px;
				stroke-linecap:round;
				stroke-miterlimit:10;
				stroke-dasharray:none;
			}

			svg.led7seg {
				display: inline-block;
				margin: 5px;
			}
		</style>
		<div id="led7seg">
			${LED7draw(3)}
			${LED7draw(2)}
			${LED7draw(1)}
			${LED7draw(0)}
		</div>
	`,
	(w) => {
		function led7write (id, val) {
			for (let i=0; i<7; i++) {
				let s = w.get(`led7seg-${id}-${i}`);
				
				if (val & (1 << i)) {
					s.style.stroke = led7ON;
				}
				else {
					s.style.stroke = led7OFF;
				}
			}
		}

		let cache = [0,0,0,0];
		let updated = [false, false, false, false];
		
		for (let i=0; i<4; i++) {
			attachMemDevice(addr+i,
				null,
				(val) => {
					if (val != cache[i]) {
						cache[i] = val;
						updated[i] = true;
					}
				},
				() => {
					if (updated[i]) {
						led7write(i, cache[i]);
						updated[i] = false;
					}
				}
			);
		}

		w.cleanup = () => {
			for (let i=0; i<4; i++) {
				removeMemDevice(addr+i);
			}	
		}

		interface.write = led7write;
	})

	return interface;
}

