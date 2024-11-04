#!/bin/bash

# - Installer Interval Start Time
start_date=$(date +%T)

# - Set Configuration File
CONFIG_FILE="$(pwd)/configs"

# - Include Configuration File
if [ -e $CONFIG_FILE ]; then
    source $CONFIG_FILE
    echo -e "$(RKDBH)${SUCCESS}${CYAN}$0${RESET}Loaded Configuration File${RESET}"
else
    echo "No Configuration File Detected"
    terminate_shell
fi

# - Define Installation Logs Path
INSTALLATION_LOGS_PATH="$(pwd)/$INSTALLATION_LOGS"

# - Check if Installation Logs Already Exists
if [ -e "$INSTALLATION_LOGS_PATH" ]; then
    if [ "$OVERWRITE_EXIST_LOGS" -eq "1" ]; then
        # - Create Log File
        create_log_file $INSTALLATION_LOGS_PATH
        # - Show Message
        logger "$(RKDBH)${WARNING}${YELLOW_DARK}Overwriting Installation Log File${RESET}" $INSTALLATION_LOGS_PATH
        # - Empty Log File
        echo -e "\033[F" > "$INSTALLATION_LOGS_PATH"
    else
        # - Show Message
        logger "$(RKDBH)${WARNING}${YELLOW_DARK}Appending to Previous Log File${RESET}" $INSTALLATION_LOGS_PATH
    fi
else
    # - Create Log File
    create_log_file $INSTALLATION_LOGS_PATH
fi

# - Install PostgreSQL
logger "$(RKDBH)Installing PostgreSQL ..." $INSTALLATION_LOGS_PATH
echo "$RKDBH_USER_PASS" | sudo -S apt install postgresql postgresql-contrib -y
result=$?
if [ "$result" -eq 0 ]; then
    logger "$(RKDBH)${SUCCESS}PostgreSQL has been Installed${RESET}" $INSTALLATION_LOGS_PATH
else
    logger "$(RKDBH)${FAILED}Can Not Install PostgreSQL${RESET}" $INSTALLATION_LOGS_PATH
fi

# - Drop Existing Database
if [ "$DROP_EXISTING_DATABASE" -eq 1 ]; then
    sudo -u postgres psql -c 'drop database qssl' > /dev/null 2>&1
    sudo -u postgres psql -c 'REVOKE ALL PRIVILEGES ON SCHEMA public FROM qb;' > /dev/null 2>&1
    sudo -u postgres psql -c 'drop role qb' > /dev/null 2>&1
fi

# - Check PostgreSQL Service
postgresql_service_status=$(systemctl status postgresql --no-pager | grep -F 'Active' | awk '{print $2}')
result=$?
if [ "$result" -eq 0 ]; then
    if [ "$postgresql_service_status" == "active" ]; then
        logger "$(RKDBH)${SUCCESS}PostgreSQL Service is Active${RESET}" $INSTALLATION_LOGS_PATH
    elif [ "$postgresql_service_status" == "inactive" ]; then
        logger "$(RKDBH)${FAILED}PostgreSQL Service is Inactive${RESET}" $INSTALLATION_LOGS_PATH
        logger "$(RKDBH)Activating PostgreSQL Service ..." $INSTALLATION_LOGS_PATH
        sudo systemctl enable postgresql > /dev/null 2>&1
        result=$?
        if [ "$result" -eq 0 ]; then
            logger "$(RKDBH)${SUCCESS}PostgreSQL Service has been Activated${RESET}" $INSTALLATION_LOGS_PATH
        else
            logger "$(RKDBH)${FAILED}Can Not Activate PostgreSQL Service${RESET}" $INSTALLATION_LOGS_PATH
            terminate_shell
        fi
    fi
else
    check_error=$(systemctl status postgresql --no-pager | grep -F 'could not be found' | wc -l)
    if [ "$check_error" == 1 ]; then
        logger "$(RKDBH)${FAILED}Can Not Find PostgreSQL Service${RESET}" $INSTALLATION_LOGS_PATH
        terminate_shell
    else
        logger "$(RKDBH)${FAILED}Unknown Error in Getting Status of PostgreSQL Service${RESET}" $INSTALLATION_LOGS_PATH
        terminate_shell
    fi
fi

