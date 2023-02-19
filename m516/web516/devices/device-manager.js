let deviceManager =(() => {
	let devices = {
		'7 Segment Display': {
			init: () => led7seg(0x0200),
			enabled: false,
			device: null,
		}
	}

	function listDevice (title, prop) {
		let device = make('div',{
			className: 'device-list'
		});
		device.innerHTML = title;

		function close () {
			prop.device.close();
			prop.enabled = false;
			prop.btn.innerText = 'Enable';
			prop.btn.className = 'off';
		}

		prop.btn = make('button',{
			className: prop.enabled ? 'on' : 'off',
			innerText: prop.enabled ? 'Disable' : 'Enable',
			onclick: () => {
				if (prop.enabled) {
					close();
				}
				else {
					prop.device = prop.init();
					prop.device.cleanup = close;
					prop.enabled = true;
					prop.btn.innerText = 'Disable';
					prop.btn.className = 'on';
				}
			}
		});

		device.appendChild(prop.btn);

		return device;
	}

	return function () {
		let interface = {};

		toolWindow('Device Manager', 350, 150, `
			<style>
				#device-manager {
					overflow: auto;
				}
				#device-manager .device-list button {
					float: right;
					margin-right: 5px;
					border-radius: 3px;
					border: 1px solid #777;
				}
				#device-manager button.on {
					background-color: #333;
					color: #fff;
				}
				#device-manager button.off {
					background-color: #fff;
					color: #000;
				}
			</style>
			<div id="device-manager">

			</div>
		`,
		(w) => {
			let container = get('device-manager');

			for (let d in devices) {
				let el = listDevice(d, devices[d]);
				container.appendChild(el);
			}

			w.cleanup = () => {
				if (interface.cleanup) {
					interface.cleanup();
				}
			}
		})

		return interface;
	}
})()