#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

// TODO: refactor to a proper state machine of some kind?
// 
CLASS("AttackAction", "Action")
	VARIABLE("ourGarrId");
	VARIABLE("theirGarrId");
	VARIABLE("splitGarrId");
	VARIABLE("stage");

	METHOD("new") {
		params [P_THISOBJECT, P_NUMBER("_ourGarrId"), P_NUMBER("_theirGarrId")];
		OOP_INFO_2("New AttackAction created %1->%2", _ourGarrId, _theirGarrId);
		T_SETV("ourGarrId", _ourGarrId);
		T_SETV("theirGarrId", _theirGarrId);
		T_SETV("splitGarrId", -1);
		T_SETV("stage", "new");
	} ENDMETHOD;

	METHOD("updateScore") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(theirGarrId);

		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _theirGarr = CALLM1(_state, "getGarrisonById", _theirGarrId);

		// Threat is just their strength scaled somewhat
		// TODO: is scaling here necessary? should we apply a non-linear function?
		private _scoreThreat = CALLM0(_theirGarr, "getStrength") * 0.1;

		// Resource is how much our garrison is *over* (required composition + required force), scaled by distance (further is lower)
		private _ourGarrOverComp = CALLM1(_state, "getOverDesiredComp", _ourGarr);
		// Enemy garrison composition
		private _theirComp = CALLM1(_theirGarr, "getComp");
		// How much over (required composition + required force) our garrison is
		private _ourGarrOverForceComp = [
			(_ourGarrOverComp select 0) - (_theirComp select 0),
			(_ourGarrOverComp select 1) - (_theirComp select 1)
		];

		// TODO: refactor out compositions and strength calculations to a utility class
		// Base resource score is based on over forcein fa
		private _scoreResource =
			// units
			(0 max (_ourGarrOverForceComp select 0)) * UNIT_STRENGTH +
			// vehicles
			(0 max (_ourGarrOverForceComp select 1)) * VEHICLE_STRENGTH;

		private _ourGarrPos = CALLM0(_ourGarr, "getPos");
		private _theirGarrPos = CALLM0(_theirGarr, "getPos");

		private _distCoeff = CALLSM2("ReinforceAction", "calcDistanceFalloff", _ourGarrPos, _theirGarrPos);

		// Scale base score by distance coefficient
		_scoreResource = _scoreResource * _distCoeff;

		T_SETV("scoreThreat", _scoreThreat);
		T_SETV("scoreResource", _scoreResource);
	} ENDMETHOD;

	METHOD("applyToSim") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(theirGarrId);
		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _theirGarr = CALLM1(_state, "getGarrisonById", _theirGarrId);

		T_PRVAR(stage);
		
		private _sentComp = [];
		// If we didn't start the action yet then we need to subtract from srcGarr
		if(_stage == "new") then {
			_sentComp = T_CALLM1("getReinfComp", _state);
			private _negSentComp = _sentComp apply { _x * -1 };
			CALLM1(_srcGarr, "modComp", _negSentComp);
			// Add to tgtGarr
			CALLM1(_tgtGarr, "modComp", _sentComp);
		} else {
			T_PRVAR(splitGarrId);

			private _splitGarr = CALLM1(_state, "getGarrisonById", _splitGarrId);
			CALLM1(_tgtGarr, "mergeGarrison", _splitGarr);
			//_sentComp = CALLM0(_splitGarr, "getComp");
			//T_GETV("sentComp");
		};
		while { !CALLM0(_ourGarr, "isDead") and !CALLM0(_theirGarr, "isDead") } do {
			CALLM1(_ourGarr, "fightUpdate", _theirGarr);
		};

	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(theirGarrId);
		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _theirGarr = CALLM1(_state, "getGarrisonById", _theirGarrId);

		// TODO: more interesting behaviour.
		// State machine/steps:
		//   Split garrison at the start and only send what is needed.
		//   Send to last known location.
		//   Once there investigate.
		//   Respond to updated position of target, or abort and come home if we can't find them.

		// If we are dead or the enemy are then this action is complete.
		// TODO: use actual intel to determine if/when target is dead.
		if(CALLM0(_ourGarr, "isDead")) exitWith {
			T_SETV("complete", true);
			OOP_INFO_2("AttackAction %1->%2 completed: %1 died", _ourGarrId, _theirGarrId);
		};

		if(CALLM0(_theirGarr, "isDead")) exitWith {
			T_SETV("complete", true);
			OOP_INFO_2("AttackAction %1->%2 completed: %2 died", _ourGarrId, _theirGarrId);
		};

		// For now just add move orders to target until we catch them, they die or we die.
		if(CALLM0(_ourGarr, "isOrderComplete")) then {
			OOP_INFO_2("AttackAction %1->%2 updating move order of %1", _ourGarrId, _theirGarrId);

			// Give our garrison move order to target garrison position
			SETV(_ourGarr, "currAction", _thisObject);

			private _targetPos = CALLM0(_theirGarr, "getPos");
			private _args = [format ["%1 attacking %2", _ourGarrId, _targetPos], _ourGarrId, _targetPos];
			private _moveOrder = NEW("MoveOrder", _args);
			CALLM1(_ourGarr, "giveOrder", _moveOrder);
		};

	} ENDMETHOD;
ENDCLASS;
