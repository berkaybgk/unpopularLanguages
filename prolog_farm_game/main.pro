 % berkay bugra gok
% 2021400258
% compiling: yes
% complete: no

% assignment is not completed, only the first 8 questions are implemented

:- ['cmpefarm.pro'].
:- init_from_map.


% 1- agents_distance(+Agent1, +Agent2, -Distance)
% get the distances of each agent and calculate the manhattan distance
agents_distance(Agent1, Agent2, Distance) :-
    get_dict(x, Agent1, X1),
    get_dict(y, Agent1, Y1),
    get_dict(x, Agent2, X2),
    get_dict(y, Agent2, Y2),
    Distance is abs(X1 - X2) + abs(Y1 - Y2).


% 2- number_of_agents(+State, -NumberOfAgents)
% find the total number of agents in the state
number_of_agents(State, NumberOfAgents) :-
    State = [Agents, _, _, _],
    dict_pairs(Agents, _, Pairs),
    list_length(Pairs, NumberOfAgents).


% 3- value_of_farm(+State, -Value)
% calculate the total value of the farm, each entity has a value defined in the farm.pro
value_of_farm(State, TotalValue) :-
    State = [AgentsDict, ObjectsDict, _, _],
    dict_to_list(AgentsDict, Agents),
    dict_to_list(ObjectsDict, Objects),
    value_of_agents(Agents, AgentValue),
    value_of_objects(Objects, ObjectValue),
    TotalValue is AgentValue + ObjectValue.

% get the value of the object
value_of_objects([], 0).
value_of_objects([Object|Rest], TotalValue) :-
    value_of_object(Object, ObjectValue),
    value_of_objects(Rest, RestValue),
    TotalValue is ObjectValue + RestValue.

value_of_object(Object, ObjectValue) :-
    get_dict(subtype, Object, Subtype),
    value(Subtype, ObjectValue).

% get the value of the agents
value_of_agents([], 0).
value_of_agents([Agent|Rest], TotalValue) :-
    get_dict(subtype, Agent, Subtype),
    (Subtype = wolf -> AgentValue = 0 ; value(Subtype, AgentValue)),
    value_of_agents(Rest, RestValue),
    TotalValue is AgentValue + RestValue.

dict_to_list(Dict, List) :-
    dict_pairs(Dict, _, Pairs),
    extract_values(Pairs, List).

extract_values([], []).
extract_values([_-Value|Rest], [Value|Values]) :-
    extract_values(Rest, Values).


% 4- find_food_coordinates(+State, +AgentId, -Coordinates)
% find the coordinates of the food that the agent can eat
find_food_coordinates(State, AgentId, Coordinates) :-
    State = [Agents, _, _, _],
    get_agent(State, AgentId, Agent),
    get_dict(subtype, Agent, AgentType),
    (   AgentType = wolf
    ->  find_food_coordinates_for_wolf(Agents, AgentId, Coordinates)
    ;   find_food_coordinates_for_herbivore(Agents, AgentType, Coordinates)
    ).

% helper rules for different types of agents
find_food_coordinates_for_wolf(Agents, AgentId, Coordinates) :-
    findall([X, Y], (
        get_dict(AId, Agents, A),
        AId \= AgentId,
        get_dict(subtype, A, Subtype),
        (Subtype == cow ; Subtype == chicken),
        get_dict(x, A, X),
        get_dict(y, A, Y)
    ), Coordinates).

find_food_coordinates_for_herbivore(_, AgentType, Coordinates) :-
    state(_, Objects, _, _),
    findall([X, Y], (
        get_dict(_, Objects, Object),
        get_dict(subtype, Object, Subtype),
        can_eat(AgentType, Subtype),
        get_dict(x, Object, X),
        get_dict(y, Object, Y)
    ), Coordinates).


% 5- find_nearest_agent(+State, +AgentId, -Coordinates, -NearestAgent)
% find the nearest agent to the given agent by finding all the distances and then finding the minimum distance
find_nearest_agent(State, AgentId, Coordinates, NearestAgent) :-
    State = [Agents, _, _, _],
    get_agent(State, AgentId, Agent),
    get_dict(x, Agent, X),
    get_dict(y, Agent, Y),
    findall(Distance-Agent_, (
        get_dict(AId, Agents, A),
        AId \= AgentId,
        get_dict(x, A, AX),
        get_dict(y, A, AY),
        distance(X, Y, AX, AY, Distance),
        Agent_ = A
    ), Distances),
    min_distance_agent(Distances, Coordinates, NearestAgent).

distance(X1, Y1, X2, Y2, Distance) :-
    Distance is abs(X1 - X2) + abs(Y1 - Y2).

min_distance_agent([Distance-Agent|Rest], Coordinates, NearestAgent) :-
    min_distance_agent_helper(Rest, Distance, Agent, Coordinates, NearestAgent).

min_distance_agent_helper([], _, NearestAgent, Coordinates, NearestAgent) :-
    get_dict(x, NearestAgent, X),
    get_dict(y, NearestAgent, Y),
    Coordinates = [X, Y].
