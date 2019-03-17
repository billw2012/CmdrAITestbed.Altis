#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"


// Commander planning AI
CLASS("Cmdr", "")
	VARIABLE("cmdrSide");
	VARIABLE("activeActions");

	METHOD("new") {
		params [P_THISOBJECT, P_STRING("_cmdrSide")];
		T_SETV("cmdrSide", _cmdrSide);
	} ENDMETHOD;

	METHOD("generateAttackActions") {
		params [P_THISOBJECT, P_STRING("state")];

		private _garrisons = GETV(_state, "garrisons");

		T_PRVAR(cmdrSide);

		private _actions = [];

		for "_i" from 0 to count _garrisons - 1 do {
			private _enemyGarr = _garrisons select _i;
			if(CALLM0(_enemyGarr, "getSide") != _cmdrSide) then {
				for "_j" from 0 to count _garrisons - 1 do {
					private _ourGarr = _garrisons select _j;
					if((CALLM0(_ourGarr, "getSide") == _cmdrSide) and (CALLM0(_ourGarr, "getStrength") > CALLM0(_enemyGarr, "getStrength"))) then {
						private _params = [_j, _i];
						_actions pushBack (NEW("AttackAction", _params));
					};
				};
			};
		};

		_actions
	} ENDMETHOD;

	METHOD("generateReinforceActions") {
		params [P_THISOBJECT, P_STRING("state")];

		private _garrisons = GETV(_state, "garrisons");

		T_PRVAR(cmdrSide);
		private _ourGarrisons = _garrisons select { CALLM0(_x, "getSide") == _cmdrSide };

		private _actions = [];
		for "_i" from 0 to count _garrisons - 1 do {
			for "_j" from 0 to count _garrisons - 1 do {
				if(_i != _j) then {
					private _params = [_i, _j];
					_actions pushBack (NEW("ReinforceAction", _params));
				};
			};
		};

		_actions
	} ENDMETHOD;

	METHOD("generateRoadblockActions") {
		params [P_THISOBJECT, P_STRING("state")];

		private _garrisons = GETV(_state, "garrisons");

		T_PRVAR(cmdrSide);
		private _actions = [];

		_actions
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("state")];

		// Copy state to simstate
		private _simState = CALLM0(_state, "copySim");

		// Generate possible actions
		private _allActions = T_CALLM1("generateAttackActions", _simState) + T_CALLM1("generateReinforceActions", _simState) + T_CALLM1("generateRoadblockActions", _simState);

		// Apply active actions to the simstate
		CALLM0(_simState, "applyActiveActions");

		// Generate a plan
		private _plan = [];
		while { count _allActions > 0 } do {
			{
				CALLM1(_x, "updateScore", _simState);
			} forEach _allActions;

			_allActions = [_allActions, [], { CALLM0(_x, "getFinalScore") }, "DECEND"] call BIS_fnc_sortBy;
			private _bestAction = _allActions deleteAt 0;
			_plan pushBack _bestAction;

			// Apply new action to simstate
			CALLM1(_bestAction, "applyInstant", _simState);
		};

	} ENDMETHOD;

ENDCLASS;
