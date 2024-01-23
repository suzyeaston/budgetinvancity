#!/bin/bash

DIR="$(dirname "$(realpath "$0")")"
FILE="$DIR/budget.csv"
DATE=$(date +%F) # Current date in YYYY-MM-DD format
TIME=$(date +%T) # Current time

# Function to initialize or reset the CSV file
initialize_csv() {
    echo "Date,Time,Amount,Category,Payment Method,Description,Recurring,Recurrence Period,Type,Due Date" > $FILE
}

# Function to create a new version of the CSV file
create_new_version() {
    mv "$FILE" "${FILE%.csv}-$(date +%F-%T).csv"
    initialize_csv
    echo -e "\e[34mNew version created and old data archived.\e[0m"
}

# Check if the CSV file exists, if not create it with headers
if [ ! -f "$FILE" ]; then
    initialize_csv
fi

# Function to add a new entry
add_entry() {
    echo "Enter the amount:"
    read amount
    echo "Enter the category (e.g., Groceries, Rent, Entertainment):"
    read category
    echo "Enter the payment method (e.g., Cash, Credit Card, PayPal):"
    read payment_method
    echo "Enter a description or note (optional):"
    read description
    echo "Is this a recurring expense? (yes/no):"
    read recurring
    if [[ $recurring == "yes" ]]; then
        echo "Enter the recurrence period (e.g., Monthly, Bi-Monthly):"
        read recurrence_period
    else
        recurrence_period="N/A"
    fi
    echo "Enter the type of bill:"
    read type
    echo "Enter the due date (YYYY-MM-DD):"
    read due_date

    # Append the new entry to the file
    echo "$DATE,$TIME,$amount,$category,$payment_method,$description,$recurring,$recurrence_period,$type,$due_date" >> $FILE
    if [[ $recurring == "yes" ]]; then
        # Calculate and add recurring entries
        for i in {1..6}; do
            # Adjustments are needed for other recurrence periods.
            next_due_date=$(date -j -v+${i}m -f "%Y-%m-%d" "$due_date" +%F)
            echo "$DATE,$TIME,$amount,$category,$payment_method,$description,$recurring,$recurrence_period,$type,$next_due_date" >> $FILE
        done
    fi
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
    echo "4. Create new version"
    echo "5. Exit"
    echo "Choose an option:"
    read option

    case $option in
        1) add_entry ;;
        2) view_entries ;;
        3) delete_all_entries ;;
        4) create_new_version ;;
        5) break ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done
