#define OOP_DEBUG
#define OOP_INFO
#define OOP_WARNING
#define OOP_ERROR

#include "..\OOP_Light\OOP_Light.h"

#include "Constants.h"

CLASS("State", "")
	VARIABLE("garrisons");
	VARIABLE("outposts");
	VARIABLE("spawningOutposts");
	VARIABLE("lastSpawnT");

	METHOD("new") {
		params [P_THISOBJECT];

		T_SETV("garrisons", []);
		T_SETV("outposts", []);
		T_SETV("spawningOutposts", []);
		T_SETV("lastSpawnT", time);
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
		private _garrisons = [];
		private _garrisonMarkers = _markers select { markerType _x == type_garrison };
		{
			private _garrisonMarker = _x;
			private _newGarrison = NEW("Garrison", []);
			REF(_newGarrison);
			CALLM1(_newGarrison, "initFromMarker", _garrisonMarker);
			private _idx = _garrisons pushBack _newGarrison;
			CALLM1(_newGarrison, "setId", _idx);
		} forEach _garrisonMarkers;

		private _outpostMarkers = _markers select { markerType _x in [type_spawn, type_outpost] };
		private _spawningOutposts = [];
		private _outposts = [];
		{
			private _outpostMkr = _x;
			
			private _newOutpost = NEW("Outpost", []);
			REF(_newOutpost);
			CALLM1(_newOutpost, "initFromMarker", _outpostMkr);
			private _outpostId = _outposts pushBack _newOutpost;
			if(markerType _outpostMkr == type_spawn) then {
				_spawningOutposts pushBack _newOutpost;
			};
			if(count (markerText _outpostMkr) > 0) then {
				private _newGarrMkr = createMarker [ _outpostMkr + "_garr", markerPos _outpostMkr ];
				OOP_INFO_2("Adding garrison %1 for outpost %2...", _newGarrMkr, _outpostMkr);
				_newGarrMkr setMarkerShape "ICON";
				_newGarrMkr setMarkerType type_garrison;
				_newGarrMkr setMarkerColor (markerColor _outpostMkr);
				_newGarrMkr setMarkerText (markerText _outpostMkr);
				private _newGarrison = NEW("Garrison", []);
				REF(_newGarrison);
				CALLM1(_newGarrison, "initFromMarker", _newGarrMkr);
				private _garrisonId = _garrisons pushBack _newGarrison;
				CALLM1(_newGarrison, "setId", _garrisonId);
				SETV(_newGarrison, "outpostId", _outpostId);
				SETV(_newOutpost, "garrisonId", _garrisonId);
			};
			CALLM1(_newOutpost, "setId", _outpostId);
		} forEach _outpostMarkers;

		OOP_INFO_2("Found %1 garrisons and %2 outposts...", count _garrisons, count _outposts);

		T_SETV("garrisons", _garrisons);
		T_SETV("outposts", _outposts);
		T_SETV("spawningOutposts", _spawningOutposts);
	} ENDMETHOD;

	METHOD("addGarrison") {
		params [P_THISOBJECT, P_STRING("_newGarr")];
		T_PRVAR(garrisons);
		REF(_newGarr);
		private _idx = _garrisons pushBack _newGarr;
		CALLM1(_newGarr, "setId", _idx);
		_idx
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

	METHOD("attachGarrison") {
		params [P_THISOBJECT, P_STRING("_garrison"), P_STRING("_outpost")];
		private _oldOutpostId = GETV(_garrison, "outpostId");
		if(_oldOutpostId != -1) then {
			private _oldOutpost = T_CALLM1("getOutpostById", _oldOutpostId);
			SETV(_oldOutpost, "garrisonId", -1);
			CALLM1(_oldOutpost, "setSide", side_none);
		};
		private _currGarrId = GETV(_outpost, "garrisonId");
		if(_currGarrId != -1) then {
			private _currGarr = T_CALLM1("getGarrisonById", _currGarrId);
			// TODO: this should probably be an action or order instead of direct merge?
			// Or maybe the garrison logic itself and handle regrouping sensibly etc.
			CALLM1(_currGarr, "mergeGarrison", _garrison);
		} else {
			private _outpostId = GETV(_outpost, "id");
			private _garrisonId = GETV(_garrison, "id");
			SETV(_garrison, "outpostId", _outpostId);
			SETV(_outpost, "garrisonId", _garrisonId);

			private _garrSide = CALLM0(_garrison, "getSide");
			CALLM1(_outpost, "setSide", _garrSide);
		};
	} ENDMETHOD;

	METHOD("detachGarrison") {
		params [P_THISOBJECT, P_STRING("_garrison")];
		private _oldOutpostId = GETV(_garrison, "outpostId");
		if(_oldOutpostId != -1) then {
			private _oldOutpost = T_CALLM1("getOutpostById", _oldOutpostId);
			SETV(_oldOutpost, "garrisonId", -1);
			CALLM1(_oldOutpost, "setSide", side_none);
		};
	} ENDMETHOD;

	METHOD("getAttachedGarrisonById") {
		params [P_THISOBJECT, P_NUMBER("_outpostId")];
		T_PRVAR(outposts);
		T_PRVAR(garrisons);
		private _outpost = _outposts select _outpostId;
		private _garrisonId = GETV(_outpost, "garrisonId");
		if(_garrisonId != -1) then { _garrisons select _garrisonId } else { objNull }
	} ENDMETHOD;

	METHOD("getAttachedOutpostById") {
		params [P_THISOBJECT, P_NUMBER("_garrisonId")];
		T_PRVAR(garrisons);
		T_PRVAR(outposts);
		private _garrison = _garrisons select _garrisonId;
		private _outpostId = GETV(_garrison, "outpostId");
		if(_outpostId != -1) then { _outposts select _outpostId } else { objNull }
	} ENDMETHOD;

	METHOD("getAliveGarrisons") {
		params [P_THISOBJECT];
		T_PRVAR(garrisons);
		_garrisons select { !CALLM0(_x, "isDead") }
	} ENDMETHOD;
	
	METHOD("getNearestGarrisons") {
		params [P_THISOBJECT, P_ARRAY("_center"), P_NUMBER("_maxDist")];

		// TODO: optimize obviously, use spatial partitioning, probably just a grid? Maybe quad tree..
		private _nearestGarrisons = [];

		{
			private _garrison = _x;
			private _pos = CALLM0(_garrison, "getPos");
			private _dist = _pos distance2D _center;
			if(_dist <= _maxDist) then {
				_nearestGarrisons pushBack [_dist, _garrison];
			};
		} forEach T_CALLM0("getAliveGarrisons");
		_nearestGarrisons sort true;
		_nearestGarrisons
	} ENDMETHOD;

	METHOD("getNearestOutposts") {
		params [P_THISOBJECT, P_ARRAY("_center"), P_NUMBER("_maxDist")];

		T_PRVAR(outposts);

		// TODO: optimize obviously, use spatial partitioning, probably just a grid? Maybe quad tree..
		private _nearestOutposts = [];
		{
			private _outpost = _x;
			private _pos = CALLM0(_outpost, "getPos");
			private _dist = _pos distance2D _center;
			if(_dist <= _maxDist) then {
				_nearestOutposts pushBack [_dist, _outpost];
			};
		} forEach _outposts;
		_nearestOutposts sort true;
		_nearestOutposts
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

		private _aliveGarrisons = T_CALLM0("getAliveGarrisons");
		// Update garrisons
		{
			CALLM1(_x, "update", _thisObject);
		} forEach _aliveGarrisons;

		// Perform combat
		private _calcedGarrisons = [];
		{
			private _curr = _x;
			if !(_curr in _calcedGarrisons) then {
				_calcedGarrisons pushBack _curr;
				private _currPos = CALLM0(_curr, "getPos");
				private _currSide = CALLM0(_curr, "getSide");
				private _enemyGarrisons = (_aliveGarrisons - _calcedGarrisons) select { 
					CALLM0(_x, "getSide") != _currSide and
					(CALLM0(_x, "getPos") distance _currPos) < 500 
				};
				{
					CALLM1(_curr, "fightUpdate", _x);
					_calcedGarrisons pushBack _curr;
				} forEach _enemyGarrisons;
			};
		} forEach _aliveGarrisons;

		{
			T_CALLM1("garrisonKilled", _x);
		} forEach (_calcedGarrisons select { CALLM0(_x, "isDead") });

		T_PRVAR(lastSpawnT);
		if(time - _lastSpawnT > SPAWN_INTERVAL) then {
			T_PRVAR(spawningOutposts);
			T_SETV("lastSpawnT", time);
			{
				private _outpost = _x;
				private _outpostId = GETV(_outpost, "id");
				private _garrison = T_CALLM1("getAttachedGarrisonById", _outpostId);
				private _outpostPos = CALLM0(_outpost, "getPos");
				private _desiredComp = T_CALLM1("getDesiredComp", _outpostPos);

				if !(_garrison isEqualType "") then {
					private _outpostSide = CALLM0(_outpost, "getSide");
					_garrison = NEW("Garrison", []);
					private _newGarrMkr = createMarker [ str(_outpostId) + "_garr_" + str(time), _outpostPos ];
					_newGarrMkr setMarkerShape "ICON";
					_newGarrMkr setMarkerType type_garrison;
					_newGarrMkr setMarkerColor _outpostSide;
					//_newGarrMkr setMarkerText "20/4";
					CALLM1(_garrison, "initFromMarker", _newGarrMkr);
					T_CALLM1("addGarrison", _garrison);

					//CALLM2(_garrison, "setComp", 20, 4);
					//CALLM1(_garrison, "setPos", _outpostPos);
					//CALLM1(_garrison, "setSide", _outpostSide);
				};
				
				CALLM2(_garrison, "setComp", _desiredComp#0 * 2, _desiredComp#1 * 2);
			} forEach _spawningOutposts;
		};
		T_PRVAR(spawningOutposts);
	} ENDMETHOD;

	METHOD("garrisonKilled") {
		params [P_THISOBJECT, P_STRING("_garrison")];
		T_CALLM1("detachGarrison", _garrison);
		CALLM0(_garrison, "killed");
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
			_comp#0 - _desiredComp#0,
			// vehicles
			_comp#1 - _desiredComp#1
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
			_comp#0 - _compScalar * _desiredComp#0,
			// vehicles
			_comp#1 - _compScalar * _desiredComp#1
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
			(0 max (_overComp#0 * -1)) * UNIT_STRENGTH +
			// vehicles
			(0 max (_overComp#1 * -1)) * VEHICLE_STRENGTH;

		// apply non linear function to threat (https://www.desmos.com/calculator/wnlyulwf7m)
		// This models reinforcement desireability as relative to absolute power of 
		// missing comp rather than relative to ratio of missing comp/desired comp.
		// 
		_score = 0.1 * _score;
		_score = 0 max ( _score * _score * _score );
		_score
	} ENDMETHOD;

ENDCLASS;