min_distance_agent_helper([Distance-Agent|Rest], MinDistance, _, Coordinates, NearestAgent) :-
    Distance < MinDistance,
    min_distance_agent_helper(Rest, Distance, Agent, Coordinates, NearestAgent).
min_distance_agent_helper([_|Rest], MinDistance, NearestAgentSoFar, Coordinates, NearestAgent) :-
    min_distance_agent_helper(Rest, MinDistance, NearestAgentSoFar, Coordinates, NearestAgent).


% 6- find_nearest_food(+State, +AgentId, -Coordinates, -FoodType, -Distance)
% find the nearest food to the given agent by finding all the distances and then finding the minimum distance
find_nearest_food(_, AgentId, Coordinates, FoodType, Distance) :-
    state(Agents, Objects, _, _),
    get_dict(AgentId, Agents, Agent),
    get_dict(x, Agent, X),
    get_dict(y, Agent, Y),
    get_dict(subtype, Agent, AgentType),

    findall([X1, Y1, Type1, Distance1], (
        (
            (AgentType = wolf) -> 
                (get_dict(_, Agents, Agent1),
                get_dict(subtype, Agent1, Type1),
                get_dict(x, Agent1, X1),
                get_dict(y, Agent1, Y1)) 
            ;
                (get_dict(_, Objects, Object),
                get_dict(subtype, Object, Type1),
                get_dict(x, Object, X1),
                get_dict(y, Object, Y1))
        ),
        can_eat(AgentType, Type1),
        manhattan_distance([X, Y], [X1, Y1], Distance1)
    ), FoodCoords),
    nearest_food(FoodCoords, Coordinates, FoodType, Distance).

nearest_food([], _, _, _).
nearest_food([[X, Y, Type, Distance]|Rest], Coordinates, FoodType, MinDistance) :-
    nearest_food_helper(Rest, X, Y, Type, Distance, Coordinates, FoodType, MinDistance).

nearest_food_helper([], X, Y, Type, Distance, Coordinates, FoodType, MinDistance) :-
    Coordinates = [X, Y],
    FoodType = Type,
    MinDistance = Distance.

% find the minimum distance, check if the current distance is less than the previous minimum distance
nearest_food_helper([[X, Y, Type, Distance]|Rest], X1, Y1, Type1, Distance1, Coordinates, FoodType, MinDistance) :-
    (Distance < Distance1 ->
        nearest_food_helper(Rest, X, Y, Type, Distance, Coordinates, FoodType, MinDistance);
        nearest_food_helper(Rest, X1, Y1, Type1, Distance1, Coordinates, FoodType, MinDistance)
    ).

manhattan_distance([X1, Y1], [X2, Y2], Distance) :-
    Distance is abs(X1 - X2) + abs(Y1 - Y2).


% 7- move_to_coordinate(+State, +AgentId, +X, +Y, -ActionList, +DepthLimit)
% move the agent to the given coordinate by using bfs, if it can reach the coordinate within the depth limit
move_to_coordinate(State, AgentId, X, Y, ActionList, DepthLimit) :-
    get_agent(State, AgentId, Agent),
    get_dict(x, Agent, X1),
    get_dict(y, Agent, Y1),
    get_dict(subtype, Agent, AgentType),
    bfs_helper(State, AgentType, X1, Y1, X, Y, DepthLimit, [[X1,Y1]], [], ActionList, []).

% helper rules for bfs
bfs_helper(State, AgentType, X1, Y1, X, Y, DepthLimit, Visited, PathesQueue, ActionList, LastPath) :-
    bfs(State, AgentType, X1, Y1, X, Y, DepthLimit, Visited, PathesQueue, LastPath, ActionList).

bfs(_, _, X, Y, X, Y, _, _, _, LastPath, ActionList) :-  % if the agent reached the target, then add the moves to the ActionList
    add_elements(LastPath, [], ActionList).   % append each element of the LastPath to the ActionList
    
bfs(_, _, _, _, _, _, _, _, [], _, _) :- fail.   % if the queue is empty, then fail
bfs(State, AgentType, CurrX, CurrY, TargetX, TargetY, DepthLimit, Visited, PathesQueue, LastPath, ActionList) :-
    list_length(LastPath, Depth),
    Depth < DepthLimit,
    height(Height),
    width(Width),

    % find the possible moves from the current position
    findall([NewX, NewY, Move], (
        can_move(AgentType, Move),
        coordinates_after_move(Move, CurrX, CurrY, NewX, NewY),
        \+ member([[NewX, NewY]], Visited),
        \+ is_coordinate_in_queue(NewX, NewY, PathesQueue),
        can_agent_move_to_position(AgentType, NewX, NewY),
        within_bounds(NewX, NewY, Width, Height)
    ), NewCoordinates),

    % find the pathes after this move
    findall(NewPath, (
        member(NewCoord, NewCoordinates),
        my_append(LastPath, [NewCoord], NewPath)
    ), NewPathes),

    % enqueue the new pathes to the queue
    append_all_to_queue(NewPathes, PathesQueue, NewPathesQueue),
    % get the next path from the queue
    dequeue(NewPathesQueue, NextPath, NewPathesQueueAfterDequeue),
    % get the last coordinate reached by this path.
    get_last_element_of_last_path(NextPath, LastX, LastY, _),
    % mark as visited
    my_append(Visited, [[LastX, LastY]], NewVisited),
    % bfs()
    bfs(State, AgentType, LastX, LastY, TargetX, TargetY, DepthLimit, NewVisited, NewPathesQueueAfterDequeue, NextPath, ActionList).

