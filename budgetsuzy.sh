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

# Function to edit an entry
edit_entry() {
    echo -e "${BLUE}Current entries with line numbers:${NC}"
    tail -n +2 "$FILE" | nl -w2 -s": "
    echo -e "${YELLOW}Enter the line number of the entry you want to edit:${NC}"
    read line_num
    let "line_num_to_edit=line_num+1"

    total_lines=$(wc -l < "$FILE")
    if ! [[ "$line_num" =~ ^[0-9]+$ ]] || [ "$line_num_to_edit" -gt "$total_lines" ] || [ "$line_num_to_edit" -eq 1 ]; then
        echo -e "${RED}Invalid selection. Please enter a valid line number.${NC}"
        return
    fi

    selected_entry=$(sed -n "${line_num_to_edit}p" "$FILE")
    IFS=, read -r curr_date curr_time curr_amount curr_category curr_payment_method curr_description curr_recurring curr_recurrence_period curr_due_date <<< "$selected_entry"

    echo "Editing entry. Press enter to keep current value."
    
    echo "Current Amount: $curr_amount"
    echo "Enter new amount (or press enter to keep current):"
    read new_amount
    new_amount=${new_amount:-$curr_amount}

    echo "Current Category: $curr_category"
    echo "Enter new category (or press enter to keep):"
    read new_category
    new_category=${new_category:-$curr_category}

    echo "Current Payment Method: $curr_payment_method"
    echo "Enter new payment method (or press enter to keep):"
    read new_payment_method
    new_payment_method=${new_payment_method:-$curr_payment_method}

    # Construct the new line
    new_line="$curr_date,$curr_time,$new_amount,$new_category,$new_payment_method,$curr_description,$curr_recurring,$curr_recurrence_period,$curr_due_date"

    # Replace the line in the file. Using a temporary file for safety.
    awk -v ln="$line_num_to_edit" -v new_line="$new_line" 'BEGIN {FS=OFS=","} NR == ln {$0=new_line} {print}' "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"

    echo -e "${GREEN}Entry updated successfully!${NC}"
}

calculate_totals() {
    start_date=$(date -j -f "%Y-%m-%d" "$1" +%Y%m%d)
    end_date=$(date -j -f "%Y-%m-%d" "$2" +%Y%m%d)

    echo "Start Date (YYYYMMDD): $start_date"
    echo "End Date (YYYYMMDD): $end_date"

    total=0
    while IFS=, read -r date time amount category payment_method description recurring recurrence_period due_date
    do
        # Skip the header row
        if [[ $due_date != "Due Date" ]]; then
            # Convert the due_date to YYYYMMDD format for comparison
            if [[ $due_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                due_date_comp=$(date -j -f "%Y-%m-%d" "$due_date" +%Y%m%d)
                echo "Processing Due Date: $due_date_comp, Amount: $amount"
                # Compare the integer values of the due_dates
                if (( due_date_comp >= start_date && due_date_comp <= end_date )); then
                    echo "Adding $amount to total"
                    total=$(echo "$total + $amount" | bc)
                fi
            fi
        fi
    done < "$FILE"
    echo "Total expenses from $(date -j -f "%Y%m%d" "$start_date" +%F) to $(date -j -f "%Y%m%d" "$end_date" +%F): $total"
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
    echo "8. Edit an entry"
    echo "9. Exit"
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
        8) edit_entry ;;
        9) break ;;
        *) echo -e "${RED}Invalid option yo. Please try again.${NC}" ;;
    esac
done
