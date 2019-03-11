#include "OOP_Light/OOP_Light.h"

call compile preprocessFileLineNumbers "OOP_Light/OOP_Light_init.sqf";

// modules = [];

// player addAction ["Recompile",
// {
// 	{
// 		_x params ["_delete", "_source_file"];

// 	} forEach modules;
// }];

side_ofp = "colorOPFOR";
side_blu = "colorBLUFOR";
side_no = "ColorYellow";

type_outpost = "hd_flag";
type_garrison = "mil_box";

// /* Outpost:
// */
// fn_init_outpost = {
// 	params ["_marker"];
// 	[]
// };
// /* Garrison:
// order: array of order specific stuff
// */
// fn_init_garrison = {
// 	params ["_marker"];
// 	[
// 	]
// };

order_types = [];

/* Garrison:

marker: marker name
location: 2D position
side: opf/gref/none (color name)
units: number
vehicles: number
order: array of order specific data

*/
CLASS("Order", "")
	VARIABLE("name");
	VARIABLE("complete");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_name")];
		T_SETV("name", _name);
		T_SETV("complete", false);
	} ENDMETHOD;
ENDCLASS;

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

CLASS("Garrison", "")
	VARIABLE("marker");
	VARIABLE("units");
	VARIABLE("vehicles");
	VARIABLE("order");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_marker")];
		T_SETV("marker", _marker);
		private _parts = (markerText _marker) splitString ", :;/";
		T_SETV("units", if(count _parts >= 1) then { parseNumber (_parts select 0) } else { 0 });
		T_SETV("vehicles", if(count _parts >= 2) then { parseNumber (_parts select 1) } else { 0 });
		T_SETV("order", objNull);
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
		T_PRVAR(units);
		T_PRVAR(vehicles);
		if(_units <= (_vehicles * UNITS_PER_VEHICLE)) then { VEHICLE_SPEED_MS } else { UNIT_SPEED_MS }
	} ENDMETHOD;
	
	METHOD("update") {
		params [P_THISOBJECT];
		T_PRVAR(marker);
		T_PRVAR(units);
		T_PRVAR(vehicles);
		_marker setMarkerText (format ["%1/%2", _units, _vehicles]);

		// TODO: update order here
	} ENDMETHOD;
	
ENDCLASS;

// find all intesting markers
garrisons = [allMapMarkers select { markerType _x == type_garrison }] apply { NEW("Garrison", [_x]) };
outposts = [allMapMarkers select { markerType _x == type_outpost }];

[] spawn {
	while {true} do {
		enemy_garrisons = garrisons select { _x };

		sleep 30;
	};
};