% check if the agent can move to the given position based on the agent type
can_agent_move_to_position(AgentType, NewX, NewY) :-
    (
        (AgentType = wolf, \+ is_wolf_at_position(NewX, NewY)) ;
        (AgentType = cow, \+ is_agent_at_position(NewX, NewY)) ;
        (AgentType = chicken, \+ is_agent_at_position(NewX, NewY))
    ).

% to check if the coordinate is in the queue, don't add it again if it is already in the queue
is_coordinate_in_queue(X, Y, Queue) :-
    member(Path, Queue),
    member([X, Y, _], Path).

% get the last element of the last path
get_last_element_of_last_path([], [LastX, LastY, LastMove], LastX, LastY, LastMove).
get_last_element_of_last_path([H|T], _, LastX, LastY, LastMove) :-
    get_last_element_of_last_path(T, H, LastX, LastY, LastMove).

get_last_element_of_last_path([H|T], LastX, LastY, LastMove) :-
    get_last_element_of_last_path(T, H, LastX, LastY, LastMove).

% append all the elements of the list to the queue
append_all_to_queue([], Queue, Queue).
append_all_to_queue([Head|Tail], Queue, NewQueue) :-
    enqueue(Queue, Head, NewQueue1),
    append_all_to_queue(Tail, NewQueue1, NewQueue).

% queue rules
enqueue([], Element, [Element]).
enqueue([Head|Tail], Element, [Head|Rest]) :- enqueue(Tail, Element, Rest).

dequeue([Head|Tail], Head, Tail).

% check if the given coordinates are within the bounds of the farm
within_bounds(X, Y, W, H) :-
    RealW is W - 1,
    RealH is H - 1,
    X > 0, Y > 0, X < RealW, Y < RealH.

% add the elements of the LastPath to the ActionList
add_elements([], Destination, Destination).
add_elements([[_,_,Move]|Tail], Destination, Result) :-
    my_append(Destination, [Move], NewDestination),
    add_elements(Tail, NewDestination, Result).

% get the length of the list
list_length([], 0).
list_length([_|T], N) :-
     length(T, N1), N is N1 + 1.

% get the agent from the given position, wolves can't move onto each other
is_wolf_at_position(X, Y) :-
    state(Agents, _, _, _),
    get_dict(_, Agents, Agent),
    get_dict(x, Agent, X),
    get_dict(y, Agent, Y),
    get_agent_from_position(X, Y, Agents, Agent),
    get_dict(subtype, Agent, wolf).

% get the agent from the given position, cows and chickens can't move onto any other agent
is_agent_at_position(X, Y) :-
    state(Agents, _, _, _),
    get_dict(_, Agents, Agent),
    get_agent_from_position(X, Y, Agents, Agent).

my_append([], L, L).
my_append([H|T], L, [H|R]) :- my_append(T, L, R).

% new coordinates after the move
coordinates_after_move(move_right, CurrentX, CurrentY, NewX, NewY) :- NewX is CurrentX + 1, NewY is CurrentY.
coordinates_after_move(move_left, CurrentX, CurrentY, NewX, NewY) :- NewX is CurrentX - 1, NewY is CurrentY.
coordinates_after_move(move_up, CurrentX, CurrentY, NewX, NewY) :- NewX is CurrentX, NewY is CurrentY + 1.
coordinates_after_move(move_down, CurrentX, CurrentY, NewX, NewY) :- NewX is CurrentX, NewY is CurrentY - 1.
coordinates_after_move(move_up_right, CurrentX, CurrentY, NewX, NewY) :- NewX is CurrentX + 1, NewY is CurrentY + 1.
coordinates_after_move(move_up_left, CurrentX, CurrentY, NewX, NewY) :- NewX is CurrentX - 1, NewY is CurrentY + 1.
coordinates_after_move(move_down_right, CurrentX, CurrentY, NewX, NewY) :- NewX is CurrentX + 1, NewY is CurrentY - 1.
coordinates_after_move(move_down_left, CurrentX, CurrentY, NewX, NewY) :- NewX is CurrentX - 1, NewY is CurrentY - 1.
    

% 8- move_to_nearest_food(+State, +AgentId, -ActionList, +DepthLimit)
move_to_nearest_food(State, AgentId, ActionList, DepthLimit) :-
    find_nearest_food(State, AgentId, [X, Y], _, _),     % find the nearest food
    move_to_coordinate(State, AgentId, X, Y, ActionList, DepthLimit).   % move to the nearest food


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% 9- consume_all(+State, +AgentId, -NumberOfMoves, -Value, NumberOfChildren +DepthLimit)