# - Check Database Availability
logger "$(RKDBH)Checking Database Availability ..." $INSTALLATION_LOGS_PATH
db_status=$(sudo -u postgres psql -l | grep $DATABASE_NAME | wc -l)
# - Check Database Status
if [ "$db_status" -eq 1 ]; then
    logger "$(RKDBH)${WARNING}Database ${CYAN_DARK}$DATABASE_NAME${RESET}is Already Available" $INSTALLATION_LOGS_PATH
    # - Drop Existing Database
    if [ "$DROP_EXISTING_DATABASE" -eq 1 ]; then
        logger "$(RKDBH)${WARNING}Removing Existing Database ${CYAN_DARK}$DATABASE_NAME${RESET}..." $INSTALLATION_LOGS_PATH
        sudo -u postgres psql -c "DROP DATABASE $DATABASE_NAME" > /dev/null 2>&1
        # - Check Database
        db_status=$(sudo -u postgres psql -l | grep $DATABASE_NAME | wc -l)
        # - Check if Database is Dropped
        if [ "$db_status" -eq 0 ]; then
            logger "$(RKDBH)${SUCCESS}Database ${CYAN_DARK}$DATABASE_NAME${RESET}has been Dropped" $INSTALLATION_LOGS_PATH
        else
            logger "$(RKDBH)${FAILED}Can Not Drop Database ${CYAN_DARK}$DATABASE_NAME${RESET}" $INSTALLATION_LOGS_PATH
            terminate_shell
        fi
    fi
else
    # - Create Database
    logger "$(RKDBH)Creating Database ${CYAN_DARK}$DATABASE_NAME${RESET}..." $INSTALLATION_LOGS_PATH
    sudo -u postgres createdb $DATABASE_NAME > /dev/null 2>&1
    # - Check Database Creation Status
    db_status=$(sudo -u postgres psql -l | grep $DATABASE_NAME | wc -l)
    # - Check Database Status
    if [ "$db_status" -eq 1 ]; then
        logger "$(RKDBH)${SUCCESS}Database ${CYAN_DARK}$DATABASE_NAME${RESET}has been Created" $INSTALLATION_LOGS_PATH
    else
        logger "$(RKDBH)${FAILED}Can Not Create Database ${CYAN_DARK}$DATABASE_NAME${RESET}" $INSTALLATION_LOGS_PATH
        logger "$(RKDBH)Database Should be Create Manually" $INSTALLATION_LOGS_PATH
        terminate_shell
    fi
fi

# - Check User and Role Availability
logger "$(RKDBH)Checking User ${CYAN_DARK}$DATABASE_USER${RESET}on Database ${CYAN_DARK}$DATABASE_NAME${RESET}..." $INSTALLATION_LOGS_PATH
db_user_status=$(sudo -u postgres psql -c '\du' | grep $DATABASE_USER | wc -l)
# - Check User Status
if [ "$db_user_status" -eq 1 ]; then
    # - Drop Role
    logger "$(RKDBH)${WARNING}Role ${CYAN_DARK}$DATABASE_USER${RESET}is Already Available" $INSTALLATION_LOGS_PATH
    logger "$(RKDBH)${WARNING}Dropping Role ..." $INSTALLATION_LOGS_PATH
    sudo -u postgres psql -c "DROP ROLE $DATABASE_USER" > /dev/null 2>&1
    result=$?
    # - Check Dropping Role Status
    if [ "$result" -eq 0 ]; then
        logger "$(RKDBH)${SUCCESS}Role ${CYAN_DARK}$DATABASE_USER${RESET}has been Dropped, Creating Role Again ..." $INSTALLATION_LOGS_PATH
    else
        logger "$(RKDBH)${WARNING}Can Not Drop Role ${CYAN_DARK}$DATABASE_USER${RESET}" $INSTALLATION_LOGS_PATH
        # - Check Privileges
        logger "$(RKDBH)Checking Privileges on Role ${CYAN_DARK}$DATABASE_USER${RESET} ..." $INSTALLATION_LOGS_PATH
        privileges_status=$(sudo -u postgres psql -c "SELECT datname, datacl FROM pg_database WHERE datname = '$DATABASE_NAME'" | grep -F "$DATABASE_USER=" | wc -l)
        # - Check Privileges Status
        if [ "$privileges_status" -eq 1 ]; then
            # - Revoke All Privileges of User on Database
            logger "$(RKDBH)${WARNING}There are Available Privileges That Makes Dropping Stop, Revoking All ..." $INSTALLATION_LOGS_PATH
            logger "$(RKDBH)Revoking All ${CYAN_DARK}$DATABASE_USER${RESET}Privileges on ${CYAN_DARK}$DATABASE_NAME${RESET}..." $INSTALLATION_LOGS_PATH
            sudo -u postgres psql -c "REVOKE ALL PRIVILEGES ON DATABASE $db_name FROM $DATABASE_USER;" > /dev/null 2>&1
            result=$?
            # - Check Revoking Status
            if [ "$result" -eq 0 ]; then
                logger "$(RKDBH)${SUCCESS}Revoked All ${CYAN_DARK}$DATABASE_USER${RESET}Privileges" $INSTALLATION_LOGS_PATH
                # - Drop Role
                logger "$(RKDBH)Dropping Role ${CYAN_DARK}$DATABASE_USER${RESET}..." $INSTALLATION_LOGS_PATH
                sudo -u postgres psql -c "DROP ROLE $DATABASE_USER" > /dev/null 2>&1
                logger "$(RKDBH)${SUCCESS}Role ${CYAN_DARK}$DATABASE_USER${RESET}has been Dropped" $INSTALLATION_LOGS_PATH
                logger "$(RKDBH)Creating Role Again ..." $INSTALLATION_LOGS_PATH
            else
                logger "$(RKDBH)${FAILED}Can Not Revoke Privileges of ${CYAN_DARK}$DATABASE_USER${RESET} on ${CYAN_DARK}$DATABASE_NAME${RESET}" $INSTALLATION_LOGS_PATH
                terminate_shell
            fi
        else
            logger "$(RKDBH)${WARNING}Can Not Find ${CYAN_DARK}$DATABASE_USER${RESET}Privileges on ${CYAN_DARK}$DATABASE_NAME${RESET}" $INSTALLATION_LOGS_PATH
            # terminate_shell
        fi
    fi
