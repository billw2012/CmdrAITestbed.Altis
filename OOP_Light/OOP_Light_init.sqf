#include "OOP_Light.h"

#ifdef ADE
#define DUMP_CALLSTACK ade_dumpCallstack
#else
#define DUMP_CALLSTACK 
#endif

/*
 * This file contains some functions for OOP_Light, mainly for asserting classess, objects and members.
 * Author: Sparker
 * 02.06.2018
*/

// Prints an error message with supplied text, file and line number
OOP_error = {
	params["_file", "_line", "_text"];
	diag_log format ["[OOP] Error: file: %1, line: %2, %3", _file, _line, _text];
};

// Print error when a member is not found
OOP_error_memberNotFound = {
	params ["_file", "_line", "_classNameStr", "_memNameStr"];
	private _errorText = format ["class '%1' has no member named '%2'", _classNameStr, _memNameStr];
	[_file, _line, _errorText] call OOP_error;
};

// Print error when a method is not found
OOP_error_methodNotFound = {
	params ["_file", "_line", "_classNameStr", "_methodNameStr"];
	private _errorText = format ["class '%1' has no method named '%2'", _classNameStr, _methodNameStr];
	[_file, _line, _errorText] call OOP_error;
};

//Print error when specified object is not an object
OOP_error_notObject = {
	params ["_file", "_line", "_objNameStr"];
	private _errorText = format ["'%1' is not an object (parent class not found)", _objNameStr];
	[_file, _line, _errorText] call OOP_error;
};

//Print error when specified class is not a class
OOP_error_notClass = {
	params ["_file", "_line", "_classNameStr"];
	private _errorText = "";
	if (isNil "_classNameStr") then {
		private _errorText = format ["class name is nil"];
		[_file, _line, _errorText] call OOP_error;
	} else {
		private _errorText = format ["class '%1' is not defined", _classNameStr];
		[_file, _line, _errorText] call OOP_error;
	};
};

//Print error when object's class is different from supplied class
OOP_error_wrongClass = {
	params ["_file", "_line", "_objNameStr", "_classNameStr", "_expectedClassNameStr"];
	private _errorText = format ["class of object %1 is %2, expected: %3", _objNameStr, _classNameStr, _expectedClassNameStr];
	[_file, _line, _errorText] call OOP_error;
};

//Check class and print error if it's not found
OOP_assert_class = {
	params["_classNameStr", "_file", "_line"];
	//Every class should have a member list. If it doesn't, then it's not a class
	private _memList = GET_SPECIAL_MEM(_classNameStr, STATIC_MEM_LIST_STR);
	//Check if it's a class
	if(isNil "_memList") then {
		[_file, _line, _classNameStr] call OOP_error_notClass;
		DUMP_CALLSTACK;
		false;
	} else {true};
};

//Check object class and print error if it differs from supplied
OOP_assert_objectClass = {
	params["_objNameStr", "_expectedClassNameStr", "_file", "_line"];

	//Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	//Check if it's an object
	if(isNil "_classNameStr") then {
		[_file, _line, _objNameStr] call OOP_error_notObject;
		DUMP_CALLSTACK;
		false;
	} else {
		private _parents = GET_SPECIAL_MEM(_classNameStr, PARENTS_STR);
		if (_expectedClassNameStr in _parents || _classNameStr == _expectedClassNameStr) then {
			true // all's fine
		} else {
			[_file, _line, _objNameStr, _classNameStr, _expectedClassNameStr] call OOP_error_wrongClass;
			DUMP_CALLSTACK;
			false
		};
	};
};

//Check object and print error if it's not an OOP object
OOP_assert_object = {
	params["_objNameStr", "_file", "_line"];
	//Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	//Check if it's an object
	if(isNil "_classNameStr") then {
		[_file, _line, _objNameStr] call OOP_error_notObject;
		DUMP_CALLSTACK;
		false;
	} else {
		true;
	};
};

//Check static member and print error if it's not found
OOP_assert_staticMember = {
	params["_classNameStr", "_memNameStr", "_file", "_line"];
	//Get static member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, STATIC_MEM_LIST_STR);
	//Check if it's a class
	if(isNil "_memList") exitWith {
		[_file, _line, _classNameStr] call OOP_error_notClass;
		DUMP_CALLSTACK;
		false;
	};
	//Check static member
	
	private _valid = (_memList findIf { (_x select 0) == _memNameStr }) != -1;
	if(!_valid) then {
		[_file, _line, _classNameStr, _memNameStr] call OOP_error_memberNotFound;
		DUMP_CALLSTACK;
	};
	//Return value
	_valid
};

