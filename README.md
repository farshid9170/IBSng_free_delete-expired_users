# IBSng User Management Script

## Overview

This Bash script provides a user-friendly command-line interface for managing users in IBSng (Interactive Bandwidth Server Next Generation). The script interacts with the PostgreSQL database of IBSng to perform actions such as deleting expired users based on absolute and relative expiration criteria.

## Features

- **Absolute Expiration:** Easily delete users whose absolute expiration date is older than a specified number of days.
- **Relative Expiration:** Efficiently manage users whose relative expiration date is older than a specified number of days from their first login.

## Usage Instructions
1. clone the project in your IBSng server
   
git clone https://github.com/farshid9170/IBSng_free_delete-expired_user.git

2. Run the script

bash delete_expired_users.sh

3. Select the expiration method (Absolute or Relative) and enter the respective number of days.
4. Confirm the deletion to initiate the background removal of expired users.
5. Monitor the progress and receive a notification when the users are successfully removed.

