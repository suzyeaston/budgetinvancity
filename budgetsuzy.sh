#!/bin/bash

DIR="$(dirname "$(realpath "$0")")"
FILE="$DIR/budget.csv"
DATE=$(date +%F) # Current date in YYYY-MM-DD format
TIME=$(date +%T) # Current time

# Colour codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

# Function to initialize or reset the CSV file
initialize_csv() {
    echo "Date,Time,Amount,Category,Payment Method,Description,Recurring,Recurrence Period,Due Date" > "$FILE"
}

# Function to create a new version of the CSV file
create_new_version() {
    mv "$FILE" "${FILE%.csv}-$(date +%F-%T).csv"
    initialize_csv
    echo -e "${BLUE}New version created and old data archived.${NC}"
}

# Check if the CSV file exists, if not create it with headers
if [ ! -f "$FILE" ]; then
    initialize_csv
fi

# Function to add a new entry
add_entry() {
    echo -e "${YELLOW}Enter the amount:${NC}"
    read amount
    echo -e "${YELLOW}Enter the category (e.g., Groceries, Rent, Entertainment):${NC}"
    read category
    echo -e "${YELLOW}Enter the payment method (e.g., Debit, Credit Card, PayPal):${NC}"
    read payment_method
    echo -e "${YELLOW}Enter a description or note (optional):${NC}"
    read description
    echo -e "${YELLOW}Is this a recurring expense? (yes/no):${NC}"
    read recurring
    if [[ $recurring == "yes" ]]; then
        echo -e "${YELLOW}Enter the recurrence period (e.g., Monthly, Bi-Weekly):${NC}"
        read recurrence_period
    else
        recurrence_period="N/A"
    fi
    echo -e "${YELLOW}Enter the due date (YYYY-MM-DD):${NC}"
    read due_date

    # Append the new entry to the file
    echo "$DATE,$TIME,$amount,$category,$payment_method,$description,$recurring,$recurrence_period,$due_date" >> "$FILE"
    if [[ $recurring == "yes" ]]; then
        # Calculate and add recurring entries
        for i in {1..6}; do
             next_due_date=$(date -j -v+${i}m -f "%Y-%m-%d" "$due_date" +%Y-%m-%d)
             echo "$DATE,$TIME,$amount,$category,$payment_method,$description,$recurring,$recurrence_period,$next_due_date" >> "$FILE"
        done
    fi
    echo -e "${GREEN}Entry added successfully!${NC}"
}

# Function to view all entries
view_entries() {
    if [ -s "$FILE" ]; then
        echo -e "${BLUE}Here are your current entries:${NC}"
        cat "$FILE"
        echo "Press Enter to return to the menu..."
        read
    else
        echo -e "${RED}No entries to display.${NC}"
        read
    fi
}

# Function to delete all entries
delete_all_entries() {
    echo -e "${RED}Are you sure you want to delete all entries? (yes/no)${NC}"
    read confirmation
    if [[ $confirmation == "yes" ]]; then
        initialize_csv
        echo -e "${RED}All entries have been deleted.${NC}"
    else
        echo "Deletion cancelled."
    fi
}

calculate_totals() {
    start_date=$(date -j -f "%Y-%m-%d" "$1" +%s)
    end_date=$(date -j -f "%Y-%m-%d" "$2" +%s)

    total=0
    while IFS=, read -r date time amount category payment_method description recurring recurrence_period due_date
    do
        # Check if date is in the correct format to avoid conversion errors
        if [[ $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            date_ts=$(date -j -f "%Y-%m-%d" "$date" +%s)
            if [[ "$date_ts" -gt "$start_date" && "$date_ts" -le "$end_date" ]]; then
                total=$(echo "$total + $amount" | bc)
            fi
        fi
    done < "$FILE"
    echo -e "${GREEN}Total expenses from $(date -j -f "%s" "$start_date" +%F) to $(date -j -f "%s" "$end_date" +%F): $total${NC}"
}

# Function to calculate and display real-time totals
display_totals() {
    total=0
    while IFS=, read -r date time amount category payment_method description recurring recurrence_period due_date
    do
        # Ensure amount is numeric to avoid bc parse errors
        if [[ $amount =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            total=$(echo "$total + $amount" | bc)
        fi
    done < "$FILE"
    echo -e "${GREEN}Total expenses recorded: $total${NC}"
}

highlight_upcoming_dues() {
    # Calculate upcoming date for the next 7 days using BSD `date` syntax
    upcoming_date=$(date -v+7d +%F)
    upcoming_date_ts=$(date -j -f "%Y-%m-%d" "$upcoming_date" +%s)
    current_date_ts=$(date +%s)

    echo -e "${YELLOW}Upcoming dues in the next 7 days (including today):${NC}"
    # Skip the header row and start reading from the second line
    tail -n +2 "$FILE" | while IFS=, read -r date time amount category payment_method description recurring recurrence_period due_date
    do
        # Check if due_date is in the correct format to avoid trying to convert non-date values
        if [[ $due_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            due_date_ts=$(date -j -f "%Y-%m-%d" "$due_date" +%s 2> /dev/null)
            if [[ "$due_date_ts" -ge "$current_date_ts" && "$due_date_ts" -le "$upcoming_date_ts" ]]; then
                echo -e "${RED}Due $due_date: $amount for $category${NC}"
            fi
        fi
    done
}

# Main menu
while true; do
    echo -e "${BLUE}Welcome to your Budget Tracker!${NC}"
    echo "1. Add new entry"
    echo "2. View all entries"
    echo "3. Delete all entries"
    echo "4. Create new version"
    echo "5. Calculate totals for a period"
    echo "6. Display total expenses"
    echo "7. Highlight upcoming dues"
    echo "8. Exit"
    echo "Choose an option:"
    read option

    case $option in
        1) add_entry ;;
        2) view_entries ;;
        3) delete_all_entries ;;
        4) create_new_version ;;
        5) echo "Enter the start date (YYYY-MM-DD):"
           read start_date
           echo "Enter the end date (YYYY-MM-DD):"
           read end_date
           calculate_totals "$start_date" "$end_date" ;;
        6) display_totals ;;
        7) highlight_upcoming_dues ;;
        8) break ;;
        *) echo -e "${RED}Invalid option yo. Please try again.${NC}" ;;
    esac
done
