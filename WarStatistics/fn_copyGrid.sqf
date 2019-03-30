/*
Copy one grid array to another grid array
input: [_to, _from]
*/

params ["_to", "_from"];

private _column = [];

for "_i" from 0 to ws_gridSizeX - 1 do //_i is x-pos
{
	_column = +(_from select _i); //Copy the column
	_to set [_i, _column];
};