//Check member and print error if it's not found or is ref
OOP_assert_member = {
	params["_objNameStr", "_memNameStr", "_file", "_line"];
	//Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	//Check if it's an object
	if(isNil "_classNameStr") exitWith {
		private _errorText = format ["class name is nil. Attempt to access member: %1", _memNameStr];
		[_file, _line, _errorText] call OOP_error;
		DUMP_CALLSTACK;
		false;
	};
	//Get member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);
	//Check member
	private _memIdx = _memList findIf { (_x select 0) == _memNameStr };
	private _valid = _memIdx != -1;
	if(!_valid) then {
		[_file, _line, _classNameStr, _memNameStr] call OOP_error_memberNotFound;
		DUMP_CALLSTACK;
	} else {
		// Check the member doesn't have the ref counted attribute (if it does we should
		// be using the REF macros with it)
		private _attr = (_memList select _memIdx) select 1;
		if (ATTR_REFCOUNTED in _attr) then {
			private _errorText = format ["class '%1' member '%2' is a ref but is NOT being treated like one!", _classNameStr, _memNameStr];
			[_file, _line, _errorText] call OOP_error;
		};
		// _valid will still be true as we can still write to the variable
	};
	//Return value
	_valid
};

//Check member ref and print error if it's not found or not a ref
OOP_assert_member_ref = {
	params["_objNameStr", "_memNameStr", "_file", "_line"];

	//Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	//Check if it's an object
	if(isNil "_classNameStr") exitWith {
		private _errorText = format ["class name is nil. Attempt to access member: %1", _memNameStr];
		[_file, _line, _errorText] call OOP_error;
		DUMP_CALLSTACK;
		false;
	};
	//Get member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);
	//Check member
	private _memIdx = _memList findIf { (_x select 0) == _memNameStr };
	private _valid = _memIdx != -1;
	if(!_valid) then {
		[_file, _line, _classNameStr, _memNameStr] call OOP_error_memberNotFound;
		DUMP_CALLSTACK;
	} else {
		// Check the member has the ref counted attribute (if it doesn't we shouldn't
		// be using the REF macros with it)
		private _attr = (_memList select _memIdx) select 1;
		if !(ATTR_REFCOUNTED in _attr) then {
			private _errorText = format ["class '%1' member '%2' is not a ref but is being treated like one!", _classNameStr, _memNameStr];
			[_file, _line, _errorText] call OOP_error;
		};
		// _valid will still be true as we can still write to the variable
	};
	//Return value
	_valid
};

//Check method and print error if it's not found
OOP_assert_method = {
	params["_classNameStr", "_methodNameStr", "_file", "_line"];

	if (isNil "_classNameStr") exitWith {
		private _errorText = format ["class name is nil. Attempt to call method: %1", _methodNameStr];
		[_file, _line, _errorText] call OOP_error;
		DUMP_CALLSTACK;
		false;
	};

	//Get static member list of this class
	private _methodList = GET_SPECIAL_MEM(_classNameStr, METHOD_LIST_STR);
	//Check if it's a class
	if(isNil "_methodList") exitWith {
		[_file, _line, _classNameStr] call OOP_error_notClass;
		DUMP_CALLSTACK;
		false;
	};
	//Check method
	private _valid = _methodNameStr in _methodList;
	if(!_valid) then {
		[_file, _line, _classNameStr, _methodNameStr] call OOP_error_methodNotFound;
		DUMP_CALLSTACK;
	};
	//Return value
	_valid
};

// Dumps all variables of an object
OOP_dumpAllVariables = {
	params [["_thisObject", "", [""]]];
	// Get object's class
	private _classNameStr = OBJECT_PARENT_CLASS_STR(_thisObject);
	//Get member list of this class
	private _memList = GET_SPECIAL_MEM(_classNameStr, MEM_LIST_STR);
	diag_log format ["DEBUG: Dumping all variables of %1: %2", _thisObject, _memList];
	{
		_x params ["_memName", "_memAttr"];
		private _varValue = GETV(_thisObject, _memName);
		if (isNil "_varValue") then {
			diag_log format ["DEBUG: %1.%2: %3", _thisObject, _memName, "<null>"];
		} else {
			diag_log format ["DEBUG: %1.%2: %3", _thisObject, _memName, _varValue];
		};
	} forEach _memList;
};


// ---- Remote execution ----
// A remote code wants to execute something on this machine
// However remote machine doesn't have to know what class the object belongs to
// So we must find out object's class on this machine and then run the method
OOP_callFromRemote = {
	params[["_object", "", [""]], ["_methodNameStr", "", [""]], ["_params", [], [[]]]];
	//diag_log format [" --- OOP_callFromRemote: %1", _this];
	CALLM(_object, _methodNameStr, _params);
};

// If assertion is enabled, this gets called on remote machine when we call a static method on it
// So it will run the standard assertions before calling static method
OOP_callStaticMethodFromRemote = {
	params [["_classNameStr", "", [""]], ["_methodNameStr", "", [""]], ["_args", [], [[]]]];
	CALL_STATIC_METHOD(_classNameStr, _methodNameStr, _args);
};

fn_test = { 
	true 
};

