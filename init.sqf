#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR
#include "OOP_Light\OOP_Light.h"

// #define LOG_SCOPE "Main"

call compile preprocessFileLineNumbers "OOP_Light\OOP_Light_init.sqf";

// modules = [];

// player addAction ["Recompile",
// {
// 	{
// 		_x params ["_delete", "_source_file"];

// 	} forEach modules;
// }];

side_opf = "ColorEAST";
side_guer = "ColorGUER";
side_no = "ColorYellow";

type_outpost = "hd_flag";
type_garrison = "mil_box";

order_types = [];

// Base class for orders
CLASS("Order", "")
	VARIABLE("name");
	VARIABLE("complete");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_name")];
		T_SETV("name", _name);
		T_SETV("complete", false);
	} ENDMETHOD;
ENDCLASS;

// Move garrison to position
CLASS("MoveOrder", "Order")
	VARIABLE("target");
	VARIABLE("garrison");
	VARIABLE("lastT");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_name"), P_STRING("_target"), P_OBJECT("_garrison")];
		T_SETV("target", _target);
		T_SETV("garrison", _garrison);
		T_SETV("lastT", time);
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT];
		T_PRVAR(target);
		T_PRVAR(garrison);
		T_PRVAR(lastT);

		private _speed = CALLM0(_garrison, "getSpeed");
		private _targetPos = markerPos _target;
		private _garrisonPos = CALLM0(_garrison, "getPos");
		private _dist = _targetPos distance _garrisonPos;
		private _dt = time - _lastT;
		T_SETV("lastT", time);

		if(_dist > 0) then {
			private _travel = _dist min (_speed * _dt);
			private _vec = _garrisonPos vectorFromTo _targetPos;
			_garrisonPos = _garrisonPos vectorAdd (_vec vectorMultiply _travel);
			CALLM1(_garrison, "setPos", _garrisonPos);
		} else {
			T_SETV("complete", true);
		};
	} ENDMETHOD;
ENDCLASS;

#define UNITS_PER_VEHICLE 8
#define UNIT_STRENGTH 1
#define VEHICLE_STRENGTH 5

#define UNIT_SPEED_MS (6 * 0.277778)
#define VEHICLE_SPEED_MS (60 * 0.277778)

