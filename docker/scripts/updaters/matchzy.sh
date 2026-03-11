#!/bin/bash
# Custom CS2 Match Plugin installer for K4ryuu-style egg

source /utils/logging.sh

install_custom_matchplugin() {
    local enabled="${INSTALL_MATCHZY:-0}"
    enabled="$(echo "$enabled" | tr '[:upper:]' '[:lower:]')"

    local BASE_DIR="./game/csgo/addons/counterstrikesharp"
    local PLUGINS_DIR="$BASE_DIR/plugins"
    local CONFIG_DIR="$BASE_DIR/config/plugins"
    local DISABLED_DIR="./game/.disabled_css_plugins"
    local TEMP_DIR="/tmp/matchplugin"
    local ZIP_URL="https://cdn.gnet.mn/nxs-cs/repo/cs2-css-match-main.zip"

    # CHANGE THIS if your extracted plugin folder has a different name
    local PLUGIN_NAME="MatchPlugin"

    mkdir -p "$TEMP_DIR" "$PLUGINS_DIR" "$CONFIG_DIR" "$DISABLED_DIR"
    rm -rf "$TEMP_DIR"/*

    case "$enabled" in
        1|true|yes|on)
            ;;
        *)
            if [ -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
                rm -rf "$DISABLED_DIR/$PLUGIN_NAME"
                mv "$PLUGINS_DIR/$PLUGIN_NAME" "$DISABLED_DIR/$PLUGIN_NAME"
                log_message "Custom Match Plugin disabled" "success"
            else
                log_message "Custom Match Plugin already disabled" "info"
            fi
            return 0
            ;;
    esac

    if [ ! -d "$BASE_DIR" ]; then
        log_message "CounterStrikeSharp is not installed. Install CSHARP first." "error"
        return 1
    fi

    log_message "Downloading custom match plugin ZIP..." "info"
    if ! curl -L --fail -o "$TEMP_DIR/plugin.zip" "$ZIP_URL"; then
        log_message "Failed to download plugin ZIP" "error"
        return 1
    fi

    log_message "Extracting plugin ZIP..." "info"
    if ! unzip -o "$TEMP_DIR/plugin.zip" -d "$TEMP_DIR/extracted" >/dev/null; then
        log_message "Failed to extract plugin ZIP" "error"
        return 1
    fi

    # Find plugin/config folders regardless of extra parent directory
    local extracted_plugin_dir
    local extracted_config_dir

    extracted_plugin_dir=$(find "$TEMP_DIR/extracted" -type d -path "*/addons/counterstrikesharp/plugins/$PLUGIN_NAME" | head -n1)
    extracted_config_dir=$(find "$TEMP_DIR/extracted" -type d -path "*/addons/counterstrikesharp/config/plugins/$PLUGIN_NAME" | head -n1)

    if [ -z "$extracted_plugin_dir" ] || [ ! -d "$extracted_plugin_dir" ]; then
        log_message "Could not find plugins/$PLUGIN_NAME inside ZIP" "error"
        log_message "Check ZIP folder structure and PLUGIN_NAME value" "error"
        return 1
    fi

    # Restore if previously disabled
    if [ -d "$DISABLED_DIR/$PLUGIN_NAME" ] && [ ! -d "$PLUGINS_DIR/$PLUGIN_NAME" ]; then
        mv "$DISABLED_DIR/$PLUGIN_NAME" "$PLUGINS_DIR/$PLUGIN_NAME"
    fi

    # Replace plugin files
    rm -rf "$PLUGINS_DIR/$PLUGIN_NAME"
    cp -rf "$extracted_plugin_dir" "$PLUGINS_DIR/" || {
        log_message "Failed to copy plugin files" "error"
        return 1
    }

    # Copy config if present; preserve existing configs
    if [ -n "$extracted_config_dir" ] && [ -d "$extracted_config_dir" ]; then
        if [ ! -d "$CONFIG_DIR/$PLUGIN_NAME" ]; then
            cp -rf "$extracted_config_dir" "$CONFIG_DIR/" || {
                log_message "Failed to copy plugin config files" "warning"
            }
        else
            cp -rn "$extracted_config_dir/." "$CONFIG_DIR/$PLUGIN_NAME/" 2>/dev/null || true
        fi
    fi

    log_message "Custom Match Plugin installed successfully" "success"
    return 0
}

install_custom_matchplugin
