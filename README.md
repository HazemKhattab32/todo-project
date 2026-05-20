# To-Do List Application
## Course: Operating Systems CPE212/EC342
## Pharos University in Alexandria

## How to Run
1. Open terminal in the project folder
2. Make the script executable:
   chmod +x todo.sh
3. Run the script:
   ./todo.sh

## Implemented Features
- Add Task (title + date, with input validation)
- View All Tasks (formatted table, green for completed)
- Edit/Update Task (modify title or date by ID)
- Delete Task (by ID, with confirmation prompt)
- Mark Task as Completed (by ID)
- Persistent storage via tasks.csv
- Full error handling and input validation

## Bash Concepts Used
- Variables: TASKS_FILE, HEADER, local variables
- Conditionals: if/elif/else and case statement
- Loops: while loops for menu and input validation, for loop for arrays
- Functions: add_task, view_tasks, edit_task, delete_task, mark_completed
- Arrays: mapfile loads CSV lines into arrays
- File Handling: cut, grep, redirection, mktemp
- Input Validation and Error Handling throughout

## Group Members
- Name: [Nour Mohamed]       ID: [202302744]
- Name: [Hazem Khattab]    ID: [202302469]

## Notes
- tasks.csv is automatically created on first run
- Completed tasks appear highlighted in green
- Date format must be YYYY-MM-DD
- Press Ctrl+C to force exit at any time
