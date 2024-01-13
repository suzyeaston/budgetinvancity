#!/bin/bash

DIR="$(dirname "$(realpath "$0")")"
FILE="$DIR/budget.csv"
DATE=$(date +%F) # Current date in YYYY-MM-DD format
TIME=$(date +%T) # Current time

# Function to initialize or reset the CSV file
initialize_csv() {
    echo "Date,Time,Amount,Type,Due Date" > $FILE
}

# Check if the CSV file exists, if not create it with headers
if [ ! -f "$FILE" ]; then
    initialize_csv
fi

# Function to add a new entry
add_entry() {
    echo "Enter the amount:"
    read amount
    echo "Enter the type of bill:"
    read type
    echo "Enter the due date (YYYY-MM-DD):"
    read due_date

    # Append the new entry to the file
    echo "$DATE,$TIME,$amount,$type,$due_date" >> $FILE
    echo -e "\e[32mEntry added successfully!\e[0m"
}

# Function to view all entries
view_entries() {
    if [ -s $FILE ]; then
        echo "Here are your current entries:"
        cat $FILE
        echo "Press Enter to return to the menu..."
        read
    else
        echo "No entries to display."
        read
    fi
}

# Function to delete all entries
delete_all_entries() {
    echo "Are you sure you want to delete all entries? (yes/no)"
    read confirmation
    if [[ $confirmation == "yes" ]]; then
        initialize_csv
        echo -e "\e[31mAll entries have been deleted.\e[0m"
    else
        echo "Deletion cancelled."
    fi
}

# Main menu
while true; do
    echo "Welcome to your Budget Tracker!"
    echo "1. Add new entry"
    echo "2. View all entries"
    echo "3. Delete all entries"
    echo "4. Exit"
    echo "Choose an option:"
    read option

    case $option in
        1) add_entry ;;
        2) view_entries ;;
        3) delete_all_entries ;;
        4) break ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done