else
    logger "$(RKDBH)Creating Role ${CYAN_DARK}$DATABASE_USER${RESET}..." $INSTALLATION_LOGS_PATH
fi

# - Create Role
sudo -u postgres psql -c "CREATE ROLE $DATABASE_USER WITH PASSWORD '$DATABASE_PASS';" > /dev/null 2>&1
result=$?
# - Check Role Creation Status
if [ "$result" -eq 0 ]; then
    logger "$(RKDBH)${SUCCESS}Role ${CYAN_DARK}$DATABASE_USER${RESET}has been Created with Password ${CYAN_DARK}$DATABASE_PASS${RESET}" $INSTALLATION_LOGS_PATH
else
    logger "$(RKDBH)${FAILED}Can Not Create Role ${CYAN_DARK}$DATABASE_USER${RESET}" $INSTALLATION_LOGS_PATH
    terminate_shell
fi

# - Setup Role Permissions on Database
logger "$(RKDBH)Setting Up ${CYAN_DARK}$DATABASE_USER${RESET}Privileges on Database ${CYAN_DARK}$DATABASE_NAME${RESET} ..." $INSTALLATION_LOGS_PATH
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $DATABASE_USER" > /dev/null 2>&1
result=$?
# - Check Privileges Status
if [ "$result" -eq 0 ]; then
    logger "$(RKDBH)${SUCCESS}All Privileges has been Granted" $INSTALLATION_LOGS_PATH
else
    logger "$(RKDBH)${FAILED}Can Not Grant Privileges of ${CYAN_DARK}$DATABASE_NAME${RESET}to ${CYAN_DARK}$DATABASE_USER${RESET}" $INSTALLATION_LOGS_PATH
    terminate_shell
fi

# - Grant Login Access to User Specified
sudo -u postgres psql -d "$DATABASE_NAME" -c "ALTER ROLE $DATABASE_USER LOGIN" > /dev/null 2>&1
result=$?
if [ "$result" -eq 0 ]; then
    logger "$(RKDBH)${SUCCESS}Login Access Granted" $INSTALLATION_LOGS_PATH
else
    logger "$(RKDBH)${FAILED}Can Not Grant Login Access" $INSTALLATION_LOGS_PATH
    terminate_shell
fi

# - Set Postgres Password
logger "$(RKDBH)Setting Password of ${CYAN_DARK}postgres${RESET}to ${CYAN_DARK}$DATABASE_PASS${RESET} ..." $INSTALLATION_LOGS_PATH
sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$DATABASE_PASS'" > /dev/null 2>&1
resut=$?
# - Check Password Change Status
if [ "$result" -eq 0 ]; then
    logger "$(RKDBH)${SUCCESS}Password Changed" $INSTALLATION_LOGS_PATH
else
    logger "$(RKDBH)${FAILED}Can Not Change Password" $INSTALLATION_LOGS_PATH
    terminate_shell
fi

# - Set User Role Create Database Permission
logger "$(RKDBH)Setting Up ${CYAN_DARK}$DATABASE_USER${RESET}to Create Database ..." $INSTALLATION_LOGS_PATH
sudo -u postgres psql -c "GRANT CREATE ON SCHEMA public TO $DATABASE_USER" > /dev/null 2>&1
result=$?
# - Check Permission Status
if [ "$result" -eq 0 ]; then
    logger "$(RKDBH)${SUCCESS}Permission Granted" $INSTALLATION_LOGS_PATH
else
    logger "$(RKDBH)${FAILED}Can Not Grant Permission" $INSTALLATION_LOGS_PATH
    terminate_shell
fi

# # - Create Login Method Enum on Database
# logger "$(RKDBH)Creating Enum Login Method ..." $INSTALLATION_LOGS_PATH
# sudo -u postgres psql -d "$DATABASE_NAME" -c "CREATE TYPE LOGIN_METHOD AS ENUM ('google', 'apple');" > /dev/null 2>&1
# result=$?
# # - Check Enum Creation Status
# if [ "$result" -eq 0 ]; then
#     logger "$(RKDBH)${SUCCESS}Enum Login Method has been Created" $INSTALLATION_LOGS_PATH
# else
#     logger "$(RKDBH)${FAILED}Can Not Create Enum Login Method" $INSTALLATION_LOGS_PATH
#     terminate_shell
# fi