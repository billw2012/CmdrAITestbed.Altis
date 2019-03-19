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
		OOP_INFO_0("RefCountedTest created");
	} ENDMETHOD;

	METHOD("delete") {
		params [P_THISOBJECT];
		OOP_INFO_0("RefCountedTest deleted");
	} ENDMETHOD;
ENDCLASS;

testObj1 = NEW("RefCountedTest", []);
CALLM0(testObj1, "unref");

testObj2 = NEW("RefCountedTest", []);
CALLM0(testObj2, "ref");
CALLM0(testObj2, "unref");
CALLM0(testObj2, "unref");
