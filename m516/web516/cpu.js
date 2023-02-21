var instCount = 0;
var PC = 0;
var ACU = 0;
var RET = 0;
var A_PTR = 0;
var B_PTR = 0;
var M_PTR = 0;
var CARRY = 0;

var reg = new Registers(0x7f);

let memUpdates = {};

function updateMem (addr) {
	memUpdates[addr] = addr;
}

function runUpdateMem (addr) {
	if (
		addr >= A_PTR-1 &&
		addr <= A_PTR+1
	) {
		get('a').innerText = formatCell(getCell(A_PTR));
		if (A_PTR+1 <= 0x1ff) {
			get('a_plus').innerText = formatCell(getCell(A_PTR+1));
		}
		if (A_PTR-1 >= 0) {
			get('a_minus').innerText = formatCell(getCell(A_PTR-1));
		}
	}

	if (
		addr >= B_PTR-1 &&
		addr <= B_PTR+1
	) {
		get('b').innerText = formatCell(getCell(B_PTR));
		if (B_PTR+1 <= 0x1ff) {
			get('b_plus').innerText = formatCell(getCell(B_PTR+1));
		}
		if (B_PTR-1 >= 0) {
			get('b_minus').innerText = formatCell(getCell(B_PTR-1));
		}
	}

	if (
		addr >= M_PTR &&
		addr < M_PTR+32
	) {
		get(`m${addr-M_PTR}`).innerText = formatCell(getCell(addr));
	}
}

let memDevices = {}

function attachMemDevice (addr, read, write, update) {
	memDevices[addr] = {
		read,
		write,
		update,
	}
}

function removeMemDevice (addr) {
	delete memDevices[addr];
}

function MEM_WRITE (addr, val) {
	if (addr <= 0x1ff) {
		setCell(addr,val);
		updateMem(addr);
	}
	else if (memDevices[addr] && memDevices[addr].write) {
		memDevices[addr].write(val);
	}
}

function MEM_READ (addr) {
	if (addr <= 0x1ff) {
		return getCell(addr);
	}
	else if (memDevices[addr] && memDevices[addr].read) {
		return memDevices[addr].read();
	}
	else {
		return 0;
	}
}

var decode = (function(){
	function copy (dst,src) {
		instCount ++;
		var val = reg[src].read();
		reg[dst].write(val);
	}
	
	function literal (dst,val) {
		instCount ++;
		reg[dst].write(val);
	}
	
	return function (word) {
		var format = (word & 0xc000) >> 14;
		
		if (format == 0) {
			// 16 bit instruction
			copy(word >> 7, word & 0x7f);
		}
		else if (format == 1) {
			// short literal
			literal((word >> 12) & 0x03, word & 0x0fff);
		}
		else {
			// packed instruction
			copy((word >> 12) & 0x07, (word >> 8) & 0x0f),
			copy((word >> 4) & 0x0f, word & 0x0f)
		}
	}
})();

function R (addr, name, fn) {
	reg.R(addr,name,fn);
}

function W (addr, name, fn) {
	reg.W(addr, name, fn);
}

function plainRegister (addr, name) {
	reg.plain(addr,name);
}