// Collection of unit_count/veh_count and their orders
CLASS("Garrison", "")
	VARIABLE("marker");
	VARIABLE("unit_count");
	VARIABLE("veh_count");
	VARIABLE("order");
	VARIABLE("in_combat");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_marker")];
		T_SETV("marker", _marker);

		private _parts = (markerText _marker) splitString ", :;/";
		private _unit_count = if(count _parts >= 1) then { parseNumber (_parts select 0) } else { 0 };
		private _veh_count = if(count _parts >= 2) then { parseNumber (_parts select 1) } else { 0 };

		T_SETV("unit_count", _unit_count);
		T_SETV("veh_count", _veh_count);
		T_SETV("order", objNull);
		T_SETV("in_combat", false);
	} ENDMETHOD;

	METHOD("getPos") {
		params [P_THISOBJECT];
		T_PRVAR(marker);
		markerPos _marker
	} ENDMETHOD;

	METHOD("setPos") {
		params [P_THISOBJECT, P_ARRAY("_pos")];
		T_PRVAR(marker);
		_marker setMarkerPos _pos;
	} ENDMETHOD;

	METHOD("getSide") {
		params [P_THISOBJECT];
		T_PRVAR(marker);
		markerColor _marker
	} ENDMETHOD;

	METHOD("setSide") {
		params [P_THISOBJECT, P_STRING("_side")];
		T_PRVAR(marker);
		_marker setMarkerColor _side;
	} ENDMETHOD;

	METHOD("getSpeed") {
		params [P_THISOBJECT];
		T_PRVAR(unit_count);
		T_PRVAR(veh_count);
		private _speedMul = if(T_GETV("in_combat")) then { 0.1 } else { 1 };
		if(_unit_count <= (_veh_count * UNITS_PER_VEHICLE)) then { VEHICLE_SPEED_MS * _speedMul } else { UNIT_SPEED_MS * _speedMul }
	} ENDMETHOD;

	METHOD("getStrength") {
		params [P_THISOBJECT];
		T_PRVAR(unit_count);
		T_PRVAR(veh_count);

		_unit_count * UNIT_STRENGTH + _veh_count * VEHICLE_STRENGTH
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT];
		T_PRVAR(marker);
		T_PRVAR(unit_count);
		T_PRVAR(veh_count);
		T_PRVAR(order);
		_marker setMarkerText (format ["%1/%2", _unit_count, _veh_count]);

		if !(isNull _order) then {
			CALLM0(_order, "update");
		};

		// Clear combat flag
		T_SETV("in_combat", false);
	} ENDMETHOD;

	METHOD("fight_update") {
		params [P_THISOBJECT, P_STRING("_other")];
		private _dead = [];

		T_PRVAR(unit_count);
		T_PRVAR(veh_count);

		private _other_unit_count = GETV(_other, "unit_count");
		private _other_veh_count = GETV(_other, "veh_count");
		private _total = _unit_count + _veh_count + _other_unit_count + _other_veh_count;

		for "_i" from 0 to random(_total - 1) do
		{
			private _idx = random(_unit_count + _veh_count - 1);
			private _idx2 = random(_other_unit_count + _other_veh_count - 1);
			if(_idx < _unit_count) then {
				if(_idx2 < _other_unit_count) then {
					if(random (UNIT_STRENGTH + UNIT_STRENGTH) < UNIT_STRENGTH) then {
						_unit_count = _unit_count - 1;
					} else {
						_other_unit_count = _other_unit_count - 1;
					};
				} else {
					if(random (UNIT_STRENGTH + VEHICLE_STRENGTH) < VEHICLE_STRENGTH) then {
						_unit_count = _unit_count - 1;
					} else {
						_other_veh_count = _other_veh_count - 1;
					};
				};
			} else  {
				if(random (VEHICLE_STRENGTH + UNIT_STRENGTH) < UNIT_STRENGTH) then {
					_veh_count = _veh_count - 1;
				} else {
					_other_unit_count = _other_unit_count - 1;
				};
			} else {
				if(random (VEHICLE_STRENGTH + VEHICLE_STRENGTH) < VEHICLE_STRENGTH) then {
					_veh_count = _veh_count - 1;
				} else {
					_other_veh_count = _other_veh_count - 1;
				};
			};
		};

		T_SETV("unit_count", _unit_count);
		T_SETV("veh_count", _veh_count);
		SETV(_other, "unit_count", _other_unit_count);
		SETV(_other, "veh_count", _other_veh_count);

		// Set combat flag
		T_SETV("in_combat", true);
	} ENDMETHOD;
ENDCLASS;

CLASS("Action", "")
	METHOD("new") {
		params [P_THISOBJECT];
		
	} ENDMETHOD;

	METHOD("getScore") {
		params [P_THISOBJECT];
	} ENDMETHOD;
ENDCLASS;

CLASS("AttackAction", "")
	VARIABLE("our_garr");
	VARIABLE("their_garr");

	METHOD("new") {
		params [P_THISOBJECT, P_OBJECT("_our_garr"), P_OBJECT("_their_garr")];

		T_SETV("our_garr", _our_garr);
		T_SETV("their_garr", _their_garr);
	} ENDMETHOD;

	METHOD("getScore") {
		params [P_THISOBJECT];
		T_PRVAR(our_garr);
		T_PRVAR(their_garr);
		// TODO actual score
		2
	} ENDMETHOD;
ENDCLASS;

CLASS("ReinforceAction", "")
	VARIABLE("our_garr");
	VARIABLE("their_garr");

	METHOD("new") {
		params [P_THISOBJECT, P_OBJECT("_our_garr"), P_OBJECT("_their_garr")];

		T_SETV("our_garr", _our_garr);
		T_SETV("their_garr", _their_garr);
	} ENDMETHOD;

	METHOD("updateScore") {
		params [P_THISOBJECT];
		T_PRVAR(our_garr);
		T_PRVAR(their_garr);
		// TODO actual score
		1
	} ENDMETHOD;

	METHOD("getScore") {
		params [P_THISOBJECT];
		T_PRVAR(our_garr);
		T_PRVAR(their_garr);
		// TODO actual score
		1
	} ENDMETHOD;
ENDCLASS;

