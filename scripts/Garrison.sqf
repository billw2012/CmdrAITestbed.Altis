#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

// Collection of unitCount/vehCount and their orders
CLASS("Garrison", "RefCounted")
	VARIABLE("id");
	VARIABLE("ownerState");
	VARIABLE("marker");
	VARIABLE("unitCount");
	VARIABLE("vehCount");
	VARIABLE_ATTR("order", [ATTR_REFCOUNTED]);
	VARIABLE_ATTR("currAction", [ATTR_REFCOUNTED]);
	VARIABLE("inCombat");
	VARIABLE("pos");
	VARIABLE("garrSide");
	VARIABLE("outpostId");

	// TODO: no reason this shouldn't take ref to state, it exists IN state after all.
	// TODO: id should be arbitrary not index into array.
	// TODO: add proper clean up of deleted garrisons.
	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_ownerState")];
		T_SETV("id", -1);
		T_SETV("ownerState", _ownerState);
		T_SETV("marker", objNull);
		T_SETV("unitCount", 0);
		T_SETV("vehCount", 0);
		T_SETV_REF("order", objNull);
		T_SETV_REF("currAction", objNull);
		T_SETV("inCombat", false);
		T_SETV("pos", []);
		T_SETV("garrSide", side_none);
		T_SETV("outpostId", -1);
	} ENDMETHOD;

	// METHOD("delete") {
	// 	params [P_THISOBJECT];
	// 	T_SETV("marker", objNull);
	// 	T_SETV("unitCount", 0);
	// 	T_SETV("vehCount", 0);
	// 	T_SETV("inCombat", false);
	// 	T_SETV("pos", []);
	// 	T_SETV("garrSide", side_none);
	// } ENDMETHOD;

	METHOD("initFromMarker") {
		params [P_THISOBJECT, P_STRING("_marker")];
		T_SETV("marker", _marker);

		private _parts = (markerText _marker) splitString ", :;/";

		private _unitCount = if(count _parts >= 1) then { parseNumber (_parts#0) } else { 0 };
		private _vehCount = if(count _parts >= 2) then { parseNumber (_parts#1) } else { 0 };

		OOP_INFO_3("Initializing Garrison from %1 [%2/%3]", _marker, _unitCount, _vehCount);

		T_SETV("unitCount", _unitCount);
		T_SETV("vehCount", _vehCount);
		T_SETV("inCombat", false);
		T_SETV("pos", markerPos _marker);
		T_SETV("garrSide", markerColor _marker);
	} ENDMETHOD;

	METHOD("setId") {
		params [P_THISOBJECT, P_NUMBER("_id")];
		T_SETV("id", _id);
		T_CALLM0("updateMarkerText");
	} ENDMETHOD;

	/*

	To iterate plan and correctly score actions we need to take into account the existing state, including orders (so we
	don't duplicate orders to reinforce for instance), and any already planned actions. 
	What is the difference between actions and orders?
		Actions are a unit of planning, orders are how a garrison helps achieve the actions goals.

	Does simulation need to happen at action or order level? 
		In progress orders need to be taken into account. This could be done during scoring by looking at in progress
		and planned actions?
		Perhaps actions need an simApply function to immediately update state to their simulated results? Yes.
		Do orders need this? Yes. Action might be partially completed, so simApply wouldn't necessarily be correct.
		Also maybe orders come from elsewhere.
		We should implement simApply in terms of applying orders instead of separately. Use the same order generation, 
		just run it to completion? In future this can do time step simulation.

	What requirements does this entail?
		Need to be able to clone entire state:
		This means garrisons and their current orders at least.
		Orders point to items in the state. So we need garrison IDs instead of pointers to objects, so that
		cloned orders can point to cloned everything else.
		Update/apply functions etc will be taking a state object that they apply to.

	*/

	METHOD("simCopy") {
		params [P_THISOBJECT, P_STRING("_newState")];
		private _newGarr = NEW("Garrison", [_newState]);
		SETV(_newGarr, "id", T_GETV("id"));
		SETV(_newGarr, "unitCount", T_GETV("unitCount"));
		SETV(_newGarr, "vehCount", T_GETV("vehCount"));
		SETV_REF(_newGarr, "order", T_GETV("order"));
		SETV_REF(_newGarr, "currAction", T_GETV("currAction"));
		SETV(_newGarr, "inCombat", T_GETV("inCombat"));
		SETV(_newGarr, "pos", +T_GETV("pos"));
		SETV(_newGarr, "garrSide", T_GETV("garrSide"));
		SETV(_newGarr, "outpostId", T_GETV("outpostId"));
		_newGarr
	} ENDMETHOD;

	METHOD("updateMarkerText") {
		params [P_THISOBJECT];
		T_PRVAR(marker);
		if (_marker isEqualType "") then {
			T_PRVAR(unitCount);
			T_PRVAR(vehCount);
			T_PRVAR(id);
			T_PRVAR(currAction);
			private _actionText = if(_currAction isEqualType "" and {!GETV(_currAction, "complete")}) then {
				"[" + CALLM0(_currAction, "getLabel") + "]"
			} else {
				""
			};
			_marker setMarkerText (format ["     %1/%2 (g%3) %4", _unitCount, _vehCount, _id, _actionText]);
		};
	} ENDMETHOD;
	
	METHOD("setComp") {
		params [P_THISOBJECT, P_NUMBER("_newUnitCount"), P_NUMBER("_newVehCount")];
		private _unitCount = 0 max floor _newUnitCount;
		private _vehCount = 0 max floor _newVehCount;
		T_SETV("unitCount", _unitCount);
		T_SETV("vehCount", _vehCount);
		if(_unitCount == 0 and _vehCount == 0) then {
			T_CALLM0("killed");
		} else {
			T_CALLM0("updateMarkerText");
		};
	} ENDMETHOD;

	METHOD("killed") {
		params [P_THISOBJECT];
		T_PRVAR(marker);
		T_PRVAR(ownerState);
		T_SETV("unitCount", 0);
		T_SETV("vehCount", 0);
		if (_marker isEqualType "") then {
			deleteMarker _marker;
		};
		CALLM1(_ownerState, "garrisonKilled", _thisObject);
	} ENDMETHOD;

	METHOD("getComp") {
		params [P_THISOBJECT];
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		[_unitCount, _vehCount]
	} ENDMETHOD;

	METHOD("getPos") {
		params [P_THISOBJECT];
		T_GETV("pos")
	} ENDMETHOD;

	METHOD("setPos") {
		params [P_THISOBJECT, P_ARRAY("_pos")];
		T_SETV("pos", _pos);
		T_PRVAR(marker);
		if (_marker isEqualType "") then {
			_marker setMarkerPos _pos;
		};
	} ENDMETHOD;

	METHOD("getSide") {
		params [P_THISOBJECT];
		T_GETV("garrSide")
	} ENDMETHOD;

	METHOD("setSide") {
		params [P_THISOBJECT, P_STRING("_garrSide")];
		T_SETV("garrSide", _garrSide);
		T_PRVAR(marker);
		if (_marker isEqualType "") then {
			_marker setMarkerColor _garrSide;
		};
	} ENDMETHOD;

	METHOD("getAction") {
		params [P_THISOBJECT];
		T_GETV("currAction")
	} ENDMETHOD;

	METHOD("setAction") {
		params [P_THISOBJECT, P_STRING("_action")];
		T_SETV_REF("currAction", _action);
	} ENDMETHOD;

	METHOD("clearAction") {
		params [P_THISOBJECT];
		T_SETV_REF("currAction", objNull);
	} ENDMETHOD;

	METHOD("getSpeed") {
		params [P_THISOBJECT];
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		private _speedMul = if(T_GETV("inCombat")) then { 0.1 } else { 1 };
		if(_unitCount <= (_vehCount * UNITS_PER_VEHICLE)) then { VEHICLE_SPEED_MS * _speedMul } else { UNIT_SPEED_MS * _speedMul }
	} ENDMETHOD;

	METHOD("getStrength") {
		params [P_THISOBJECT];
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		_unitCount * UNIT_STRENGTH + _vehCount * VEHICLE_STRENGTH
	} ENDMETHOD;

	METHOD("modComp") {
		params [P_THISOBJECT, P_ARRAY("_mod")];
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		_unitCount = 0 max floor (_unitCount + _mod#0);
		_vehCount = 0 max floor (_vehCount + _mod#1);
		T_SETV("unitCount", _unitCount);
		T_SETV("vehCount", _vehCount);
		T_CALLM0("updateMarkerText");
	} ENDMETHOD;

	METHOD("isDead") {
		params [P_THISOBJECT];
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		(0 max floor (_unitCount + _vehCount)) == 0
	} ENDMETHOD;

	METHOD("giveOrder") {
		params [P_THISOBJECT, P_STRING("_newOrder")];
		T_SETV_REF("order", _newOrder);
	} ENDMETHOD;

	METHOD("cancelOrder") {
		params [P_THISOBJECT];
		T_SETV_REF("order", objNull);
	} ENDMETHOD;

	METHOD("isOrderComplete") {
		params [P_THISOBJECT];
		T_PRVAR(order);
		private _complete = true;
		if (_order isEqualType "") then {
			_complete = GETV(_order, "complete");
		};
		_complete
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(marker);
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		T_PRVAR(order);

		if (_order isEqualType "") then {
			CALLM1(_order, "update", _state);
		};

		if (_marker isEqualType "") then {
			if(T_CALLM0("isDead")) then {
				deleteMarker _marker;
				T_SETV("marker", objNull);
			} else {
				T_PRVAR(pos);
				T_PRVAR(garrSide);
				_marker setMarkerPos _pos;
				_marker setMarkerColor _garrSide;
				T_CALLM0("updateMarkerText");
			};
		};

		// Clear combat flag
		T_SETV("inCombat", false);
	} ENDMETHOD;

	METHOD("fightUpdate") {
		params [P_THISOBJECT, P_STRING("_other")];

		if(T_CALLM0("isDead") or CALLM0(_other, "isDead")) exitWith {};

		if(T_CALLM0("getSide") == CALLM0(_other, "getSide")) exitWith {
			OOP_ERROR_1("Can't fight %1, same side!", _other);
			DUMP_CALLSTACK;
		};

		T_PRVAR(unitCount);
		T_PRVAR(vehCount);

		(CALLM0(_other, "getComp")) params ["_other_unitCount", "_other_vehCount"];
		// private _other_unitCount = GETV(_other, "unitCount");
		// private _other_vehCount = GETV(_other, "vehCount");
		T_PRVAR(id);
		private _otherId = GETV(_other, "id");
		private _msg = format ["Fighting g%1 [%2/%3] vs g%4 [%5/%6]", _id, _unitCount, _vehCount, _otherId, _other_unitCount, _other_vehCount];

		OOP_INFO_0(_msg);
		// OOP_INFO_4("Fighting %1 [%2/%3] vs %3 [%4]", _thisObject, _other);
		private _total = _unitCount + _vehCount + _other_unitCount + _other_vehCount;
		private _ourPos = T_CALLM0("getPos");
		private _otherPos = CALLM0(_other, "getPos");
		private _distCoeff = CALLSM3("Action", "calcDistanceFalloff", _ourPos, _otherPos, 10);

		// Some fake fighting based on relative strengths.
		for "_i" from 0 to random(_total - 1) do
		{	
			private _ourStrength = _unitCount * UNIT_STRENGTH + _vehCount * VEHICLE_STRENGTH;
			private _theirStrength = _other_unitCount * UNIT_STRENGTH + _other_vehCount * VEHICLE_STRENGTH;
			
			if(floor _ourStrength == 0) exitWith { OOP_INFO_1("g%1 died", _id) };
			if(floor _theirStrength == 0) exitWith { OOP_INFO_1("g%1 died", _otherId) };

			if((random 1) <= _distCoeff) then {
				// Decide the fate of a random unit.
				// This probably isn't remotely realistic, but at least stronger garrison should usually win.
				if(random(_ourStrength + _theirStrength) < _ourStrength) then {
					if((_other_vehCount == 0) or (random(UNIT_STRENGTH + VEHICLE_STRENGTH) < VEHICLE_STRENGTH)) then {
						_other_unitCount = _other_unitCount - 1;
					} else {
						_other_vehCount = _other_vehCount - 1;
					};
				} else {
					if((_vehCount == 0) or (random(UNIT_STRENGTH + VEHICLE_STRENGTH) < VEHICLE_STRENGTH)) then {
						_unitCount = _unitCount - 1;
					} else {
						_vehCount = _vehCount - 1;
					};
				};
			};
		};

		T_CALLM2("setComp", _unitCount, _vehCount);
		CALLM2(_other, "setComp", _other_unitCount, _other_vehCount);

		// Set combat flag
		T_SETV("inCombat", true);
	} ENDMETHOD;

	// Split the garrison, based on composition, returning the new one
	METHOD("splitGarrison") {
		params [P_THISOBJECT, P_ARRAY("_newComp")];
		T_PRVAR(ownerState);
		T_PRVAR(marker);
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		T_PRVAR(pos);
		T_PRVAR(garrSide);
		T_PRVAR(id);


		// Cap the new composition based on our composition
		private _otherUnitCount = _unitCount min floor (_newComp#0);
		private _otherVehCount = _vehCount min floor (_newComp#1);

		if(_otherUnitCount == 0 and _otherVehCount == 0) exitWith {
			OOP_ERROR_1("Cannot split garrison from %1 with no forces.", _id);
		};

		// Remove from our comp
		_unitCount = _unitCount - _otherUnitCount;
		_vehCount = _vehCount - _otherVehCount;
		if(_unitCount == 0 and _vehCount == 0) exitWith {
			OOP_ERROR_1("Cannot split garrison from %1 with ALL forces.", _id);
		};
		T_CALLM2("setComp", _unitCount, _vehCount);

		private _newGarrison = NEW("Garrison", [_ownerState]);
		// Create new marker and update it
		if (_marker isEqualType "") then {
			private _newMarker = createMarker [_marker + "_detachment_" + str(time), _pos];
			_newMarker setMarkerType (markerType _marker);
			_newMarker setMarkerShape "ICON";
			SETV(_newGarrison, "marker", _newMarker);
		};

		// Update rest of new garrison vars
		CALLM2(_newGarrison, "setComp", _otherUnitCount, _otherVehCount);
		CALLM1(_newGarrison, "setPos", _pos);
		CALLM1(_newGarrison, "setSide", _garrSide);

		_newGarrison
	} ENDMETHOD;

	// Merge the garrison into this one
	METHOD("mergeGarrison") {
		params [P_THISOBJECT, P_STRING("_garr")];
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		T_PRVAR(id);

		private _garrId = GETV(_garr, "id");
		
		OOP_DEBUG_2("Merging %1 into %2", _id, _garrId);

		if(_unitCount == 0 and _vehCount == 0) exitWith {
			OOP_ERROR_2("Cannot merge %1 into dead garrison %2.", _garrId, _id);
		};

		// Merge comps, this is all merge garrisons does
		private _otherComp = CALLM0(_garr, "getComp");
		_unitCount = _unitCount + _otherComp#0;
		_vehCount = _vehCount + _otherComp#1;
		T_CALLM2("setComp", _unitCount, _vehCount);

		// Clear out comp of old garrison, it will be dead after this
		CALLM2(_garr, "setComp", 0, 0);
	} ENDMETHOD;
ENDCLASS;
