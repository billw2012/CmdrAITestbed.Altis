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
		T_SETV("activeActions", []);
	} ENDMETHOD;

	fn_isValidAttackSource = {
		!CALLM0(_this, "isDead") and CALLM0(_this, "getSide") == _cmdrSide
	};

	fn_isValidAttackTarget = {
		!CALLM0(_this, "isDead") and CALLM0(_this, "getSide") != _cmdrSide
	};

	METHOD("generateAttackActions") {
		params [P_THISOBJECT, P_STRING("_state")];

		private _garrisons = GETV(_state, "garrisons");

		T_PRVAR(cmdrSide);

		private _actions = [];

		for "_i" from 0 to count _garrisons - 1 do {
			private _enemyGarr = _garrisons select _i;
			if(_enemyGarr call fn_isValidAttackTarget) then {
				for "_j" from 0 to count _garrisons - 1 do {
					private _ourGarr = _garrisons select _j;
					if((_ourGarr call fn_isValidAttackSource) and (CALLM0(_ourGarr, "getStrength") > CALLM0(_enemyGarr, "getStrength"))) then {
						private _params = [_j, _i];
						_actions pushBack (NEW("AttackAction", _params));
					};
				};
			};
		};

		_actions
	} ENDMETHOD;

	fn_isValidReinfGarr = {
		if(CALLM0(_this, "isDead") or (CALLM0(_this, "getSide") != _cmdrSide)) exitWith { false };
		private _action = GETV(_this, "currAction");
		if(!(_action isEqualType "")) exitWith { true };

		OBJECT_PARENT_CLASS_STR(_action) != "ReinforceAction"
	};

	METHOD("generateReinforceActions") {
		params [P_THISOBJECT, P_STRING("_state")];

		private _garrisons = GETV(_state, "garrisons");

		T_PRVAR(cmdrSide);
		private _ourGarrisons = _garrisons select { CALLM0(_x, "getSide") == _cmdrSide };

		private _actions = [];
		for "_i" from 0 to count _garrisons - 1 do {
			private _srcGarr = _garrisons select _i;
			if(_srcGarr call fn_isValidReinfGarr) then {
				for "_j" from 0 to count _garrisons - 1 do {
					private _tgtGarr = _garrisons select _j;
					if((_i != _j) and (_tgtGarr call fn_isValidReinfGarr)) then {
						private _params = [_i, _j];
						_actions pushBack (NEW("ReinforceAction", _params));
					};
				};
			};
		};

		_actions
	} ENDMETHOD;

	METHOD("generateRoadblockActions") {
		params [P_THISOBJECT, P_STRING("_state")];

		private _garrisons = GETV(_state, "garrisons");

		T_PRVAR(cmdrSide);
		private _actions = [];

		_actions
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];

		T_PRVAR(activeActions);

		// Copy state to simstate
		private _simState = CALLM0(_state, "simCopy");

		// Generate possible actions
		private _newActions = T_CALLM1("generateAttackActions", _simState) + T_CALLM1("generateReinforceActions", _simState) + T_CALLM1("generateRoadblockActions", _simState);

		// Apply active actions to the simstate
		{
			CALLM1(_x, "applyToSim", _simState);
		} forEach _activeActions;

		// Create any new actions
		while { count _newActions > 0 } do {
			{
				CALLM1(_x, "updateScore", _simState);
			} forEach _newActions;

			_newActions = [_newActions, [], { CALLM0(_x, "getFinalScore") }, "DECEND"] call BIS_fnc_sortBy;

			private _bestAction = _newActions deleteAt 0;
			private _bestActionScore = CALLM0(_bestAction, "getFinalScore");

			if(_bestActionScore <= 0.001) exitWith {};

			REF(_bestAction);
			_activeActions pushBack _bestAction;

			// Apply new action to simstate
			CALLM1(_bestAction, "applyToSim", _simState);
		};

		// Delete any remaining actions
		{
			DELETE(_x);
		} forEach _newActions;

		// Update actions in real state
		{ CALLM1(_x, "update", _state) } forEach _activeActions;

		// Remove complete actions
		private _completeActions = _activeActions select { GETV(_x, "complete") };

		// Unref completed actions
		{
			UNREF(_x);
		} forEach _completeActions;

		_activeActions = _activeActions - _completeActions;

		T_SETV("activeActions", _activeActions);
	} ENDMETHOD;

ENDCLASS;
