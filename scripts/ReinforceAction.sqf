#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

CLASS("ReinforceAction", "Action")
	VARIABLE("srcGarrId");
	VARIABLE("tgtGarrId");
	VARIABLE("splitGarrId");
	VARIABLE("stage");

	METHOD("new") {
		params [P_THISOBJECT, P_NUMBER("_srcGarrId"), P_NUMBER("_tgtGarrId")];
		OOP_INFO_2("New ReinforceAction created %1->%2", _srcGarrId, _tgtGarrId);
		T_SETV("srcGarrId", _srcGarrId);
		T_SETV("tgtGarrId", _tgtGarrId);
		T_SETV("splitGarrId", -1);
		T_SETV("stage", "new");
	} ENDMETHOD;

	METHOD("updateScore") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(srcGarrId);
		T_PRVAR(tgtGarrId);
		private _srcGarr = CALLM1(_state, "getGarrisonById", _srcGarrId);
		private _tgtGarr = CALLM1(_state, "getGarrisonById", _tgtGarrId);

		// Threat is how much tgt is *under* composition (so over comp * -1).
		// i.e. How much units/vehicles tgt needs.
		private _tgtOverComp = CALLM1(_state, "getOverDesiredComp", _tgtGarr);
		private _scoreThreat = 
			// units
			(0 max ((_tgtOverComp select 0) * -1)) * UNIT_STRENGTH +
			// vehicles
			(0 max ((_tgtOverComp select 1) * -1)) * VEHICLE_STRENGTH;

		// Resource is how much src is *over* composition, scaled by distance (further is lower)
		// i.e. How much units/vehicles src can spare.
		private _srcOverComp = CALLM1(_state, "getOverDesiredComp", _srcGarr);
		private _scoreResource =
			// units
			(0 max (_srcOverComp select 0)) * UNIT_STRENGTH +
			// vehicles
			(0 max (_srcOverComp select 1)) * VEHICLE_STRENGTH;
		private _srcGarrPos = CALLM0(_srcGarr, "getPos");
		private _tgtGarrPos = CALLM0(_tgtGarr, "getPos");

		private _distCoeff = CALLSM2("ReinforceAction", "calcDistanceFalloff", _srcGarrPos, _tgtGarrPos);

		_scoreResource = _scoreResource * _distCoeff;

		T_SETV("scoreThreat", _scoreThreat);
		T_SETV("scoreResource", _scoreResource);
	} ENDMETHOD;
	
	METHOD("applyToSim") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(srcGarrId);
		T_PRVAR(tgtGarrId);
		private _srcGarr = CALLM1(_state, "getGarrisonById", _srcGarrId);
		private _tgtGarr = CALLM1(_state, "getGarrisonById", _tgtGarrId);

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
	} ENDMETHOD;

	// Get composition of reinforcements we should send from src to tgt. 
	// This is the min of what src has spare and what tgt wants.
	METHOD("getReinfComp") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(srcGarrId);
		T_PRVAR(tgtGarrId);

		private _srcGarr = CALLM1(_state, "getGarrisonById", _srcGarrId);
		private _tgtGarr = CALLM1(_state, "getGarrisonById", _tgtGarrId);

		// How much resources tgt needs
		private _tgtUnderComp = CALLM1(_state, "getOverDesiredComp", _tgtGarr) apply { 0 max (_x * -1) };
		// How much resources src can spare.
		private _srcOverComp = CALLM1(_state, "getOverDesiredComp", _srcGarr) apply { 0 max _x };

		// Min of those values
		// TODO: make this a "nice" composition. We don't want to send a bunch of guys to walk or whatever.
		[
			(_srcOverComp select 0) min (_tgtUnderComp select 0),
			(_srcOverComp select 1) min (_tgtUnderComp select 1)
		]
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];
		
		T_PRVAR(complete);
		if(_complete) exitWith { false };

		T_PRVAR(srcGarrId);
		T_PRVAR(tgtGarrId);
		T_PRVAR(splitGarrId);

		private _srcGarr = CALLM1(_state, "getGarrisonById", _srcGarrId);
		private _tgtGarr = CALLM1(_state, "getGarrisonById", _tgtGarrId);

		// If we are dead or the enemy are then this action is complete.
		// TODO: use actual intel to determine if/when target is dead.
		if(CALLM0(_srcGarr, "isDead")) exitWith {
			T_SETV("complete", true);
			OOP_INFO_2("ReinforceAction %1->%2 completed: %1 died", _srcGarrId, _tgtGarrId);
		};

		if(CALLM0(_tgtGarr, "isDead")) exitWith {
			// TODO: What do if target garrison is dead? Should still go there probably?
			// Maybe fall back and wait? Return to origin?
			// Probably we want to abort this action and just let commander decide what to 
			// do with a floating free garrison.
			T_SETV("complete", true);
			OOP_INFO_2("ReinforceAction %1->%2 completed: %2 died", _srcGarrId, _tgtGarrId);
		};

		T_PRVAR(stage);

		switch(_stage) do {
			case "new": {
				OOP_INFO_2("ReinforceAction %1->%2 starting", _srcGarrId, _tgtGarrId);

				// We didn't split the source garrison yet, so do it now.
				private _splitComp = T_CALLM1("getReinfComp", _state);
				private _splitGarr = CALLM1(_srcGarr, "splitGarrison", _splitComp);
				_splitGarrId = CALLM1(_state, "addGarrison", _splitGarr);
				T_SETV("splitGarrId", _splitGarrId);

				// Assign action to the split garrison.
				SETV(_splitGarr, "currAction", _thisObject);

				// Next stage
				T_SETV("stage", "moving");

				OOP_INFO_4("ReinforceAction %1->%2 sending %3 %4", _srcGarrId, _tgtGarrId, _splitGarrId, _splitComp);
			};
			case "moving": {
				private _splitGarr = CALLM1(_state, "getGarrisonById", _splitGarrId);				
				private _splitPos = CALLM0(_splitGarr, "getPos");
				OOP_INFO_4("ReinforceAction %1->%3->%2 pos: %4", _srcGarrId, _tgtGarrId, _splitGarrId, _splitPos);
				if(CALLM0(_splitGarr, "isDead")) exitWith {
					T_SETV("complete", true);
					OOP_INFO_3("ReinforceAction %1->%3->%2 completed: %3 died", _srcGarrId, _tgtGarrId, _splitGarrId);
				};
				if(CALLM0(_splitGarr, "isOrderComplete")) then {
					OOP_INFO_3("ReinforceAction %1->%3->%2 move order completed", _srcGarrId, _tgtGarrId, _splitGarrId);
					
					private _targetPos = CALLM0(_tgtGarr, "getPos");
					private _dist = _splitPos distance _targetPos;
					OOP_INFO_4("ReinforceAction %1->%3->%2 dist: %4", _srcGarrId, _tgtGarrId, _splitGarrId, _dist);
					// If we reached the target then merge the garrisons
					if(_dist < 100) then {
						OOP_INFO_3("ReinforceAction %1->%3->%2 merging %3 to target", _srcGarrId, _tgtGarrId, _splitGarrId);
						CALLM1(_tgtGarr, "mergeGarrison", _splitGarr);
						T_SETV("complete", true);
					} else {
						OOP_INFO_3("ReinforceAction %1->%3->%2 moving %3 to target", _srcGarrId, _tgtGarrId, _splitGarrId);

						// Give another move order as we didn't reach target yet.
						private _args = [ format["%1 reinforcing %2", _splitGarrId, _tgtGarrId], _splitGarrId, _targetPos];
						private _moveOrder = NEW("MoveOrder", _args);
						CALLM1(_splitGarr, "giveOrder", _moveOrder);
					};
				};
			};
		};
	} ENDMETHOD;
ENDCLASS;
