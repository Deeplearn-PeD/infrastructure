#!/bin/bash
set -e

CONTAINER_NAME="epidbot"
WORKDIR="/opt/kwar-ai/epidbot"
REMOTE_HOST="204.168.149.153"
SSH_USER="${SSH_USER:-root}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSH_KEY="${SSH_KEY:-${SCRIPT_DIR}/../ssh_keys/kwar-ai-ssh-key}"

ssh_cmd() {
    ssh -i "${SSH_KEY}" "${SSH_USER}@${REMOTE_HOST}" "$@"
}

usage() {
    echo "EpidBot User Management"
    echo ""
    echo "Usage: $0 <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  list                          List all users"
    echo "  create <user> <email>         Create a new admin user (prompts for password)"
    echo "  create-with-password <user> <password> <email>  Create user non-interactively"
    echo "  passwd <user>                 Change user password"
    echo "  delete <user>                 Delete a user"
    echo "  show-credentials              Show default admin credentials"
    echo "  help                          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 create researcher researcher@institute.org"
    echo "  $0 create-with-password researcher securepass123 researcher@institute.org"
    echo "  $0 passwd admin"
    echo "  $0 delete researcher"
    echo ""
    echo "Note: Commands run on remote host ${REMOTE_HOST} inside the epidbot Docker container"
    echo ""
    echo "Environment variables:"
    echo "  SSH_USER  - SSH user (default: root)"
    echo "  SSH_KEY   - SSH private key path (default: ${SCRIPT_DIR}/../ssh_keys/kwar-ai-ssh-key)"
    exit 1
}

check_container() {
    if ! ssh_cmd "docker ps --format '{{.Names}}' | grep -q \"^${CONTAINER_NAME}\$\""; then
        echo "Error: EpidBot container is not running on ${REMOTE_HOST}"
        echo "Start it with: ssh -i ${SSH_KEY} ${SSH_USER}@${REMOTE_HOST} 'cd ${WORKDIR} && docker-compose up -d'"
        exit 1
    fi
}

cmd_list() {
    check_container
    echo "Listing EpidBot users..."
    echo ""
    ssh_cmd "docker exec -it ${CONTAINER_NAME} uv run python auth_cli.py list"
}

cmd_create() {
    check_container
    local user="$1"
    local email="$2"
    
    if [ -z "$user" ] || [ -z "$email" ]; then
        echo "Error: Missing arguments"
        echo "Usage: $0 create <username> <email>"
        exit 1
    fi
    
    echo "Creating user: $user ($email)"
    echo "You will be prompted for a password..."
    echo ""
    ssh_cmd -t "docker exec -it ${CONTAINER_NAME} uv run python auth_cli.py create-admin << EOF
${user}
${email}
EOF"
}

cmd_create_with_password() {
    check_container
    local user="$1"
    local password="$2"
    local email="$3"
    
    if [ -z "$user" ] || [ -z "$password" ] || [ -z "$email" ]; then
        echo "Error: Missing arguments"
        echo "Usage: $0 create-with-password <username> <password> <email>"
        exit 1
    fi
    
    echo "Creating user: $user ($email)..."
    ssh_cmd "docker exec -i ${CONTAINER_NAME} uv run python auth_cli.py create-admin << EOF
${user}
${password}
${password}
${email}
EOF"
    echo "User created successfully!"
}

cmd_passwd() {
    check_container
    local user="$1"
    
    if [ -z "$user" ]; then
        echo "Error: Missing username"
        echo "Usage: $0 passwd <username>"
        exit 1
    fi
    
    echo "Changing password for user: $user"
    ssh_cmd -t "docker exec -it ${CONTAINER_NAME} uv run python auth_cli.py passwd \"$user\""
}

cmd_delete() {
    check_container
    local user="$1"
    
    if [ -z "$user" ]; then
        echo "Error: Missing username"
        echo "Usage: $0 delete <username>"
        exit 1
    fi
    
    echo "Warning: This will permanently delete user '$user'!"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh_cmd "docker exec -it ${CONTAINER_NAME} uv run python auth_cli.py delete \"$user\""
        echo "User deleted."
    else
        echo "Cancelled."
    fi
}

cmd_show_credentials() {
    check_container
    echo "Default admin credentials:"
    echo ""
    ssh_cmd "docker exec ${CONTAINER_NAME} cat /data/.admin_credentials 2>/dev/null" || {
        echo "No credentials file found (may have been deleted or not yet created)"
    }
}

case "${1:-}" in
    list)
        cmd_list
        ;;
    create)
        cmd_create "$2" "$3"
        ;;
    create-with-password)
        cmd_create_with_password "$2" "$3" "$4"
        ;;
    passwd)
        cmd_passwd "$2"
        ;;
    delete)
        cmd_delete "$2"
        ;;
    show-credentials)
        cmd_show_credentials
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        usage
        ;;
esac
