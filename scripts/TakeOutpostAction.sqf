#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

// TODO: refactor to a proper state machine of some kind?
// 
CLASS("TakeOutpostAction", "Action")
	VARIABLE("ourGarrId");
	VARIABLE("targetOutpostId");
	VARIABLE("detachedGarrId");
	VARIABLE("stage");

	METHOD("new") {
		params [P_THISOBJECT, P_NUMBER("_ourGarrId"), P_NUMBER("_targetOutpostId")];
		T_SETV("ourGarrId", _ourGarrId);
		T_SETV("targetOutpostId", _targetOutpostId);
		T_SETV("detachedGarrId", -1);
		T_SETV("stage", "new");
	} ENDMETHOD;

	METHOD("updateScore") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(targetOutpostId);

		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _targetOutpost = CALLM1(_state, "getOutpostById", _targetOutpostId);
		private _targetGarr = CALLM1(_state, "getAttachedGarrisonById", _targetOutpostId);

		// No particular priority here, could be weighted towards empty outposts?
		private _scorePriority = 1; //CALLM0(_targetGarr, "getStrength") * 0.1;

		// Resource is how much our garrison is *over* (required composition + required force), scaled by distance (further is lower)
		private _ourGarrOverComp = CALLM1(_state, "getOverDesiredComp", _ourGarr);
		// Enemy garrison composition
		private _targetComp = if(_targetGarr isEqualType "") then { CALLM0(_targetGarr, "getComp") } else { [0,0] };
		private _targetOutpostPos = CALLM0(_targetOutpost, "getPos");
		private _targetOutpostDesiredComp = CALLM1(_state, "getDesiredComp", _targetOutpostPos);

		_targetComp = [
			(_targetComp#0 * 1.5) max _targetOutpostDesiredComp#0,
			(_targetComp#1 * 1.5) max _targetOutpostDesiredComp#1
		];
		// How much over (required composition + required force) our garrison is
		private _ourGarrOverForceComp = [
			_ourGarrOverComp#0 - _targetComp#0,
			_ourGarrOverComp#1 - _targetComp#1
		];

		// TODO: refactor out compositions and strength calculations to a utility class
		// Base resource score is based on how much excess resource our garrison has.
		private _scoreResource =
			// units
			(0 max _ourGarrOverForceComp#0) * UNIT_STRENGTH +
			// vehicles
			(0 max _ourGarrOverForceComp#1) * VEHICLE_STRENGTH;

		private _ourGarrPos = CALLM0(_ourGarr, "getPos");

		private _distCoeff = CALLSM2("Action", "calcDistanceFalloff", _ourGarrPos, _targetOutpostPos);

		// Scale base score by distance coefficient
		_scoreResource = _scoreResource * _distCoeff;

		T_SETV("scorePriority", _scorePriority);
		T_SETV("scoreResource", _scoreResource);
	} ENDMETHOD;

	// Get composition of reinforcements we should send from src to tgt. 
	// This is the min of what src has spare and what tgt wants.
	METHOD("getDetachmentComp") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(targetOutpostId);

		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _ourComp = CALLM0(_ourGarr, "getComp");
		private _ourSide = CALLM0(_ourGarr, "getSide");

		private _targetOutpost = CALLM1(_state, "getOutpostById", _targetOutpostId);
		private _targetOutpostPos = CALLM0(_targetOutpost, "getPos");
		private _targetGarr = CALLM1(_state, "getAttachedGarrisonById", _targetOutpostId);

		// Enemy garrison composition (if they exist)
		private _targetComp = if(_targetGarr isEqualType "" and {CALLM0(_targetGarr, "getSide") != _ourSide}) then { CALLM0(_targetGarr, "getComp") } else { [0,0] };
		// What composition we want to end up with at the outpost (make sure we take at least this much units)
		private _targetOutpostDesiredComp = CALLM1(_state, "getDesiredComp", _targetOutpostPos);
		_targetComp = [
			(_targetComp#0 * 1.5) max _targetOutpostDesiredComp#0,
			(_targetComp#1 * 1.5) max _targetOutpostDesiredComp#1
		];

		// TODO: many things should be done to improve this (and associated scoring).
		// Just some:
		//   -- Make sure we take an appropriate combination of units/vehicles
		//   -- If attacking an entrenched position scale appropriately (at least 3 times defenders)
		//   -- If area or route is dangerous increase force

		// detach comp is min(ourComp, _targetComp)
		[
			round (_ourComp#0 min _targetComp#0),
			round (_ourComp#1 min _targetComp#1)
		]
	} ENDMETHOD;

	METHOD("applyToSim") {
		params [P_THISOBJECT, P_STRING("_state")];
		T_PRVAR(ourGarrId);
		T_PRVAR(targetOutpostId);
		T_PRVAR(stage);

		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _ourSide = CALLM0(_ourGarr, "getSide");
		private _targetOutpost = CALLM1(_state, "getOutpostById", _targetOutpostId);
		private _targetOutpostPos = CALLM0(_targetOutpost, "getPos");
		private _targetGarr = CALLM1(_state, "getAttachedGarrisonById", _targetOutpostId);

		// Regardless of stage, we expect any target garrison to be killed
		if(_targetGarr isEqualType "" and {CALLM0(_targetGarr, "getSide") != _ourSide}) then {
			CALLM2(_targetGarr, "setComp", 0, 0);
		};

		// If we didn't start the action yet then we need to subtract from srcGarr
		switch(_stage) do {
			case "new": {
				private _detachedComp = T_CALLM1("getDetachmentComp", _state);
				private _detachedGarr = CALLM1(_ourGarr, "splitGarrison", _detachedComp);
				CALLM1(_state, "addGarrison", _detachedGarr);
				CALLM2(_state, "attachGarrison", _detachedGarr, _targetOutpost);
			};
			case "moving": {
				T_PRVAR(detachedGarrId);
				private _detachedGarr = CALLM1(_state, "getGarrisonById", _detachedGarrId);
				CALLM2(_state, "attachGarrison", _detachedGarr, _targetOutpost);
			};
		};
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT, P_STRING("_state")];

		T_PRVAR(ourGarrId);
		T_PRVAR(targetOutpostId);
		T_PRVAR(stage);

		private _ourGarr = CALLM1(_state, "getGarrisonById", _ourGarrId);
		private _ourSide = CALLM0(_ourGarr, "getSide");
		private _targetOutpost = CALLM1(_state, "getOutpostById", _targetOutpostId);
		private _targetOutpostPos = CALLM0(_targetOutpost, "getPos");

		T_PRVAR(stage);

		// Stages:
		// new - split off detachment from our garrison and send them to target outpost
		// moving - if detachment is at the target outpost then occupy it
		switch(_stage) do {
			case "new": {
				OOP_INFO_2("TakeOutpostAction %1->%2 starting", _ourGarrId, _targetOutpostId);

				if(CALLM0(_ourGarr, "isDead")) exitWith {
					T_SETV("complete", true);
					OOP_INFO_2("TakeOutpostAction %1->%2 completed: %1 died", _ourGarrId, _targetOutpostId);
				};

				// Create the detachment
				private _detachedComp = T_CALLM1("getDetachmentComp", _state);
				private _detachedGarr = CALLM1(_ourGarr, "splitGarrison", _detachedComp);
				_detachedGarrId = CALLM1(_state, "addGarrison", _detachedGarr);
				T_SETV("detachedGarrId", _detachedGarrId);

				// Assign action to the split garrison.
				SETV_REF(_detachedGarr, "currAction", _thisObject);

				// Give the move order to the detachment
				OOP_INFO_3("TakeOutpostAction %1->%3->%2 moving %3 to target", _ourGarrId, _targetOutpostId, _detachedGarrId);
				private _args = [ format["%1 taking %2", _detachedGarrId, _targetOutpostId], _detachedGarrId, _targetOutpostPos];
				private _moveOrder = NEW("MoveOrder", _args);
				CALLM1(_detachedGarr, "giveOrder", _moveOrder);
				// Next stage
				T_SETV("stage", "moving");
			};

			case "moving": {
				T_PRVAR(detachedGarrId);
				private _detachedGarr = CALLM1(_state, "getGarrisonById", _detachedGarrId);
				if(CALLM0(_detachedGarr, "isDead")) exitWith {
					T_SETV("complete", true);
					OOP_INFO_3("TakeOutpostAction %1->%3->%2 completed: %3 died", _ourGarrId, _targetOutpostId, _detachedGarrId);
				};

				if(CALLM0(_detachedGarr, "isOrderComplete")) then {
					private _targetGarr = CALLM1(_state, "getAttachedGarrisonById", _targetOutpostId);

					if(!(_targetGarr isEqualType "") or {CALLM0(_targetGarr, "getSide") == _ourSide} or {CALLM0(_targetGarr, "isDead")}) then {
						// Occupying force is dead, and we arrived at target, so occupy it
						CALLM2(_state, "attachGarrison", _detachedGarr, _targetOutpost);

						T_SETV("complete", true);
						OOP_INFO_3("TakeOutpostAction %1->%3->%2 completed: %3 took outpost", _ourGarrId, _targetOutpostId, _detachedGarrId);
					};
				};
			};
		};
	} ENDMETHOD;
ENDCLASS;
