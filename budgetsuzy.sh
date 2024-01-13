#!/bin/bash

FILE=budget.csv
DATE=$(date +%F) # Current date in YYYY-MM-DD format

# Check if the CSV file exists, if not create it with headers
if [ ! -f "$FILE" ]; then
    echo "Date,Amount,Type,Due Date" > $FILE
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
    echo "$DATE,$amount,$type,$due_date" >> $FILE
    echo -e "\e[32mEntry added successfully!\e[0m"
}

# Function to view all entries
view_entries() {
    column -t -s, $FILE
}

# Main menu
while true; do
    clear
    echo "Welcome to your Budget Tracker!"
    echo "1. Add new entry"
    echo "2. View all entries"
    echo "3. Exit"
    echo "Choose an option:"
    read option

    case $option in
        1) add_entry ;;
        2) view_entries ;;
        3) break ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    read -p "Press Enter to continue..."
done
