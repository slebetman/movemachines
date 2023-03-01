include 516inc.as
autopack


macro ifStringEnd $STR $GOTO else $ELSE {
	acu deref $STR
	ifFALSE $GOTO else $ELSE
}

macro ifStringEnd $STR $GOTO {
	acu deref $STR
	ifFALSE $GOTO
}

macro ifLowEnd $STR $GOTO else $ELSE {
	*a $STR
	*a a
	acu low
	ifFALSE $GOTO else $ELSE
}

macro ifLowEnd $STR $GOTO {
	*a $STR
	*a a
	acu low
	ifFALSE $GOTO
}

macro ifHighEnd $STR $GOTO else $ELSE {
	*a $STR
	*a a
	acu high
	ifFALSE $GOTO else $ELSE
}

macro ifHighEnd $STR $GOTO {
	*a $STR
	*a a
	acu high
	ifFALSE $GOTO
}

macro strlen_rearrange_stack {
	// [str_addr] => acu

	// stack is: *a, ret, str

	+b nil // string length

	// stack is: len, *a, ret, str
	acu *b
	sub lit 2
	*a acu
	swap_reg a b

	// stack is: ret, *a, len, str
	acu *b
	sub lit 3
	*a acu
	swap_reg a b

	// stack is: str, *a, len, ret
	acu *b
	sub lit 2
	*a acu     // a is now pointing to len
}

macro bytestrlen $STR {
	if undefined BYTE_STR_LEN_IMPLEMENTATION
	define BYTE_STR_LEN_IMPLEMENTATION 1
	goto $$START

	// [str_addr] => acu
	routine BYTE_STR_LEN {
		+b *a // save *a

		strlen_rearrange_stack

		// stack is: str, *a, len, ret
		//            b        a
		
	:$$LOOP
		// Check if end of str
		ifLowEnd b $$END
		incr_reg a

		ifHighEnd b $$END
		incr_reg a

		incr_reg b

		goto $$LOOP

	:$$END
		acu b-
		*a b-  // restore *a
		acu b- // pop len into acu

		return
	}

	:$$START
	end undefined

	acu $STR
	call BYTE_STR_LEN
}

macro strlen $STR {
	if undefined STR_LEN_IMPLEMENTATION
	define STR_LEN_IMPLEMENTATION 1
	goto $$START

	// [str_addr] => acu
	routine STR_LEN {
		+b *a // save *a

		strlen_rearrange_stack

		// stack is: str, *a, len, ret
		//            b        a
		
	:$$LOOP
		// Check if end of str
		ifStringEnd b $$END

		incr_reg a
		incr_reg b

		goto $$LOOP

	:$$END
		acu b-
		*a b-  // restore *a
		acu b- // pop len into acu

		return
	}

	:$$START
	end undefined

	acu $STR
	call STR_LEN
}

macro strequal_rearrange_stack {
	// Let's re-arrange the stack so we can simply return later
	// stack is: *a, ret, str1, str2
	acu *b
	sub lit 3
	*a acu
	decr_reg *b
	swap_reg a b
	incr_reg *b
	// stack is: *a, str2, str1, ret
}

macro bytestrequal $STR1 $STR2 {
	if undefined BYTE_STR_EQ_IMPLEMENTATION
	define BYTE_STR_EQ_IMPLEMENTATION 1
	goto $$START

	// (str1_addr, str2_addr) => acu
	routine BYTE_STR_EQ {
		+b *a // save *a and restore later

		strequal_rearrange_stack

		// stack is: *a, str2, str1, ret

	:$$LOOP
		// Compare char 2 bytes at a time
		acu *b        // get value at str2
		sub one
		+b deref acu  // save value of str2 to stack
		acu *b        // get value at str1
		sub lit 3
		acu deref acu
		sub b-        // pop value of str2 and compare
		ifTRUE $$END_FALSE

		// If we are here it means the string matches up to this point
		// Now we need to find out if both string ends, if not we need to loop

		// Check if high byte is string end. Don't need to check
		// both strings because they match.
		ifHighEnd b $$END_TRUE

		// Increment str2
		acu *b
		sub one
		incr acu
		// Increment str1
		acu *b
		sub lit 2
		incr acu

		// Check if end of str2
		acu *b
		sub one
		ifLowEnd acu $$STR2_END

		// Check if end of str1
		acu *b
		sub lit 2
		// if str1 end here it means str2 is not end so obviously no match
		ifLowEnd acu $$END_FALSE

		// Note: We don't need to check if high end because that is
		//       already handled above.

		// Not end of either strings so we should loop
		goto $$LOOP

	// If both buffer and string end then they are the same
	:$$STR2_END
		// Check if end of str1
		acu *b
		sub lit 2
		ifLowEnd acu $$END_TRUE else $$END_FALSE

	// stack is: *a, str2, str1, ret

	:$$END_TRUE
		*a b- // restore *a
		acu b-
		acu b-
		acu one
		return
	:$$END_FALSE
		*a b- // restore *a
		acu b-
		acu b-
		acu nil
		return
	}

	:$$START
	end undefined

	+b $STR1
	+b $STR2
	call BYTE_STR_EQ
}

