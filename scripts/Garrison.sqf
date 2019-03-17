#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

// Collection of unitCount/vehCount and their orders
CLASS("Garrison", "")
	VARIABLE("marker");
	VARIABLE("unitCount");
	VARIABLE("vehCount");
	VARIABLE("order");
	VARIABLE("actions");
	VARIABLE("inCombat");
	VARIABLE("pos");
	VARIABLE("garrSide");

	METHOD("new") {
		params [P_THISOBJECT];
		T_SETV("marker", objNull);
		T_SETV("unitCount", 0);
		T_SETV("vehCount", 0);
		T_SETV("order", objNull);
		T_SETV("actions", []);
		T_SETV("inCombat", false);
		T_SETV("pos", []);
		T_SETV("garrSide", side_none);
	} ENDMETHOD;

	METHOD("initFromMarker") {
		params [P_THISOBJECT, P_STRING("_marker")];
		T_SETV("marker", _marker);

		private _parts = (markerText _marker) splitString ", :;/";

		private _unitCount = if(count _parts >= 1) then { parseNumber (_parts select 0) } else { 0 };
		private _vehCount = if(count _parts >= 2) then { parseNumber (_parts select 1) } else { 0 };

		OOP_INFO_3("Initializing Garrison from %1 [%2/%3]", _marker, _unitCount, _vehCount);

		T_SETV("unitCount", _unitCount);
		T_SETV("vehCount", _vehCount);
		T_SETV("order", objNull);
		T_SETV("inCombat", false);
		T_SETV("pos", markerPos _marker);
		T_SETV("garrSide", markerColor _marker);
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
		params [P_THISOBJECT, P_STRING("_state")];
		private _newGarr = NEW("Garrison", []);

		SETV(_newGarr, "unitCount", T_GETV("unitCount"));
		SETV(_newGarr, "vehCount", T_GETV("vehCount"));
		SETV(_newGarr, "order", T_GETV("order"));
		SETV(_newGarr, "actions", T_GETV("actions"));
		SETV(_newGarr, "inCombat", T_GETV("inCombat"));
		SETV(_newGarr, "pos", +T_GETV("pos"));
		SETV(_newGarr, "garrSide", T_GETV("garrSide"));

		_newGarr
	} ENDMETHOD;

	METHOD("getPos") {
		params [P_THISOBJECT];
		T_GETV("pos");
	} ENDMETHOD;

	METHOD("setPos") {
		params [P_THISOBJECT, P_ARRAY("_pos")];
		T_SETV("pos", _pos);
		T_PRVAR(marker);
		if !(isNull _marker) then {
			_marker setMarkerPos _pos;
		};
	} ENDMETHOD;

	METHOD("getSide") {
		params [P_THISOBJECT];
		T_GETV("garrSide");
	} ENDMETHOD;

	METHOD("setSide") {
		params [P_THISOBJECT, P_STRING("_garrSide")];
		T_SETV("garrSide", _garrSide);
		T_PRVAR(marker);
		if !(isNull _marker) then {
			_marker setMarkerPos _garrSide;
		};
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

	METHOD("isDead") {
		params [P_THISOBJECT];
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		(_unitCount + _vehCount) == 0
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT];
		T_PRVAR(marker);
		T_PRVAR(unitCount);
		T_PRVAR(vehCount);
		T_PRVAR(order);

		if !(isNull _order) then {
			CALLM0(_order, "update");
		};

		if !(isNull _marker) then {
			T_PRVAR(pos);
			T_PRVAR(garrSide);
			_marker setMarkerPos _pos;
			_marker setMarkerColor _garrSide;
			_marker setMarkerText (format ["%1/%2", _unitCount, _vehCount]);
		};

		// Clear combat flag
		T_SETV("inCombat", false);
	} ENDMETHOD;

	METHOD("fightUpdate") {
		params [P_THISOBJECT, P_STRING("_other")];

		if(T_CALLM0("isDead") or CALLM0(_other, "isDead")) exitWith {};

		T_PRVAR(unitCount);
		T_PRVAR(vehCount);

		private _other_unitCount = GETV(_other, "unitCount");
		private _other_vehCount = GETV(_other, "vehCount");

		private _msg = format ["Fighting %1 [%2/%3] vs %4 [%5/%6]", _thisObject, _unitCount, _vehCount, _other, _other_unitCount, _other_vehCount];

		OOP_INFO_0(_msg);
		// OOP_INFO_4("Fighting %1 [%2/%3] vs %3 [%4]", _thisObject, _other);
		private _total = _unitCount + _vehCount + _other_unitCount + _other_vehCount;

		for "_i" from 0 to random(_total - 1) do
		{
			private _ourStrength = _unitCount * UNIT_STRENGTH + _vehCount * VEHICLE_STRENGTH;
			private _theirStrength = _other_unitCount * UNIT_STRENGTH + _other_vehCount * VEHICLE_STRENGTH;
			
			if(_ourStrength == 0) exitWith { OOP_INFO_1("%1 died", _thisObject) };
			if(_theirStrength == 0) exitWith { OOP_INFO_1("%1 died", _other) };

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

		T_SETV("unitCount", _unitCount);
		T_SETV("vehCount", _vehCount);
		SETV(_other, "unitCount", _other_unitCount);
		SETV(_other, "vehCount", _other_vehCount);

		// Set combat flag
		T_SETV("inCombat", true);
	} ENDMETHOD;
ENDCLASS;