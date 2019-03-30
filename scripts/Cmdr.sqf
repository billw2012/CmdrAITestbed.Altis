#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR
#define OOP_PROFILE

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

	// METHOD("isValidAttackTarget") {
	// 	params [P_THISOBJECT, P_STRING("_garrison")];
	// 	T_PRVAR(cmdrSide);
	// 	!CALLM0(_garrison, "isDead") and CALLM0(_garrison, "getSide") != _cmdrSide
	// } ENDMETHOD;

	// METHOD("isValidAttackSource") {
	// 	params [P_THISOBJECT, P_STRING("_garrison")];
	// 	T_PRVAR(cmdrSide);
	// 	!CALLM0(_garrison, "isDead") and CALLM0(_garrison, "getSide") == _cmdrSide
	// } ENDMETHOD;

	// METHOD("isValidTakeOutpostTarget") {
	// 	params [P_THISOBJECT, P_STRING("_outpost")];
	// 	T_PRVAR(cmdrSide);
	// 	CALLM0(_outpost, "getSide") != _cmdrSide
	// } ENDMETHOD;
	
	// fn_isValidAttackTarget = {
	// 	!CALLM0(_this, "isDead") and CALLM0(_this, "getSide") != _cmdrSide
	// };

	// fn_isValidAttackSource = {
	// 	!CALLM0(_this, "isDead") and CALLM0(_this, "getSide") == _cmdrSide
	// };

	// fn_isValidOutpostTarget = {
	// 	CALLM0(_this, "getSide") != _cmdrSide
	// };

	METHOD("generateTakeOutpostActions") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(activeActions);
		T_PRVAR(cmdrSide);

		// Garrison must be alive
		private _garrisons = CALLM0(_state, "getAliveGarrisons") select { 
			// Must be on our side
			(CALLM0(_x, "getSide") == _cmdrSide) and 
			// Must have at least a minimum strength
			{CALLM0(_x, "getStrength") > 10} and 
			// Must not be engaged in another action
			{ ! (GETV(_x, "currAction") isEqualType "") }
		};

		private _outposts = GETV(_state, "outposts") select {
			private _outpost = _x;
			// Only try to take empty or enemy outposts
			CALLM0(_outpost, "getSide") != _cmdrSide and
			// Don't make duplicate take actions for the same outpost
			_activeActions findIf { 
				OBJECT_PARENT_CLASS_STR(_x) == "TakeOutpostAction" and 
				{ GETV(_x, "targetOutpostId") == GETV(_outpost, "id") }
			} == -1
		};

		private _actions = [];
		{
			private _garrisonId = GETV(_x, "id");
			{
				private _outpostId = GETV(_x, "id");
				private _params = [_garrisonId, GETV(_x, "id")];
				_actions pushBack NEW("TakeOutpostAction", _params);
			} forEach _outposts;
		} forEach _garrisons;

		_actions
	} ENDMETHOD;

	METHOD("generateAttackActions") {
		params [P_THISOBJECT, P_STRING("_state")];

		private _garrisons = GETV(_state, "garrisons");

		T_PRVAR(cmdrSide);

		private _actions = [];

		// for "_i" from 0 to count _garrisons - 1 do {
		// 	private _enemyGarr = _garrisons select _i;
		// 	if(_enemyGarr call fn_isValidAttackTarget) then {
		// 		for "_j" from 0 to count _garrisons - 1 do {
		// 			private _ourGarr = _garrisons select _j;
		// 			if((_ourGarr call fn_isValidAttackSource) and (CALLM0(_ourGarr, "getStrength") > CALLM0(_enemyGarr, "getStrength"))) then {
		// 				private _params = [_j, _i];
		// 				_actions pushBack (NEW("AttackAction", _params));
		// 			};
		// 		};
		// 	};
		// };

		_actions
	} ENDMETHOD;

	// fn_isValidReinfGarr = {
	// 	if(CALLM0(_this, "isDead") or (CALLM0(_this, "getSide") != _cmdrSide)) exitWith { false };
	// 	private _action = GETV(_this, "currAction");
	// 	if(!(_action isEqualType "")) exitWith { true };

	// 	OBJECT_PARENT_CLASS_STR(_action) != "ReinforceAction"
	// };

	METHOD("generateReinforceActions") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(cmdrSide);

		private _ourGarrisons = CALLM0(_state, "getAliveGarrisons") select { 
			// Must be on our side
			CALLM0(_x, "getSide") == _cmdrSide and 
			// Not involved in another reinforce action
			{
				private _action = GETV(_x, "currAction");
				!(_action isEqualType "") or { OBJECT_PARENT_CLASS_STR(_action) != "ReinforceAction" }
			}
		};

		T_PRVAR(cmdrSide);
		
		// Source garrisons must have a minimum strength
		private _srcGarrisons = _ourGarrisons select { 
			// Must have at least a minimum strength
			(CALLM0(_x, "getStrength") > 10) and 
			// Not involved in another action already
			{ !(GETV(_x, "currAction") isEqualType "") }
		};

		private _actions = [];
		{
			private _srcGarrison = _x;
			{
				private _tgtGarrison = _x;
				if(_srcGarrison != _tgtGarrison) then {
					private _params = [GETV(_srcGarrison, "id"), GETV(_tgtGarrison, "id")];
					_actions pushBack (NEW("ReinforceAction", _params));
				};
			} forEach _ourGarrisons;
		} forEach _srcGarrisons;

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

	METHOD("plan") {
		params [P_THISOBJECT, P_STRING("_state")];

		T_PRVAR(activeActions);

		OOP_DEBUG_0("Copying simstate ...");

		// Copy state to simstate
		private _simState = CALLM0(_state, "simCopy");

		OOP_DEBUG_0("Applying %1 active actions to simstate new actions ...");

		PROFILE_SCOPE_START(ApplyActive);
		// Apply active actions to the simstate
		{
			CALLM1(_x, "applyToSim", _simState);
		} forEach _activeActions;
		PROFILE_SCOPE_END(ApplyActive, 0.1);

		OOP_DEBUG_0("Generating new actions ...");

		PROFILE_SCOPE_START(GenerateActions);
		// Generate possible actions
		private _newActions = 
			  T_CALLM1("generateTakeOutpostActions", _simState) 
			//+ T_CALLM1("generateAttackActions", _simState) 
			+ T_CALLM1("generateReinforceActions", _simState) 
			//+ T_CALLM1("generateRoadblockActions", _simState)
			;
		PROFILE_SCOPE_END(GenerateActions, 0.1);

		PROFILE_SCOPE_START(PlanActions);
		// Plan new actions
		while { count _newActions > 0 } do {
			PROFILE_SCOPE_START(UpdateScores);
			{
				CALLM1(_x, "updateScore", _simState);
			} forEach _newActions;
			PROFILE_SCOPE_END(UpdateScores, 0.1);

			_newActions = [_newActions, [], { CALLM0(_x, "getFinalScore") }, "DECEND"] call BIS_fnc_sortBy;

			private _bestAction = _newActions deleteAt 0;
			private _bestActionScore = CALLM0(_bestAction, "getFinalScore");

			if(_bestActionScore <= 0.001) exitWith {};

			REF(_bestAction);
			_activeActions pushBack _bestAction;

			PROFILE_SCOPE_START(ApplyNewActionToSim);
			// Apply new action to simstate
			CALLM1(_bestAction, "applyToSim", _simState);
			PROFILE_SCOPE_END(ApplyNewActionToSim, 0.1);
		};
		PROFILE_SCOPE_END(PlanActions, 0.1);

		// Delete any remaining actions
		{
			DELETE(_x);
		} forEach _newActions;

		T_SETV("activeActions", _activeActions);
	} ENDMETHOD;

ENDCLASS;
