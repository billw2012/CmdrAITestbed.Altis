#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

CLASS("State", "")
	VARIABLE("garrisons");
	VARIABLE("outposts");

	METHOD("new") {
		params [P_THISOBJECT];

		T_SETV("garrisons", []);
		T_SETV("outposts", []);
	} ENDMETHOD;

	METHOD("delete") {
		params [P_THISOBJECT];
		T_PRVAR(garrisons);
		T_PRVAR(outposts);
		{ UNREF(_x) } forEach _garrisons;
		{ UNREF(_x) } forEach _outposts;
	} ENDMETHOD;

	METHOD("initFromMarkers") {
		params [P_THISOBJECT, P_ARRAY("_markers")];

		// find all intesting markers
		private _garrisons = (_markers select { markerType _x == type_garrison }) apply { 
			private _newGarrison = NEW("Garrison", []);
			REF(_newGarrison);
			CALLM1(_newGarrison, "initFromMarker", _x);
			_newGarrison
		};

		private _outpostMarkers = _markers select { markerType _x == type_outpost };
		private _garrisonedOutposts = _outpostMarkers select { count (markerText _x) > 0 };
		private _outpostGarrs = _garrisonedOutposts apply {
			private _outpostMkr = _x;
			private _newGarrMkr = createMarker [ _outpostMkr + "_garr", markerPos _outpostMkr ];
			OOP_INFO_2("Adding garrison %1 for outpost %2...", _newGarrMkr, _outpostMkr);
			_newGarrMkr setMarkerShape "ICON";
			_newGarrMkr setMarkerType type_garrison;
			_newGarrMkr setMarkerColor (markerColor _outpostMkr);
			_newGarrMkr setMarkerText (markerText _outpostMkr);
			_outpostMkr setMarkerText "";
			private _newGarrison = NEW("Garrison", []);
			REF(_newGarrison);
			CALLM1(_newGarrison, "initFromMarker", _newGarrMkr);
			_newGarrison
		};
		private _outposts = _outpostMarkers apply { 
			private _newOutpost = NEW("Outpost", []);
			REF(_newOutpost);
			CALLM1(_newOutpost, "initFromMarker", _x);
			_newOutpost
		};
		_garrisons = _garrisons + _outpostGarrs;

		OOP_INFO_2("Found %1 garrisons and %2 outposts...", count _garrisons, count _outposts);
		T_SETV("garrisons", _garrisons);
		T_SETV("outposts", _outposts);
	} ENDMETHOD;

	METHOD("addGarrison") {
		params [P_THISOBJECT, P_STRING("_newGarr")];
		T_PRVAR(garrisons);
		REF(_newGarr);
		_garrisons pushBack _newGarr
	} ENDMETHOD;
	
	METHOD("getGarrisonById") {
		params [P_THISOBJECT, P_NUMBER("_id")];
		T_PRVAR(garrisons);
		_garrisons select _id
	} ENDMETHOD;

	METHOD("getOutpostById") {
		params [P_THISOBJECT, P_NUMBER("_id")];
		T_PRVAR(outposts);
		_outposts select _id
	} ENDMETHOD;

	METHOD("getNearestGarrisonsById") {
		params [P_THISOBJECT, P_STRING("_side"), P_ARRAY("_pos"), P_NUMBER("_dist")];

		T_PRVAR(garrisons);

		// TODO: optimize obviously, use spatial partitioning, probably just a grid? Maybe quad tree..
		private _garrs = [];
		for "_i" from 0 to count _garrisons - 1 do {
			private _garrison = _garrisons select _i;
			if(CALLM0(_garrison, "getSide") == _side) then {
				private _garrisonPos = CALLM0(_garrison, "getPos");
				private _garrisonDist = _garrisonPos distance2D _pos;
				if(_garrisonDist <= _dist) then {
					_garrs pushBack [_garrisonDist, _i];
				};
			};
		};
		_garrs sort true;
	} ENDMETHOD;

	METHOD("getNearestNonEnemyOutpostId") {
		params [P_THISOBJECT, P_STRING("_side"), P_ARRAY("_pos")];

		T_PRVAR(outposts);

		// TODO: optimize obviously, use spatial partitioning, probably just a grid? Maybe quad tree..
		private _nearestOutpostId = -1;
		private _nearestDist = 100000;
		for "_i" from 0 to count _outposts - 1 do {
			private _outpost = _outposts select _i;
			if(CALLM0(_outpost, "getSide") in [_side, side_none]) then {
				private _outpostPos = CALLM0(_outpost, "getPos");
				private _outpostDist = _outpostPos distance2D _pos;
				if(_outpostDist < _nearestDist) then {
					_nearestOutpostId = _i;
					_nearestDist = _outpostDist;
				};
			};
		};
		_nearestOutpostId
	} ENDMETHOD;

	METHOD("simCopy") {
		params [P_THISOBJECT];
		
		T_PRVAR(garrisons);
		T_PRVAR(outposts);
		
		private _simState = NEW("State", []);
		private _simGarrisons = _garrisons apply { 
			private _copy = CALLM0(_x, "simCopy");
			REF(_copy);
			_copy
		};
		SETV(_simState, "garrisons", _simGarrisons);
		private _simOutposts = _outposts apply { 
			private _copy = CALLM0(_x, "simCopy");
			REF(_copy);
			_copy
		};
		SETV(_simState, "outposts", _simOutposts);

		_simState
	} ENDMETHOD;

	METHOD("update") {
		params [P_THISOBJECT];
		T_PRVAR(garrisons);
		T_PRVAR(outposts);

		// Update garrisons
		{
			CALLM1(_x, "update", _thisObject);
		} forEach _garrisons;

		// Perform combat
		private _calcedGarrisons = [];
		{
			private _curr = _x;
			if !(_x in _calcedGarrisons) then {
				_calcedGarrisons pushBack _x;
				private _otherGarrisons = (_garrisons - _calcedGarrisons) select { 
					CALLM0(_curr, "getSide") != CALLM0(_x, "getSide") and
					(CALLM0(_curr, "getPos") distance CALLM0(_x, "getPos")) < 500 
				};
				{
					CALLM1(_curr, "fightUpdate", _x);
				} forEach _otherGarrisons;
				_calcedGarrisons = _calcedGarrisons + _otherGarrisons;
			};
		} forEach _garrisons;

	} ENDMETHOD;
	
	// Action toolkit

	// Get desired composition of forces at a particular location.
	METHOD("getDesiredComp") {
		params [P_THISOBJECT, P_ARRAY("_pos")];
		// TODO: calculate this based on threat levels / whatever.
		// For now just 10 units, 2 vehicles is desired strength
		[10, 2]
	} ENDMETHOD;

	// How much over desired composition is the garrison? Negative for under.
	METHOD("getOverDesiredComp") {
		params [P_THISOBJECT, P_STRING("_garr")];
		
		private _pos = CALLM0(_garr, "getPos");
		private _comp = [GETV(_garr, "unitCount"), GETV(_garr, "vehCount")];
		private _desiredComp = T_CALLM1("getDesiredComp", _pos);
		[
			// units
			(_comp select 0) - (_desiredComp select 0),
			// vehicles
			(_comp select 1) - (_desiredComp select 1)
		]
	} ENDMETHOD;

	// How much over desired composition is the garrison? Negative for under.
	METHOD("getOverDesiredCompScaled") {
		params [P_THISOBJECT, P_STRING("_garr"), P_NUMBER("_compScalar")];
		
		private _pos = CALLM0(_garr, "getPos");
		private _comp = [GETV(_garr, "unitCount"), GETV(_garr, "vehCount")];
		private _desiredComp = T_CALLM1("getDesiredComp", _pos);
		[
			// units
			(_comp select 0) - _compScalar * (_desiredComp select 0),
			// vehicles
			(_comp select 1) - _compScalar * (_desiredComp select 1)
		]
	} ENDMETHOD;

	// A scoring factor for how much a garrison desires reinforcement
	METHOD("getReinforceRequiredScore") {
		params [P_THISOBJECT, P_STRING("_garr")];

		// How much garr is *under* composition (so over comp * -1) with a non-linear function applied.
		// i.e. How much units/vehicles tgt needs.
		private _overComp = T_CALLM2("getOverDesiredCompScaled", _garr, 0.75);
		private _score = 
			// units
			(0 max ((_overComp select 0) * -1)) * UNIT_STRENGTH +
			// vehicles
			(0 max ((_overComp select 1) * -1)) * VEHICLE_STRENGTH;

		// apply non linear function to threat (https://www.desmos.com/calculator/wnlyulwf7m)
		// This models reinforcement desireability as relative to absolute power of 
		// missing comp rather than relative to ratio of missing comp/desired comp.
		// 
		_score = 0.1 * _score;
		_score = 0 max ( _score * _score * _score );
		_score
	} ENDMETHOD;

ENDCLASS;
