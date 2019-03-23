#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

// TODO: refactor out all the common stuff from this and TakeOutpostAction.
// Detachments, composition based scoring, state machine etc.
// Or factor out these into orders from which actions can be built? Hmmm

CLASS("ReinforceAction", "Action")
	VARIABLE("srcGarrId");
	VARIABLE("tgtGarrId");
	VARIABLE("detachedGarrId");
	VARIABLE("stage");

	METHOD("new") {
		params [P_THISOBJECT, P_NUMBER("_srcGarrId"), P_NUMBER("_tgtGarrId")];

		T_SETV("srcGarrId", _srcGarrId);
		T_SETV("tgtGarrId", _tgtGarrId);
		T_SETV("detachedGarrId", -1);
		T_SETV("stage", "new");
	} ENDMETHOD;

	METHOD("updateScore") {
		params [P_THISOBJECT, P_STRING("_state")];

		T_PRVAR(srcGarrId);
		T_PRVAR(tgtGarrId);

		private _srcGarr = CALLM1(_state, "getGarrisonById", _srcGarrId);
		private _tgtGarr = CALLM1(_state, "getGarrisonById", _tgtGarrId);

		// TODO:OPT cache these scores!
		private _scorePriority = CALLM1(_state, "getReinforceRequiredScore", _tgtGarr);

		// Resource is how much src is *over* composition, scaled by distance (further is lower)
		// i.e. How much units/vehicles src can spare.
		private _srcOverComp = CALLM1(_state, "getOverDesiredComp", _srcGarr);
		private _srcOverCompScore =
			// units
			(0 max _srcOverComp#0) * UNIT_STRENGTH +
			// vehicles
			(0 max _srcOverComp#1) * VEHICLE_STRENGTH;

		private _srcGarrPos = CALLM0(_srcGarr, "getPos");
		private _tgtGarrPos = CALLM0(_tgtGarr, "getPos");

		private _distCoeff = CALLSM2("Action", "calcDistanceFalloff", _srcGarrPos, _tgtGarrPos);

		private _scoreResource = _srcOverCompScore * _distCoeff;
		private _str = format ["%1->%2 _scorePriority = %3, _srcOverComp = %4, _srcOverCompScore = %5, _distCoeff = %6, _scoreResource = %7", _srcGarrId, _tgtGarrId, _scorePriority, _srcOverComp, _srcOverCompScore, _distCoeff, _scoreResource];
		OOP_INFO_0(_str);

		T_SETV("scorePriority", _scorePriority);
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
			_sentComp = T_CALLM1("getDetachmentComp", _state);
			private _negSentComp = _sentComp apply { _x * -1 };
			// Remove from source garrison
			CALLM1(_srcGarr, "modComp", _negSentComp);
			// Add to target garrison
			CALLM1(_tgtGarr, "modComp", _sentComp);
		} else {
			T_PRVAR(detachedGarrId);

			private _detachedGarr = CALLM1(_state, "getGarrisonById", _detachedGarrId);
			CALLM1(_tgtGarr, "mergeGarrison", _detachedGarr);
		};
	} ENDMETHOD;

	// Get composition of reinforcements we should send from src to tgt. 
	// This is the min of what src has spare and what tgt wants.
	METHOD("getDetachmentComp") {
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
			ceil (_srcOverComp#0 min _tgtUnderComp#0),
			ceil (_srcOverComp#1 min _tgtUnderComp#1)
		]
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];
		
		T_PRVAR(complete);
		if(_complete) exitWith { false };

		T_PRVAR(srcGarrId);
		T_PRVAR(tgtGarrId);

		private _srcGarr = CALLM1(_state, "getGarrisonById", _srcGarrId);
		private _tgtGarr = CALLM1(_state, "getGarrisonById", _tgtGarrId);

		T_PRVAR(stage);

		switch(_stage) do {
			case "new": {
				OOP_INFO_2("ReinforceAction %1->%2 starting", _srcGarrId, _tgtGarrId);

				// We only care about the source garrison being dead at this point, after this 
				// detachment has already left.
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

				// We didn't split the source garrison yet, so do it now.
				private _detachedComp = T_CALLM1("getDetachmentComp", _state);
				if(_detachedComp#0 == 0 and _detachedComp#1 == 0) exitWith {
					T_SETV("complete", true);
					OOP_INFO_2("ReinforceAction %1->%2 completed: detachment comp was empty", _srcGarrId, _tgtGarrId);
				};
				private _detachedGarr = CALLM1(_srcGarr, "splitGarrison", _detachedComp);
				private _detachedGarrId = CALLM1(_state, "addGarrison", _detachedGarr);
				T_SETV("detachedGarrId", _detachedGarrId);

				// Assign action to the detached garrison.
				SETV_REF(_detachedGarr, "currAction", _thisObject);

				// Next stage
				T_SETV("stage", "moving");

				OOP_INFO_4("ReinforceAction %1->%2 sending %3 %4", _srcGarrId, _tgtGarrId, _detachedGarrId, _detachedComp);
			};
			case "moving": {
				T_PRVAR(detachedGarrId);

				private _detachedGarr = CALLM1(_state, "getGarrisonById", _detachedGarrId);
				private _detachedPos = CALLM0(_detachedGarr, "getPos");
				OOP_INFO_4("ReinforceAction %1->%3->%2 pos: %4", _srcGarrId, _tgtGarrId, _detachedGarrId, _detachedPos);
				if(CALLM0(_detachedGarr, "isDead")) exitWith {
					T_SETV("complete", true);
					OOP_INFO_3("ReinforceAction %1->%3->%2 completed: %3 died", _srcGarrId, _tgtGarrId, _detachedGarrId);
				};

				// If target is dead then rtb
				if(CALLM0(_tgtGarr, "isDead")) exitWith {
					// TODO: What do if target garrison is dead? Should still go there probably?
					// Maybe fall back and wait? Return to origin?
					// Probably we want to abort this action and just let commander decide what to 
					// do with a floating free garrison.

					// RTB
					CALLM0(_detachedGarr, "cancelOrder");
					// Set target to source
					T_SETV("tgtGarrId", _srcGarrId);
					OOP_INFO_3("ReinforceAction %1->%3->%2 rtb: %2 already dead", _srcGarrId, _tgtGarrId, _detachedGarrId);
				};

				if(CALLM0(_detachedGarr, "isOrderComplete")) then {
					OOP_INFO_3("ReinforceAction %1->%3->%2 move order completed", _srcGarrId, _tgtGarrId, _detachedGarrId);
					
					private _targetPos = CALLM0(_tgtGarr, "getPos");
					private _dist = _detachedPos distance _targetPos;
					OOP_INFO_4("ReinforceAction %1->%3->%2 dist: %4", _srcGarrId, _tgtGarrId, _detachedGarrId, _dist);
					// If we reached the target then merge the garrisons
					if(_dist < 100) then {
						OOP_INFO_3("ReinforceAction %1->%3->%2 merging %3 to target", _srcGarrId, _tgtGarrId, _detachedGarrId);
						CALLM1(_tgtGarr, "mergeGarrison", _detachedGarr);
						T_SETV("complete", true);
					} else {
						OOP_INFO_3("ReinforceAction %1->%3->%2 moving %3 to target", _srcGarrId, _tgtGarrId, _detachedGarrId);

						// Give another move order as we didn't reach target yet.
						private _args = [ format["%1 reinforcing %2", _detachedGarrId, _tgtGarrId], _detachedGarrId, _targetPos];
						private _moveOrder = NEW("MoveOrder", _args);
						CALLM1(_detachedGarr, "giveOrder", _moveOrder);
					};
				};
			};
		};
	} ENDMETHOD;
ENDCLASS;
