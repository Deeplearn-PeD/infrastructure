#!/bin/bash
# Ollama Model Management Script
# Manage Ollama models on the Kwar-AI server via SSH
#
# Usage:
#   ./ollama-models.sh list                    - List installed models
#   ./ollama-models.sh pull <model>            - Pull/download a model
#   ./ollama-models.sh remove <model>          - Remove a model
#   ./ollama-models.sh show <model>            - Show model details
#   ./ollama-models.sh ps                      - Show running models

set -e

SSH_KEY="ssh_keys/kwar-ai-ssh-key"
SERVER="root@204.168.149.153"
CONTAINER="libby-ollama"

ssh_cmd() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SERVER" "$1"
}

ollama_cmd() {
    ssh_cmd "docker exec $CONTAINER ollama $1"
}

list_models() {
    echo "=== Ollama Models Installed ==="
    echo ""
    ollama_cmd "list"
    echo ""
    echo "Disk usage:"
    ssh_cmd "du -sh /var/lib/docker/volumes/libby_ollama-models 2>/dev/null || echo 'Volume not found'"
}

pull_model() {
    local model="$1"
    if [ -z "$model" ]; then
        echo "Error: Model name required"
        echo "Usage: $0 pull <model>"
        echo ""
        echo "Example models:"
        echo "  llama3.2:3b      - Llama 3.2 3B (2GB)"
        echo "  llama3.2:1b      - Llama 3.2 1B (1.3GB)"
        echo "  qwen2.5:3b       - Qwen 2.5 3B"
        echo "  mistral:latest   - Mistral 7B (4.1GB)"
        echo "  phi3:mini        - Phi-3 Mini (2.2GB)"
        exit 1
    fi
    
    echo "Pulling model: $model"
    echo "This may take a while depending on model size..."
    echo ""
    ollama_cmd "pull $model"
    echo ""
    echo "Model pulled successfully!"
}

remove_model() {
    local model="$1"
    if [ -z "$model" ]; then
        echo "Error: Model name required"
        echo "Usage: $0 remove <model>"
        echo ""
        echo "Installed models:"
        ollama_cmd "list" | tail -n +1
        exit 1
    fi
    
    echo "=== Model to remove ==="
    ollama_cmd "show $model --modelfile" 2>/dev/null | head -5 || echo "Model: $model"
    echo ""
    read -p "Are you sure you want to remove '$model'? [y/N] " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        ollama_cmd "rm $model"
        echo "Model '$model' removed successfully!"
    else
        echo "Cancelled."
    fi
}

show_model() {
    local model="$1"
    if [ -z "$model" ]; then
        echo "Error: Model name required"
        echo "Usage: $0 show <model>"
        echo ""
        echo "Installed models:"
        ollama_cmd "list"
        exit 1
    fi
    
    echo "=== Model Details: $model ==="
    echo ""
    ollama_cmd "show $model"
}

show_running() {
    echo "=== Running Models ==="
    echo ""
    ollama_cmd "ps"
}

case "${1:-list}" in
    list|ls)
        list_models
        ;;
    pull|download)
        pull_model "$2"
        ;;
    remove|rm|delete)
        remove_model "$2"
        ;;
    show|info)
        show_model "$2"
        ;;
    ps|running)
        show_running
        ;;
    help|--help|-h)
        echo "Ollama Model Management Script"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  list              List installed models (default)"
        echo "  pull <model>      Pull/download a model"
        echo "  remove <model>    Remove a model"
        echo "  show <model>      Show model details"
        echo "  ps                Show running models"
        echo "  help              Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 pull llama3.2:3b"
        echo "  $0 remove old-model"
        echo "  $0 show qwen3.5:4b"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
