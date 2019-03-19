#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

CLASS("RefCounted", "")
	VARIABLE("refCount");

	METHOD("new") {
		params [P_THISOBJECT];
		// Start at ref count zero. When the object gets assigned to a VARIABLE
		// using T_SETV_REF it will be automatically reffed.
		T_SETV("refCount", 0);
	} ENDMETHOD;

	METHOD("ref") {
		params [P_THISOBJECT];
		CRITICAL_SECTION {
			T_PRVAR(refCount);
			_refCount = _refCount + 1;
			T_SETV("refCount", _refCount);
		};
	} ENDMETHOD;

	METHOD("unref") {
		params [P_THISOBJECT];
		CRITICAL_SECTION {
			T_PRVAR(refCount);
			_refCount = _refCount - 1;
			if(_refCount == 0) then {
				DELETE(_thisObject);
			} else {
				T_SETV("refCount", _refCount);
			};
		};
	} ENDMETHOD;
ENDCLASS;
