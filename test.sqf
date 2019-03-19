fn_a = {
	true
};

fn_b = {
	params ["_ignore"];
	true
};

// works
val = [] call (if([] call fn_a) then { fn_a } else { fn_a });

// doesn't work, only differnce is that fn_b has params
val2 = [] call (if([true] call fn_b) then { fn_a } else { fn_a });