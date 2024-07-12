#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
#Generate random number from 1 to 1000
SECRET_NUMBER=$(( 1 + RANDOM % 1000 ))
echo -e "Enter your username:"
read USERNAME
#Check if user exists
QUERY_USERNAME_RESULT=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
#If user does not exist
if [[ -z $QUERY_USERNAME_RESULT ]]
then
  echo -e "Welcome, $USERNAME! It looks like this is your first time here."
  #Add user to database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0)")
#If user exists
else
  #Get user's number of games played and best game
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'")
  BEST_GAME_GUESSES=$($PSQL "SELECT min(number_of_guesses) FROM games LEFT JOIN users USING(user_id) WHERE username='$USERNAME' GROUP BY user_id")
  echo -e "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME_GUESSES guesses."
fi
#Get user's id
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
#Take number guess from user as input
echo -e "Guess the secret number between 1 and 1000:"
read GUESSED_NUMBER
NUMBER_OF_GUESSES=1
function integer_check {
  #While not integer
  while ! [[ "$GUESSED_NUMBER" =~ ^[0-9]+$ ]]
  do
    echo -e "That is not an integer, guess again:"
    read GUESSED_NUMBER
  done
}
#Check if input is integer
integer_check
#While guessed number does not match secret number
while [[ $GUESSED_NUMBER != $SECRET_NUMBER ]]
do
  #If secret number is higher than guessed number
  if [[ $GUESSED_NUMBER < $SECRET_NUMBER ]]
  then
    echo -e "It's higher than that, guess again:"
    read GUESSED_NUMBER
    #Check if input is integer
    integer_check
    #Increment number of guesses
    NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES+1))
  else
    #If secret number is lower than guessed number
    echo -e "It's lower than that, guess again:"
    read GUESSED_NUMBER
    #Check if input is integer
    integer_check
    #Increment number of guesses
    NUMBER_OF_GUESSES=$(($NUMBER_OF_GUESSES+1))
  fi
done
#When guessed number matches secret number
echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
#Add game details to games database
INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)")
#Increment number of games played for current user
GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID")+1
UPDATE_GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE user_id=$USER_ID")