OOP_new = {
	params ["_classNameStr", "_extraParams"];

	CONSTRUCTOR_ASSERT_CLASS(_classNameStr);

	private _oop_nextID = -1;
	_oop_nul = isNil {
		_oop_nextID = GET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR);
		if (isNil "_oop_nextID") then { 
			SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, 0);	_oop_nextID = 0;
		};
		SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, _oop_nextID+1);
	};
	
	private _objNameStr = OBJECT_NAME_STR(_classNameStr, _oop_nextID);

	FORCE_SET_MEM(_objNameStr, OOP_PARENT_STR, _classNameStr);
	private _oop_parents = GET_SPECIAL_MEM(_classNameStr, PARENTS_STR);
	private _oop_i = 0;
	private _oop_parentCount = count _oop_parents;

	while { _oop_i < _oop_parentCount } do {
		//([_objNameStr] + _extraParams) call GET_METHOD((_oop_parents select _oop_i), "new");
		([_objNameStr] + _extraParams) call FORCE_GET_METHOD((_oop_parents select _oop_i), "new");
		_oop_i = _oop_i + 1;
	};
	private _args = ([_objNameStr] + _extraParams);
	private _oopp = missionNameSpace getVariable ((_objNameStr) + "_" + "oop_parent");
	private _assargs = [((_oopp)), "new", __FILE__, __LINE__];
	diag_log format ["_args = %1, _oopp = %2", _args, _oopp];

	(_args call ( 
		if([] call fn_test) then {
			( missionNameSpace getVariable ((((missionNameSpace getVariable ((_objNameStr) + "_" + "oop_parent")))) + "_fnc_" + ("new")) )
		} else {
			nil
		} ));
	//CALL_METHOD(_objNameStr, "new", _extraParams);
	_objNameStr
};

OOP_new_public = {
	params ["_classNameStr", "_extraParams"];

	CONSTRUCTOR_ASSERT_CLASS(_classNameStr);

	private _oop_nextID = -1;
	_oop_nul = isNil {
		_oop_nextID = GET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR);
		if (isNil "_oop_nextID") then { 
			SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, 0); _oop_nextID = 0;
		};
		SET_SPECIAL_MEM(_classNameStr, NEXT_ID_STR, _oop_nextID+1);
	};
	private _objNameStr = OBJECT_NAME_STR(_classNameStr, _oop_nextID);
	FORCE_SET_MEM(_objNameStr, OOP_PARENT_STR, _classNameStr);
	PUBLIC_VAR(_objNameStr, OOP_PARENT_STR);
	FORCE_SET_MEM(_objNameStr, OOP_PUBLIC_STR, 1);
	PUBLIC_VAR(_objNameStr, OOP_PUBLIC_STR);
	private _oop_parents = GET_SPECIAL_MEM(_classNameStr, PARENTS_STR);
	private _oop_i = 0;
	private _oop_parentCount = count _oop_parents;
	while {_oop_i < _oop_parentCount} do {
		([_objNameStr] + _extraParams) call GET_METHOD((_oop_parents select _oop_i), "new");
		_oop_i = _oop_i + 1;
	};
	CALL_METHOD(_objNameStr, "new", _extraParams);
	_objNameStr
};

OOP_delete = {
	params ["_objNameStr"];

	DESTRUCTOR_ASSERT_OBJECT(_objNameStr);

	private _oop_classNameStr = OBJECT_PARENT_CLASS_STR(_objNameStr);
	private _oop_parents = GET_SPECIAL_MEM(_oop_classNameStr, PARENTS_STR);
	private _oop_parentCount = count _oop_parents;
	private _oop_i = _oop_parentCount - 1;

	CALL_METHOD(_objNameStr, "delete", []);
	while {_oop_i > -1} do {
		[_objNameStr] call GET_METHOD((_oop_parents select _oop_i), "delete");
		_oop_i = _oop_i - 1;
	};

	private _isPublic = IS_PUBLIC(_objNameStr);
	private _oop_memList = GET_SPECIAL_MEM(_oop_classNameStr, MEM_LIST_STR);

	if (_isPublic) then {
		{
			_x params ["_memName", "_memAttr"];
			if(ATTR_REFCOUNTED in _memAttr) then {
				private _memObj = FORCE_GET_MEM(_objNameStr, _memName);
				if(_memObj isEqualType "") then {
					CALLM0(_memObj, "unref");
				};
			};
			FORCE_SET_MEM(_objNameStr, _memName, nil);
			PUBLIC_VAR(_objNameStr, OOP_PARENT_STR);
		} forEach _oop_memList;
	} else {
		{
			_x params ["_memName", "_memAttr"];
			if(ATTR_REFCOUNTED in _memAttr) then {
				private _memObj = FORCE_GET_MEM(_objNameStr, _memName);
				if(_memObj isEqualType "") then {
					CALLM0(_memObj, "unref");
				};
			};
			FORCE_SET_MEM(_objNameStr, _memName, nil);
		} forEach _oop_memList;
	};
};