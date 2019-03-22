_fn = {
    diag_log "a";
};

fn_a = {
    call _fn;
};

_fn = {
	diag_log "b";
};

call fn_a;