// plainRegister(0x00,'acu');
R(0x00,'acu',function(){return ACU});
W(0x00,'acu',function(v){ACU = v});
R(0x01,'one',function(){return 0x0001});
R(0x02,'nil',function(){return 0x0000});
R(0x03,'all',function(){return 0xffff});
W(0x01,'add',function(v){
	ACU += v;
	if (ACU > 0xffff) {
		CARRY = 1;
	}
	else {
		CARRY = 0;
	}
	ACU &= 0xffff;
});
W(0x02,'sub',function(v){
	ACU -= v;
	if (ACU < 0) {
		CARRY = 1;
	}
	else {
		CARRY = 0;
	}
	ACU &= 0xffff;
});
W(0x03,'and',function(v){ACU &= v});
R(0x04,'rsh',function(){return ACU >> 1});
W(0x04,'or',function(v){ACU |= v});
// plainRegister(0x05,'*a');
R(0x05,'*a',function(){return A_PTR});
W(0x05,'*a',function(v){
	A_PTR = v;
	updateMem(A_PTR);
	updateMem(A_PTR-1);
	updateMem(A_PTR+1);
});
R(0x28,'inv',function(){return ACU ^ 0xffff});
W(0x28,'xor',function(v){ACU ^= v});
// plainRegister(0x2c,'*b');
R(0x2c,'*b',function(){return B_PTR});
W(0x2c,'*b',function(v){
	B_PTR = v;
	updateMem(B_PTR);
	updateMem(B_PTR-1);
	updateMem(B_PTR+1);
});
// plainRegister(0x2f,'pc');
R(0x2f,'pc',function(){return PC});
W(0x2f,'pc',function(v){RET = PC; PC = v});
//plainRegister(0x32,'ret');
R(0x32,'ret',function(){return RET});
W(0x32,'ret',function(v){RET = v});
//plainRegister(0x33,'*m');
R(0x33,'*m',function(){return M_PTR});
W(0x33,'*m',function(v){
	M_PTR = v & 0xffe0;
	for (let i=0;i<32;i++) {
		updateMem(M_PTR+i);
	}
});
R(0x06,'a',function(){return MEM_READ(A_PTR)});
W(0x06,'a',function(v){MEM_WRITE(A_PTR,v)});
R(0x07,'a-',function(){
	A_PTR--;
	reg[reg.address['*a']].write(A_PTR);
	updateMem(A_PTR);
	updateMem(A_PTR-1);
	updateMem(A_PTR+1);
	return MEM_READ(A_PTR+1);
});
W(0x07,'+a',function(v){
	A_PTR++;
	MEM_WRITE(A_PTR,v);
	updateMem(A_PTR-1);
	updateMem(A_PTR+1);
});
R(0x29,'a+',function(){
	A_PTR++;
	reg[reg.address['*a']].write(A_PTR);
	updateMem(A_PTR);
	updateMem(A_PTR-1);
	updateMem(A_PTR+1);
	return MEM_READ(A_PTR-1);
});
W(0x29,'-a',function(v){
	A_PTR--;
	MEM_WRITE(A_PTR,v);
	updateMem(A_PTR-1);
	updateMem(A_PTR+1);
});
R(0x2a,'high',function(){
	return (MEM_READ(A_PTR) >> 8) & 0x00ff;
});
W(0x2a,'high',function(v){
	var mval = MEM_READ(A_PTR) & 0x00ff;
	MEM_WRITE(A_PTR, mval | ((v << 8) & 0xff00));
});
R(0x2b,'low',function(){
	return MEM_READ(A_PTR) & 0x00ff;
});
W(0x2b,'low',function(v){
	var mval = MEM_READ(A_PTR) & 0xff00;
	MEM_WRITE(A_PTR, mval | (v & 0x00ff));
});
R(0x2d,'b',function(){return MEM_READ(B_PTR)});
W(0x2d,'b',function(v){MEM_WRITE(B_PTR,v)});
R(0x2e,'b-',function(){
	B_PTR--;
	reg[reg.address['*b']].write(B_PTR);
	updateMem(B_PTR-1);
	updateMem(B_PTR+1);
	return MEM_READ(B_PTR+1);
});
W(0x2e,'+b',function(v){
	B_PTR++;
	MEM_WRITE(B_PTR,v);
	updateMem(B_PTR-1);
	updateMem(B_PTR+1);
});
W(0x30,'pcz',function(v){
	if (ACU == 0) {
		RET = PC; PC = v
	}
});
R(0x30,'lit',function(){
	PC++;
	return MEM_READ(PC-1);
});
W(0x31,'pcc',function(v){
	if (CARRY) {
		RET = PC; PC = v
	}
});
R(0x31,'conf',function(){return 0x0001});

for (var i=0x08,m=0;i<=0x27;i++,m++) {
	R(i,'m'+m,function(offset){
		return function(){
			return MEM_READ(M_PTR+offset);
		};
	}(m));
	W(i,'m'+m,function(offset){
		return function(v){
			MEM_WRITE(M_PTR+offset,v);
		};
	}(m));
}

let regUpdates = {};

function runUpdateRegisters (name) {
	switch (name) {
		case 'acu':
		case 'add':
		case 'sub':
		case 'and':
		case 'or':
		case 'xor':
		case 'high':
		case 'low':
			get('acu').innerText = formatCell(ACU);
			break;

		case '*a':
		case '+a':
		case '-a':
		case 'a+':
		case 'a-':
			get('a_ptr').innerText = formatCell(A_PTR);
			break;

		case '*b':
		case '+b':
		case 'b-':
			get('b_ptr').innerText = formatCell(B_PTR);
			break;

		case 'pc':
		case 'pcz':
		case 'pcc':
			get('pc').innerText = formatCell(PC);
			// fallthrough..
		case 'ret':
			get('ret').innerText = formatCell(RET);
			break;

		case '*m':
			get('m_ptr').innerText = formatCell(M_PTR);
			for (let i=0; i<32; i++) {
				get(`m${i}`).innerText = formatCell(MEM_READ(M_PTR+i));
			}
			break;
	}
}

reg.onchange = (addr, name, val) => {
	regUpdates[name] = true;
}

function updatePC () {
	showCell(PC);
	get('pc').innerText = formatCell(PC);
	let inst = disassemble(MEM_READ(PC));
	if (inst.match(/ lit$/)) {
		inst += ' ' + formatCell(MEM_READ(PC+1));
	}
	get('disassembly').innerText = inst;
	for (let i in memUpdates) {
		runUpdateMem(memUpdates[i]);
	}
	for (let n in regUpdates) {
		runUpdateRegisters(n);
	}
	regUpdates = {};
	memUpdates = {};
	for (let i in memDevices) {
		let dev = memDevices[i];
		if (dev.update) {
			dev.update();
		}
	}
	if (CARRY) {
		get('carry-dot').style.fill = '#333';
	}
	else {
		get('carry-dot').style.fill = 'none';
	}
}

function exec () {
	var instruction = MEM_READ(PC);
	PC ++;
	decode(instruction);
}
