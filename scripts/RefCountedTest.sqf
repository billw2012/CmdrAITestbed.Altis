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

testObj1 = [] call { 
	if (!(["RefCountedTest", __FILE__, __LINE__] call OOP_assert_class)) exitWith {throw format ["ERROR_NO_CLASS_%1", "RefCountedTest"]}; 
	private _oop_nextID = -1; 
	_oop_nul = isNil { 
		_oop_nextID = ( missionNamespace getVariable ("o_" + ("RefCountedTest") + "_spm_" + (  "nextID")) ); 
		if (isNil "_oop_nextID") then { 
			missionNamespace setVariable [("o_" + ("RefCountedTest") + "_spm_" + ("nextID")), 0];
			_oop_nextID = 0;
		}; 
		missionNamespace setVariable [("o_" + ("RefCountedTest") + "_spm_" + (  "nextID")),  _oop_nextID+1];
	};
	private _objNameStr = ("o_" + ("RefCountedTest") + "_N_" + (format ["%1",  _oop_nextID]));
	missionNameSpace setVariable [((_objNameStr) + "_" +   "oop_parent"),  "RefCountedTest"];
	private _oop_parents = ( missionNamespace getVariable ("o_" + ("RefCountedTest") + "_spm_" + ("parents")) );
	private _oop_i = 0;
	private _oop_parentCount = count _oop_parents;
	while {_oop_i < _oop_parentCount} do {
		([_objNameStr] +  []) call ( 
			if([(_oop_parents select _oop_i),  "new", __FILE__, __LINE__] call OOP_assert_method) then {
				( missionNameSpace getVariable (((_oop_parents select _oop_i)) + "_fnc_" + (   "new")) )
			} else {nil}
		);
		_oop_i = _oop_i + 1;
	};
	(([_objNameStr] + []) call (
		if([(( missionNameSpace getVariable ((_objNameStr) + "_" +   "oop_parent") )),   "new", __FILE__, __LINE__] call OOP_assert_method) then {
			( missionNameSpace getVariable (((( missionNameSpace getVariable ((_objNameStr) + "_" + "oop_parent") ))) + "_fnc_" + ("new")) )
		}else{nil}
	));
	_objNameStr
};
//testObj1 = NEW("RefCountedTest", []);
//CALLM0(testObj1, "unref");

// testObj2 = NEW("RefCountedTest", []);
// CALLM0(testObj2, "ref");
// CALLM0(testObj2, "unref");
// CALLM0(testObj2, "unref");
