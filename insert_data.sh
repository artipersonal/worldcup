#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

#initializing array for teams and array for games to bulk insert later
declare -a arrGames
declare -A arrTeams
declare -a arrTeamsReq

arrGames+=("INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES")
arrTeamsReq+=("INSERT INTO teams(name) VALUES")

#cleaning up the tables and serial numbers for teams for further fast input
TRUNC_RES=$( $PSQL "TRUNCATE teams, games;" )
RESET_RES=$( $PSQL "SELECT setval(pg_get_serial_sequence('teams', 'team_id'), COALESCE(max(team_id) + 1, 1), false) FROM teams;" )
echo $TRUNC_RES
echo $RESET_RES

#reading the file directly without opening another bash
COUNTER=0
while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
if [[ $YEAR != "year" ]]
then
#fulfilling hash table with indexes
if [ ! -v arrTeams["$WINNER"] ]
then
COUNTER=$(( $COUNTER + 1 ))
arrTeams["$WINNER"]=$COUNTER
arrTeamsReq+=("('$WINNER')")
arrTeamsReq+=(",")
fi

if [ ! -v arrTeams["$OPPONENT"] ]
then
COUNTER=$(( $COUNTER + 1 ))
arrTeams["$OPPONENT"]=$COUNTER
arrTeamsReq+=("('$OPPONENT')")
arrTeamsReq+=(",")
fi

#fulfilling the array of games with values
arrGames+=("($YEAR, '$ROUND', ${arrTeams["$WINNER"]}, ${arrTeams["$OPPONENT"]}, $WINNER_GOALS, $OPPONENT_GOALS)")
arrGames+=(",")

#done with the while loop. For another bash not to open- directly interacting with file there
fi
done < games.csv  

#removing last ',' from the array to complete the request
unset arrGames[${#arrGames[*]}-1]
unset arrTeamsReq[${#arrTeamsReq[*]}-1]
#adding last pices of sql command
arrGames+=(";")
arrTeamsReq+=(";")
#chech the result for games insert
echo ${arrGames[*]}
echo ${arrTeamsReq[*]}
echo $COUNTER
echo ${arrTeams["United States"]}

#making a request to the table
INSERT_TEAMS=$( $PSQL "${arrTeamsReq[*]}" )
INSERT_GAMES=$( $PSQL "${arrGames[*]}" )

echo teams inserted: $INSERT_TEAMS
echo games inserted: $INSERT_GAMES