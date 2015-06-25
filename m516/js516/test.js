#! /usr/bin/env node

var b = require('blessed');

var s = b.screen();

s.title = 'testing 1.. 2.. 3..';

var t1 = b.box({
	content : 'Hello Test',
	top : '0',
	left : '0',
	width : '20%',
	height : '100%-1',
	border : {type: 'line'},
	style : {
		hover : {
			bg : 'white',
			fg : 'black'
		}
	}
});

var t2 = b.text({
	content : 'type "q" to quit',
	top : '100%-1'
});

s.append(t1);
s.append(t2);

t1.on('click', function() {
	t1.setContent(t1.getContent()+'.');
	s.render();
});

t1.focus();

s.key('q', function() {
	process.exit(0);
});

s.render();
