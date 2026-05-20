#!/bin/bash


# ─────────────────────────────────────────
# To-Do List Application
# Course: Operating Systems CPE212/EC342
# ─────────────────────────────────────────


# VARIABLES
TASKS_FILE="tasks.csv"
HEADER="ID,Title,Status,Date"


# FUNCTION: Initialize the CSV file
init_file() {
    if [[ ! -f "$TASKS_FILE" ]]; then
        echo "$HEADER" > "$TASKS_FILE"
        echo "Task file created: $TASKS_FILE"
    fi
}


# FUNCTION: Get the next available task ID
get_next_id() {
    local max_id=0
    mapfile -t lines < "$TASKS_FILE"
    for line in "${lines[@]}"; do
        local id
        id=$(echo "$line" | cut -d',' -f1)
        if [[ "$id" =~ ^[0-9]+$ ]] && (( id > max_id )); then
            max_id=$id
        fi
    done
    echo $(( max_id + 1 ))
}


# FUNCTION: Check if a task ID exists
id_exists() {
    local target_id="$1"
    grep -q "^${target_id}," "$TASKS_FILE"
}


# FUNCTION: Add a new task
add_task() {
    echo ""
    echo "=== Add New Task ==="

    local title=""
    while [[ -z "$title" ]]; do
        read -rp "Enter task title: " title
        if [[ -z "$title" ]]; then
            echo "ERROR: Title cannot be empty. Please try again."
        fi
    done

    local date=""
    while true; do
        read -rp "Enter due date (YYYY-MM-DD) or press Enter to skip: " date
        if [[ -z "$date" ]]; then
            date="N/A"
            break
        elif [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            break
        else
            echo "ERROR: Invalid date format. Use YYYY-MM-DD."
        fi
    done

    local new_id
    new_id=$(get_next_id)
    local status="Pending"

    echo "${new_id},${title},${status},${date}" >> "$TASKS_FILE"
    echo "SUCCESS: Task #${new_id} added!"
}


# FUNCTION: View all tasks
view_tasks() {
    echo ""
    echo "=== All Tasks ==="

    mapfile -t lines < "$TASKS_FILE"
    local count=0

    printf "%-5s %-30s %-12s %-12s\n" "ID" "Title" "Status" "Date"
    echo "-------------------------------------------------------------"

    for line in "${lines[@]}"; do
        if [[ "$line" == "$HEADER" ]]; then
            continue
        fi

        local id title status date
        id=$(echo "$line"     | cut -d',' -f1)
        title=$(echo "$line"  | cut -d',' -f2)
        status=$(echo "$line" | cut -d',' -f3)
        date=$(echo "$line"   | cut -d',' -f4)

        if [[ "$status" == "Completed" ]]; then
            printf "\e[32m%-5s %-30s %-12s %-12s\e[0m\n" "$id" "$title" "$status" "$date"
        else
            printf "%-5s %-30s %-12s %-12s\n" "$id" "$title" "$status" "$date"
        fi

        (( count++ ))
    done

    if (( count == 0 )); then
        echo "No tasks found. Add one first!"
    else
        echo "-------------------------------------------------------------"
        echo "Total tasks: $count"
    fi
}


# FUNCTION: Edit an existing task
edit_task() {
    echo ""
    echo "=== Edit Task ==="
    view_tasks

    local target_id=""
    while [[ -z "$target_id" ]]; do
        read -rp "Enter task ID to edit: " target_id
        if [[ -z "$target_id" ]]; then
            echo "ERROR: ID cannot be empty."
        elif ! [[ "$target_id" =~ ^[0-9]+$ ]]; then
            echo "ERROR: ID must be a number."
            target_id=""
        elif ! id_exists "$target_id"; then
            echo "ERROR: Task ID #${target_id} does not exist."
            target_id=""
        fi
    done

    local current_line
    current_line=$(grep "^${target_id}," "$TASKS_FILE")
    local cur_title cur_status cur_date
    cur_title=$(echo "$current_line"  | cut -d',' -f2)
    cur_status=$(echo "$current_line" | cut -d',' -f3)
    cur_date=$(echo "$current_line"   | cut -d',' -f4)

    echo "Current Title: $cur_title"
    read -rp "New title (press Enter to keep current): " new_title
    [[ -z "$new_title" ]] && new_title="$cur_title"

    echo "Current Date: $cur_date"
    local new_date=""
    while true; do
        read -rp "New date YYYY-MM-DD (press Enter to keep current): " new_date
        if [[ -z "$new_date" ]]; then
            new_date="$cur_date"
            break
        elif [[ "$new_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            break
        else
            echo "ERROR: Invalid date format. Use YYYY-MM-DD."
        fi
    done

    local tmp_file
    tmp_file=$(mktemp)
    while IFS= read -r line; do
        local line_id
        line_id=$(echo "$line" | cut -d',' -f1)
        if [[ "$line_id" == "$target_id" ]]; then
            echo "${target_id},${new_title},${cur_status},${new_date}"
        else
            echo "$line"
        fi
    done < "$TASKS_FILE" > "$tmp_file"
    mv "$tmp_file" "$TASKS_FILE"

    echo "SUCCESS: Task #${target_id} updated."
}


# FUNCTION: Delete a task
delete_task() {
    echo ""
    echo "=== Delete Task ==="
    view_tasks

    local target_id=""
    while [[ -z "$target_id" ]]; do
        read -rp "Enter task ID to delete: " target_id
        if [[ -z "$target_id" ]]; then
            echo "ERROR: ID cannot be empty."
        elif ! [[ "$target_id" =~ ^[0-9]+$ ]]; then
            echo "ERROR: ID must be a number."
            target_id=""
        elif ! id_exists "$target_id"; then
            echo "ERROR: Task ID #${target_id} does not exist."
            target_id=""
        fi
    done

    local task_title
    task_title=$(grep "^${target_id}," "$TASKS_FILE" | cut -d',' -f2)
    read -rp "Are you sure you want to delete \"${task_title}\"? (y/n): " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        local tmp_file
        tmp_file=$(mktemp)
        grep -v "^${target_id}," "$TASKS_FILE" > "$tmp_file"
        mv "$tmp_file" "$TASKS_FILE"
        echo "SUCCESS: Task #${target_id} deleted."
    else
        echo "Delete cancelled."
    fi
}


# FUNCTION: Mark a task as completed
mark_completed() {
    echo ""
    echo "=== Mark Task as Completed ==="
    view_tasks

    local target_id=""
    while [[ -z "$target_id" ]]; do
        read -rp "Enter task ID to mark as completed: " target_id
        if [[ -z "$target_id" ]]; then
            echo "ERROR: ID cannot be empty."
        elif ! [[ "$target_id" =~ ^[0-9]+$ ]]; then
            echo "ERROR: ID must be a number."
            target_id=""
        elif ! id_exists "$target_id"; then
            echo "ERROR: Task ID #${target_id} does not exist."
            target_id=""
        fi
    done

    local current_status
    current_status=$(grep "^${target_id}," "$TASKS_FILE" | cut -d',' -f3)
    if [[ "$current_status" == "Completed" ]]; then
        echo "INFO: Task #${target_id} is already Completed."
        return
    fi

    local tmp_file
    tmp_file=$(mktemp)
    while IFS= read -r line; do
        local line_id
        line_id=$(echo "$line" | cut -d',' -f1)
        if [[ "$line_id" == "$target_id" ]]; then
            local t d
            t=$(echo "$line" | cut -d',' -f2)
            d=$(echo "$line" | cut -d',' -f4)
            echo "${target_id},${t},Completed,${d}"
        else
            echo "$line"
        fi
    done < "$TASKS_FILE" > "$tmp_file"
    mv "$tmp_file" "$TASKS_FILE"

    echo "SUCCESS: Task #${target_id} marked as Completed."
}


# FUNCTION: Display the main menu
show_menu() {
    echo ""
    echo "╔══════════════════════════════════╗"
    echo "║       TO-DO LIST APPLICATION     ║"
    echo "╠══════════════════════════════════╣"
    echo "║  1. Add Task                     ║"
    echo "║  2. View All Tasks               ║"
    echo "║  3. Edit Task                    ║"
    echo "║  4. Delete Task                  ║"
    echo "║  5. Mark Task as Completed       ║"
    echo "║  6. Exit                         ║"
    echo "╚══════════════════════════════════╝"
    echo -n "  Choose an option [1-6]: "
}


# FUNCTION: Main loop
main() {
    init_file
    echo "Welcome to the To-Do List App!"

    local choice
    while true; do
        show_menu
        read -r choice

        case "$choice" in
            1) add_task ;;
            2) view_tasks ;;
            3) edit_task ;;
            4) delete_task ;;
            5) mark_completed ;;
            6)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "ERROR: Invalid option. Please choose between 1 and 6."
                ;;
        esac
    done
}

# Run the program
main