macro strequal $STR1 $STR2 {
	if undefined STR_EQ_IMPLEMENTATION
	define STR_EQ_IMPLEMENTATION 1
	goto $$START

	// (str1_addr, str2_addr) => acu
	routine STR_EQ {
		+b *a // save *a and restore later

		strequal_rearrange_stack
		
		// stack is: *a, str2, str1, ret

	:$$LOOP
		// Compare char
		acu *b        // get value at str2
		sub one
		+b deref acu  // save value of str2 to stack
		acu *b        // get value at str1
		sub lit 3
		acu deref acu
		sub b-        // pop value of str2 and compare
		ifTRUE $$END_FALSE

		// Increment str2
		acu *b
		sub one
		incr acu
		// Increment str1
		acu *b
		sub lit 2
		incr acu

		// If we are here it means the string matches up to this point
		// Now we need to find out if both string ends, if not we need to loop

		// Check if end of str2
		acu *b
		sub one
		ifStringEnd acu $$STR2_END

		// Check if end of str1
		acu *b
		sub lit 2
		// if str1 end here it means str2 is not end so obviously no match
		ifStringEnd acu $$END_FALSE

		// Not end of either strings so we should loop
		goto $$LOOP

	// If both buffer and string end then they are the same
	:$$STR2_END
		// Check if end of str1
		acu *b
		sub lit 2
		ifStringEnd acu $$END_TRUE else $$END_FALSE

	// stack is: *a, str2, str1, ret

	:$$END_TRUE
		*a b- // restore *a
		acu b-
		acu b-
		acu one
		return
	:$$END_FALSE
		*a b- // restore *a
		acu b-
		acu b-
		acu nil
		return
	}

	:$$START
	end undefined

	+b $STR1
	+b $STR2
	call STR_EQ
}

macro bytestrstart $NEEDLE $HAYSTACK {
	if undefined BYTE_STR_START_IMPLEMENTATION
	define BYTE_STR_START_IMPLEMENTATION 1
	goto $$START

	// (NEEDLE_addr, HAYSTACK_addr) => acu
	routine BYTE_STR_START {
		+b *a // save *a and restore later

		strequal_rearrange_stack
		
		// stack is: *a, HAYSTACK, NEEDLE, ret

	:$$LOOP
		// Compare char 2 bytes at a time
		acu *b        // get value at HAYSTACK
		sub one
		+b deref acu  // save value of HAYSTACK to stack
		acu *b        // get value at NEEDLE
		sub lit 3
		acu deref acu
		sub b-        // pop value of HAYSTACK and compare
		ifTRUE $$END_FALSE

		// If we are here it means the string matches up to this point
		// Now we need to find out if both string ends, if not we need to loop

		// Check if end of NEEDLE
		acu *b
		sub lit 2
		if ifHighEnd acu $$END_TRUE

		// Increment HAYSTACK
		acu *b
		sub one
		incr acu
		// Increment NEEDLE
		acu *b
		sub lit 2
		incr acu

		// Check if end of NEEDLE
		acu *b
		sub lit 2
		// if NEEDLE end here it means HAYSTACK starts with NEEDLE
		ifLowEnd acu $$END_TRUE

		// Check if end of HAYSTACK
		acu *b
		sub one
		// if HAYSTACK end here it means HAYSTACK is shorter than NEEDLE
		ifLowEnd acu $$END_FALSE

		// Not end of either strings so we should loop
		goto $$LOOP


	// stack is: *a, HAYSTACK, NEEDLE, ret

	:$$END_TRUE
		*a b- // restore *a
		acu b-
		acu b-
		acu one
		return
	:$$END_FALSE
		*a b- // restore *a
		acu b-
		acu b-
		acu nil
		return
	}

	:$$START
	end undefined

	+b $NEEDLE
	+b $HAYSTACK
	call BYTE_STR_START
}

macro strstart $NEEDLE $HAYSTACK {
	if undefined STR_START_IMPLEMENTATION
	define STR_START_IMPLEMENTATION 1
	goto $$START

	// (NEEDLE_addr, HAYSTACK_addr) => acu
	routine STR_START {
		+b *a // save *a and restore later

		strequal_rearrange_stack
		
		// stack is: *a, HAYSTACK, NEEDLE, ret

	:$$LOOP
		// Compare char
		acu *b        // get value at HAYSTACK
		sub one
		+b deref acu  // save value of HAYSTACK to stack
		acu *b        // get value at NEEDLE
		sub lit 3
		acu deref acu
		sub b-        // pop value of HAYSTACK and compare
		ifTRUE $$END_FALSE

		// Increment HAYSTACK
		acu *b
		sub one
		incr acu
		// Increment NEEDLE
		acu *b
		sub lit 2
		incr acu

		// If we are here it means the string matches up to this point
		// Now we need to find out if both string ends, if not we need to loop

		// Check if end of NEEDLE
		acu *b
		sub lit 2
		// if NEEDLE end here it means HAYSTACK starts with NEEDLE
		ifStringEnd acu $$END_TRUE

		// Check if end of HAYSTACK
		acu *b
		sub one
		// if HAYSTACK end here it means HAYSTACK is shorter than NEEDLE
		ifStringEnd acu $$END_FALSE

		// Not end of either strings so we should loop
		goto $$LOOP


	// stack is: *a, HAYSTACK, NEEDLE, ret

	:$$END_TRUE
		*a b- // restore *a
		acu b-
		acu b-
		acu one
		return
	:$$END_FALSE
		*a b- // restore *a
		acu b-
		acu b-
		acu nil
		return
	}

	:$$START
	end undefined

	+b $NEEDLE
	+b $HAYSTACK
	call STR_START
}