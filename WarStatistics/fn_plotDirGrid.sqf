/*
Plot the ws_grid on the map treating each element of input array as direction in degrees

Parameters:
_gridArray

Author: Sparker
*/
params ["_gridArray"];

call ws_fnc_unplotGrid;

//ws_grid = [missionNamespace, "ws_grid", Nil] call BIS_fnc_getServerVariable;

if(!isNil "_gridArray") then
{
	private _halfSize = 0.5*ws_squareSize;

	for "_i" from 0 to ws_gridSizeX - 1 do //_i is x-pos
	{
		//_markerColumn = [];
		for "_j" from 0 to ws_gridSizeY - 1 do //_j is y-pos
		{
			private _wsmName = format ["ws_mrk_%1_%2", _i, _j];

			private _wsm = createMarkerLocal [_wsmName, [ws_squareSize*_i + _halfSize + ws_gridStartX, ws_squareSize*_j + _halfSize + ws_gridStartY, 0]];
			//_markerColumn pushBack _wsm;
			_dir = [_gridArray, _i, _j] call ws_fnc_getValueID;
			if(_dir == 666) then //If we there's no direction there
			{
				_wsm setMarkerAlphaLocal 0;
			}
			else
			{
				_wsm setMarkerTypeLocal "mil_arrow2";
				_wsm setMarkerColorLocal "ColorOrange";
				_wsm setMarkerDirLocal _dir;
			};
		};
	};
};