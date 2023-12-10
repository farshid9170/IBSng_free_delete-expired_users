  GNU nano 2.0.7                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      File: delete_user.sh                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  

#!/bin/bash

# Set your PostgreSQL connection details
PG_USER="ibs"
PG_DATABASE="IBSng"

# Function to handle relative expiration and count expired users
handle_relative_expiration() {
    days=$1

    # Count the number of expired users
    expired_user_count=$(psql -d $PG_DATABASE -U $PG_USER \
        -c "SELECT COUNT(*) FROM user_attrs WHERE attr_name = 'rel_exp_date' AND (CAST(attr_value AS integer) + (SELECT MAX(CAST(attr_value AS integer)) FROM user_attrs WHERE user_id = user_attrs.user_id AND attr_name = 'first_login')) < extract(epoch from current_timestamp - interval '$days days');" -t)

    # Create a list of user IDs
    user_id_list=$(psql -d $PG_DATABASE -U $PG_USER \
        -c "SELECT user_id FROM user_attrs WHERE attr_name = 'rel_exp_date' AND (CAST(attr_value AS integer) + (SELECT MAX(CAST(attr_value AS integer)) FROM user_attrs WHERE user_id = user_attrs.user_id AND attr_name = 'first_login')) < extract(epoch from current_timestamp - interval '$days days');" -t)

    echo "Number of expired users within $days days: $expired_user_count"
    echo "User ID list: $user_id_list"
}
# Function to handle absolute expiration and count expired users
handle_absolute_expiration() {
    days=$1

    # Count the number of expired users
    expired_user_count=$(psql -d $PG_DATABASE -U $PG_USER \
        -c "SELECT COUNT(*) FROM user_attrs WHERE attr_name = 'abs_exp_date' AND CAST(attr_value AS double precision) < extract(epoch from current_timestamp - interval '$days days');" -t)

    # Create a list of user IDs
    user_id_list=$(psql -d $PG_DATABASE -U $PG_USER \
        -c "SELECT user_id FROM user_attrs WHERE attr_name = 'abs_exp_date' AND CAST(attr_value AS double precision) < extract(epoch from current_timestamp - interval '$days days');" -t)

    echo "Number of expired users within $days days: $expired_user_count"
    echo "User ID list: $user_id_list"
}

# Function to handle deletion of expired users
delete_expired_users() {
    user_ids=$1

    # Display a "wait" message
    echo "Please wait. Removing users in the background..."

    # Your code to execute the series of SQL deletion statements in the background
    (psql -d $PG_DATABASE -U $PG_USER -c "BEGIN;"

    for user_id in $user_ids; do
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM user_attrs WHERE user_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM normal_users WHERE user_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM persistent_lan_users WHERE user_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM caller_id_users WHERE user_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM voip_users WHERE user_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM user_messages WHERE user_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM admin_messages WHERE user_id = $_user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM web_analyzer_log WHERE user_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM internet_bw_snapshot WHERE user_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM connection_log_details WHERE connection_log_id IN (SELECT connection_log_id FROM connection_log WHERE user_id = $user_id);"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM connection_log WHERE user_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM user_audit_log WHERE is_user = 't' AND object_id = $user_id;"
        psql -d $PG_DATABASE -U $PG_USER -c "DELETE FROM users WHERE user_id = $user_id;"
    done

    psql -d $PG_DATABASE -U $PG_USER -c "COMMIT;") > /dev/null 2>&1 &

    # Wait for the background process to complete
    wait

    # Restart the service without displaying output
    /etc/init.d/IBSng restart > /dev/null 2>&1

    # Display the success message and wait for user input
    dialog --msgbox "Users removed successfully." 8 60
}

# Function to confirm deletion
confirm_deletion() {
    local count=$1
    dialog --yesno "Are you sure you want to delete $count users?" 8 60
    return $?
}

# Main script
while true; do
    # Show main menu
    choice=$(dialog --menu "Select an action:" 12 40 3 \
        1 "Delete Expired Users" \
        2 "Exit" --stdout)

    case $choice in
        1)
            # Show submenu for delete options
            delete_choice=$(dialog --menu "Select deletion method:" 12 40 2 \
                1 "Relative Expire" \
                2 "Absolute Expire" --stdout)

            case $delete_choice in
                1)
                    # Show submenu for relative expiration options
                    days=$(dialog --inputbox "Enter the number of days for relative expiration:" 8 40 --stdout)

                    # Call the function to handle relative expiration and count expired users
                    handle_relative_expiration "$days"
                    expired_user_list="$user_id_list"

                    # Confirm deletion
                    confirm_deletion "$expired_user_count"
                    deletion_confirmation=$?

                    # If the user confirms deletion, proceed with deletion
                    if [ $deletion_confirmation -eq 0 ]; then
                        delete_expired_users "$expired_user_list"
                    else
                        dialog --msgbox "Deletion canceled." 8 60
                    fi
                    ;;
                2)
                    # Show submenu for absolute expiration options
                    days=$(dialog --inputbox "Enter the number of days for absolute expiration:" 8 40 --stdout)

                    # Call the function to handle absolute expiration and count expired users
                    handle_absolute_expiration "$days"
                    expired_user_list="$user_id_list"

                    # Confirm deletion
                    confirm_deletion "$expired_user_count"
                    deletion_confirmation=$?

                    # If the user confirms deletion, proceed with deletion
                    if [ $deletion_confirmation -eq 0 ]; then
                        delete_expired_users "$expired_user_list"
                    else
                        dialog --msgbox "Deletion canceled." 8 60
                    fi
                    ;;
                *)
                    # Go back to main menu if Cancel is pressed
                    continue
                    ;;
            esac
            ;;
        2)
            # Exit the script if Exit is selected
            break
            ;;
    esac
done




