#!/bin/bash

####################################
# SALON APPOINTMENT SCHEDULING APP #
####################################

# To execute this script, run the following command in your terminal:
# ./salon.sh




# ==================================================
# INITIAL VARIABLES
# ==================================================

DB=salon
PSQL="psql --username=freecodecamp --dbname=$DB --tuples-only -c"




# ================================================
# FUNCTIONS
# ================================================


FORMAT_VARCHAR() {
	echo $1 | sed -r 's/^ *| *$//g'
}


SELECT_SERVICE() {
	# get list of services
	ALL_SERVICES=$($PSQL "
		SELECT * FROM services ORDER BY service_id;
	")

	# add list header
	if [[ $1 ]]
	then
		echo -e "\n$1"
	fi

	# display list
	echo -e "Here are all the services we offer:\n"
	echo "$ALL_SERVICES" | while read SERVICE_ID BAR SERVICE_OPTION
	do
		echo "$SERVICE_ID) $SERVICE_OPTION"
	done

	# get service_id_selected
	echo -e "\nWhat would you like to schedule? Please input the number of the service you selected."
	read SERVICE_ID_SELECTED

	# get service_name
	SERVICE_NAME=$($PSQL "
		SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;
	")

	# if service doesn't exist
	if [[ -z $SERVICE_NAME ]]
	then
		SELECT_SERVICE "I could not find that service."
	fi

	# format service_name
	SERVICE_NAME=$(FORMAT_VARCHAR "$SERVICE_NAME")
}


GET_CUSTOMER_DATA() {
	# get customer_phone
	echo -e "\nLet's schedule a $SERVICE_NAME. What is your phone number?"
	read CUSTOMER_PHONE

	# get customer_id
	CUSTOMER_ID=$($PSQL "
		SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';
	")

	# if customer doesn't exist
	if [[ -z $CUSTOMER_ID ]]
	then
		# get new customer_name
		echo -e "\nI don't have a record for that phone number. What is your name?"
		read CUSTOMER_NAME

		# insert new customer
		INSERT_CUSTOMER_RESULT=$($PSQL "
			INSERT INTO customers(name, phone)
			VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE');
		")

		# get new customer_id
		if [[ $INSERT_CUSTOMER_RESULT == "INSERT 0 1" ]]
		then
			CUSTOMER_ID=$($PSQL "
				SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';
			")
		fi

	else
		# get customer_name
		CUSTOMER_NAME=$($PSQL "
			SELECT name FROM customers WHERE customer_id=$CUSTOMER_ID;
		")
	fi

	# format customer_name
	CUSTOMER_NAME=$(FORMAT_VARCHAR "$CUSTOMER_NAME")
}


MAKE_APPT() {
	SELECT_SERVICE
	GET_CUSTOMER_DATA

	# get service_time
	echo -e "\nThank you. At what time would you like to schedule your $SERVICE_NAME?"
	read SERVICE_TIME

	# insert new appointment
	INSERT_APPT_RESULT=$($PSQL "
		INSERT INTO appointments(service_id, customer_id, time)
		VALUES ($SERVICE_ID_SELECTED, $CUSTOMER_ID, '$SERVICE_TIME');
	")

	# confirmation message
	if [[ $INSERT_APPT_RESULT == "INSERT 0 1" ]]
	then
		echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
	fi
}




# =================================================
# POINT OF ENTRY
# =================================================

echo -e "\n~~~~~ EMERY SALON ~~~~~\n"
echo -e "Welcome to Emery Salon's scheduling app!"

MAKE_APPT
