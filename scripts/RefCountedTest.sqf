#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

call compile preprocessFileLineNumbers "OOP_Light\OOP_Light_init.sqf";
call compile preprocessFileLineNumbers "scripts\RefCounted.sqf";

CLASS("RefCountedTest", "RefCounted")
	METHOD("new") {
		params [P_THISOBJECT];
		OOP_INFO_1("%1 created", _thisObject);
	} ENDMETHOD;

	METHOD("delete") {
		params [P_THISOBJECT];
		OOP_INFO_1("%1 deleted", _thisObject);
	} ENDMETHOD;
ENDCLASS;

CLASS("RefPtrContainer", "")
	VARIABLE_ATTR("refPtr", [ATTR_REFCOUNTED]);

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_refPtrIn")];
		T_SETV_REF("refPtr", _refPtrIn);
		OOP_INFO_1("%1 created", _thisObject);
	} ENDMETHOD;

	METHOD("delete") {
		params [P_THISOBJECT];
		OOP_INFO_1("%1 deleted", _thisObject);
	} ENDMETHOD;
ENDCLASS;

OOP_INFO_0("Test single ref unref ==============================================");
// Test single ref unref
isNil {
	private _testObj1 = NEW("RefCountedTest", []);
	CALLM0(_testObj1, "ref");
	CALLM0(_testObj1, "unref");
};

OOP_INFO_0("Test multiple ref unref ============================================");
// Test multiple ref unref
isNil {
	private _testObj = NEW("RefCountedTest", []);
	CALLM0(_testObj, "ref");
	CALLM0(_testObj, "ref");
	CALLM0(_testObj, "unref");
	CALLM0(_testObj, "unref");
};

OOP_INFO_0("Test ref members ===================================================");
// Test ref members
isNil {
	private _testObj = NEW("RefCountedTest", []);
	private _objArray = [1, 2, 3] apply { NEW("RefPtrContainer", [_testObj]) };
	{
		DELETE(_x);
	} forEach _objArray;
};
