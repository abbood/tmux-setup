#!/bin/bash
# Function to create a new session with windows if it doesn't exist
create_session() {
    local session_name=$1
    local initial_command=$2
    local second_window_name=$3
    # Check if session exists
    tmux has-session -t $session_name 2>/dev/null
    if [ $? != 0 ]; then
        # Create new session with first window named "cli"
        tmux new-session -d -s $session_name -n "cli"
        
        # Send initial command if provided
        if [ ! -z "$initial_command" ]; then
            tmux send-keys -t $session_name "$initial_command" C-m
            
            # Wait a bit for the cd command to complete
            sleep 0.5
            
            # Get the current working directory from the first window
            local current_dir=$(tmux display-message -p -t $session_name:0 "#{pane_current_path}")
            
            # Create additional windows in the same directory
            tmux new-window -t $session_name:1 -n "$second_window_name" -c "#{pane_current_path}"
            tmux new-window -t $session_name:2 -n "git" -c "#{pane_current_path}"
        else
            # If no initial command, just create the windows normally
            tmux new-window -t $session_name:1 -n "$second_window_name"
            tmux new-window -t $session_name:2 -n "git"
        fi
    fi
}
# Kill existing sessions if they exist
tmux kill-session -t web 2>/dev/null
tmux kill-session -t bac 2>/dev/null
tmux kill-session -t db 2>/dev/null
# Create web session
create_session "web" "web-siira" "web"
# Create bac session
create_session "bac" "bac-siira" "bac"
# Create db session and setup SSH tunnel
tmux new-session -d -s db -n "db"
tmux send-keys -t db "gcloud compute ssh --zone=us-central1-a staging-main-backend-node -- -NL 7777:10.226.0.3:5432" C-m
# Attach to the web session (you can change this to whichever session you prefer)
tmux attach-session -t web
