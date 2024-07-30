# Checks if a specific command is available on your system.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Processes named command-line arguments into variables (e.g., --arg1 value1 --arg2 value2)
parse_args() {
    # $1 - The associative array name containing the argument definitions and default values
    # $2 - The arguments passed to the script
    local -n arg_defs=$1
    shift
    local args=("$@")

    # Assign default values first for defined arguments
    for arg_name in "${!arg_defs[@]}"; do
        declare -g "$arg_name"="${arg_defs[$arg_name]}"
    done

    # Process command-line arguments
    for ((i = 0; i < ${#args[@]}; i++)); do
        arg=${args[i]}
        if [[ $arg == --* ]]; then
            arg_name=${arg#--}
            next_index=$((i + 1))
            next_arg=${args[$next_index]}

            # Check if the argument is defined in arg_defs
            if [[ -z ${arg_defs[$arg_name]+_} ]]; then
                # Argument not defined, skip setting
                continue
            fi

            if [[ $next_arg == --* ]] || [[ -z $next_arg ]]; then
                # Treat as a flag
                declare -g "$arg_name"=1
            else
                # Treat as a value argument
                declare -g "$arg_name"="$next_arg"
                ((i++))
            fi
        else
            break
        fi
    done
}

# Sets a new value for a field in a YAML file using yq.
set_yaml_field() {
    local yaml_file="$1"
    local field_path="$2"
    local new_value="$3"

    yq eval ".${field_path} = \"${new_value}\"" "$yaml_file" -i
}

# Installs jq, for processing JSON files, if it is not already installed.
install_jq() {
    if ! command_exists jq; then
        echo "[jq] is not installed. Installing [jq]..." >&2
        sudo apt-get update && sudo apt-get install -y jq
        if command_exists jq; then
            echo "[jq] successfully installed." >&2
        else
            echo "Failed to install [jq]." >&2
            exit 1
        fi
    fi
}

# Installs yq, for processing YAML files, if it is not already installed.
install_yq() {
    if ! command_exists yq; then
        echo "[yq] is not installed. Installing [yq]..." >&2
        sudo apt-get update && sudo apt-get install -y jq # jq is a prerequisite for yq
        sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.25.1/yq_linux_amd64"
        sudo chmod +x /usr/local/bin/yq
        if command_exists yq; then
            echo "[yq] successfully installed." >&2
        else
            echo "Failed to install [yq]." >&2
            exit 1
        fi
    fi
}

# Installs Python and pip, if they are not already installed.
install_python() {
    if ! command_exists python3; then
        echo "[Python3] is not installed. Installing [Python3]..." >&2
        sudo apt-get update && sudo apt-get install -y python3
        if command_exists python3; then
            echo "[Python3] successfully installed." >&2
        else
            echo "Failed to install [Python3]." >&2
            exit 1
        fi
    fi

    if ! command_exists pip3; then
        echo "[pip3] is not installed. Installing [pip3]..." >&2
        sudo apt-get update && sudo apt-get install -y python3-pip
        if command_exists pip3; then
            echo "[pip3] successfully installed." >&2
        else
            echo "Failed to install [pip3]." >&2
            exit 1
        fi
    fi
}

# Installs the promptflow tools, if they are not already installed.
install_promptflow() {
    install_python

    if ! pip3 show promptflow >/dev/null 2>&1; then
        echo "Installing promptflow using pip3..." >&2
        pip3 install promptflow --upgrade
        if pip3 show promptflow >/dev/null 2>&1; then
            echo "[promptflow] successfully installed." >&2
        else
            echo "Failed to install [promptflow]." >&2
            exit 1
        fi
    fi

    if ! command_exists pfazure; then
        echo "[promptflow[azure]] is not installed. Installing [promptflow[azure]]..." >&2
        pip3 install promptflow[azure] --upgrade
        if command_exists pfazure; then
            echo "[promptflow[azure]] successfully installed." >&2
        else
            echo "Failed to install [promptflow[azure]]." >&2
            exit 1
        fi
    fi
}
