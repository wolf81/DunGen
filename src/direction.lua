Direction = {}

Direction.cardinal = {
    north = {  0, -1 }, 
    south = {  0,  1 },
    east =  {  1,  0 },
    west =  { -1,  0 },
}

Direction.opposite = {
    north = south,
    south = north,
    east  = west,
    west  = east,
}

