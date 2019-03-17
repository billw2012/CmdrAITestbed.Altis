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
CALLM1(State, "initFromMarkers", allMapMarkers);

OpforCommander = NEW("Cmdr", [side_opf]);

#define PLAN_INTERVAL 30

OOP_INFO_0("Spawning AI thread...");
[] spawn {
	private _itr = 0;
	while {true} do {
		if(_itr == PLAN_INTERVAL) then {
			// Update commander AIs
			CALLM1(OpforCommander, "update", State);
			_itr = 0;
		};

		CALLM0(State, "update");

		sleep 0.1;
		_itr = _itr + 1;
	};
};
