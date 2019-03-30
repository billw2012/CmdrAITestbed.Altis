/*
Smoothes the input array
Input: [_sourceArray]
Return: a new smoothed array
*/

params ["_gridArray", ["_destArray", []]];

if(_destArray isEqualTo []) then
{
	_destArray = call ws_fnc_newGridArray;
};

if(!isNil "_gridArray") then
{
	for "_i" from 0 to ws_gridSizeX - 1 do //_i is x-pos
	{
		for "_j" from 0 to ws_gridSizeY - 1 do //_j is y-pos
		{
			private _newValue = [_gridArray, _i, _j] call ws_fnc_getSmoothValueID;
			[_destArray, _i, _j, _newValue] call ws_fnc_setValueID;
		};
	};
};

_destArray