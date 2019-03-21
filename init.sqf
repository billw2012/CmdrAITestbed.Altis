#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "OOP_Light\OOP_Light.h"

// #define LOG_SCOPE "Main"

call compile preprocessFileLineNumbers "OOP_Light\OOP_Light_init.sqf";

side_opf = "ColorEAST";
side_guer = "ColorGUER";
side_none = "ColorYellow";

type_outpost = "mil_flag";
type_garrison = "mil_box";

order_types = [];

call compile preprocessFileLineNumbers "Scripts\Garrison.sqf";
call compile preprocessFileLineNumbers "Scripts\Orders.sqf";
call compile preprocessFileLineNumbers "Scripts\Action.sqf";
call compile preprocessFileLineNumbers "Scripts\AttackAction.sqf";
call compile preprocessFileLineNumbers "Scripts\ReinforceAction.sqf";
call compile preprocessFileLineNumbers "Scripts\State.sqf";
call compile preprocessFileLineNumbers "Scripts\Cmdr.sqf";

OOP_INFO_0("Initializing state...");
State = NEW("State", []);

testing = false;
if (testing) then {
	private _newMarker = createMarker ["us", [0, 0, 0]];
	OOP_INFO_1("_newMarker %1", _newMarker);
	_newMarker setMarkerType type_outpost;
	_newMarker setMarkerShape "ICON";
	_newMarker setMarkerColor side_opf;
	_newMarker setMarkerText "10/4";
	private _newMarker2 = createMarker ["them", [2000, 0, 0]];
	_newMarker2 setMarkerType type_outpost;
	_newMarker2 setMarkerShape "ICON";
	_newMarker2 setMarkerColor side_guer;
	_newMarker2 setMarkerText "4/2";
};
CALLM1(State, "initFromMarkers", allMapMarkers);

OpforCommander = NEW("Cmdr", [side_opf]);

#define PLAN_INTERVAL 30

OOP_INFO_0("Spawning AI thread...");
[] spawn {
	OOP_INFO_0("In AI thread...");
	private _itr = 0;
	while {true} do {
		if(_itr == PLAN_INTERVAL) then {
			OOP_INFO_0("Planning...");
			// Update commander AIs
			CALLM1(OpforCommander, "update", State);
			_itr = 0;
		};
		OOP_INFO_0("Updating state...");
		CALLM0(State, "update");

		sleep 0.1;
		_itr = _itr + 1;
	};
};