// Commander planning AI
CLASS("Cmdr", "")
	VARIABLE("cmdr_side");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_cmdr_side")];
		T_SETV("cmdr_side", _cmdr_side)
		
	} ENDMETHOD;

	METHOD("generateAttackActions") {
		params [P_THISOBJECT];

		T_PRVAR(cmdr_side);
		private _enemy_garrisons = garrisons select { CALLM0(_x, "getSide") != _cmdr_side };
		private _our_garrisons = garrisons select { CALLM0(_x, "getSide") == _cmdr_side };

		private _actions = [];
		{
			private _enemy_garr = _x;
			{
				private _params = [_x, _enemy_garr];
				_actions pushBack NEW("AttackAction", _params);
			} forEach (_our_garrisons select { CALLM0(_x, "getStrength") > CALLM0(_enemy_garr, "getStrength") });
		} forEach _enemy_garrisons;

		_actions
	} ENDMETHOD;

	METHOD("generateReinforceActions") {
		params [P_THISOBJECT];

		T_PRVAR(cmdr_side);
		private _our_garrisons = garrisons select { CALLM0(_x, "getSide") == _cmdr_side };

		private _actions = [];
		{
			private _garr_a = _x;
			{
				private _params = [_garr_a, _x];
				_actions pushBack NEW("ReinforceAction", _params);
			} forEach (_our_garrisons - [_garr_a]);
		} forEach _our_garrisons;

		_actions
	} ENDMETHOD;

	METHOD("generateRoadblockActions") {
		params [P_THISOBJECT];

		T_PRVAR(cmdr_side);
		private _our_garrisons = garrisons select { CALLM0(_x, "getSide") == _cmdr_side };

		private _actions = [];
		// {
		// 	private _garr_a = _x;
		// 	{
		// 		private _params = [_garr_a, _x];
		// 		_actions pushBack NEW("ReinforceAction", _params);
		// 	} forEach (_our_garrisons - [_garr_a]);
		// } forEach _our_garrisons;

		_actions
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT];

		// Generate actions
		private _allActions = T_CALLM0("generateAttackActions") + T_CALLM0("generateReinforceActions") + T_CALLM0("generateRoadblockActions");

		// Generate a plan
		private _plan = [];
		private _lastPlanSize = -1;
		while { _lastPlanSize != count _plan && count _allActions > 0} do {
			_lastPlanSize = count _plan;

			{
				CALLM0(_x, "updateScore");
			} forEach _allActions;

			_allActions = [_allActions, [], { CALLM0(_x, "getScore") }, "DECEND"] call BIS_fnc_sortBy;
			_plan pushBack (_allActions deleteAt 0);
		};

	} ENDMETHOD;

ENDCLASS;

OOP_INFO_0("Processing markers...");

// find all intesting markers
garrisons = [allMapMarkers select { markerType _x == type_garrison }] apply { 
	private _mkr = [_x];
	NEW("Garrison", _mkr)
};
outposts = allMapMarkers select { markerType _x == type_outpost };
private _garrisonedOutposts = outposts select { count (markerText _x) > 0 };
garrisons = garrisons + (_garrisonedOutposts apply {
	private _outpostMkr = _x;
	private _newGarrMkr = createMarker [ _outpostMkr + "_garr", markerPos _outpostMkr ];
	OOP_INFO_2("Adding garrison %1 for outpost %2...", _newGarrMkr, _outpostMkr);
	_newGarrMkr setMarkerShape "ICON";
	_newGarrMkr setMarkerType type_garrison;
	_newGarrMkr setMarkerColor (markerColor _outpostMkr);
	_newGarrMkr setMarkerText (markerText _outpostMkr);
	_outpostMkr setMarkerText "";
	NEW("Garrison", [_newGarrMkr])
});

OOP_INFO_2("Found %1 garrisons and %2 outposts...", count garrisons, count outposts);

OpforCommander = NEW("Cmdr", [side_opf]);

#define PLAN_INTERVAL 30

OOP_INFO_0("Spawning AI thread...");
[] spawn {
	private _itr = 0;
	while {true} do {
		if(_itr == PLAN_INTERVAL) then {
			// Update commander AIs
			CALLM0(OpforCommander, "update");
			_itr = 0;
		};

		// Update garrisons
		{
			CALLM0(_x, "update");
		} forEach garrisons;

		// Perform combat
		private _calcedGarrisons = [];
		{
			private _curr = _x;
			if !(_x in _calcedGarrisons) then {
				_calcedGarrisons pushBack _x;
				private _otherGarrisons = (garrisons - [_calcedGarrisons]) select { (CALLM0(_curr, "getPos") distance CALLM0(_x, "getPos")) < 500 };
				{
					CALLM1(_curr, "fight_update", _x);
				} forEach _otherGarrisons;
				_calcedGarrisons = _calcedGarrisons + _otherGarrisons;
			};
		} forEach garrisons;

		sleep 0.1;
		_itr = _itr + 1;
	};
};
