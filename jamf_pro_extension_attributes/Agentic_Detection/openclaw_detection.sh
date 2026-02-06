#!/bin/bash

###########################################################################################################################
#
# Copyright 2026, Jamf Software LLC.
# This work is licensed under the terms of the Jamf Source Available License
# https://github.com/jamf/scripts/blob/main/LICENCE.md
#
###########################################################################################################################

################################################################################
# Detects OpenClaw installations including:
# - CLI binary (npm/pnpm global install)
# - LaunchAgent services (current and legacy)
# - macOS companion app
# - Configuration directories
# - Running processes/gateway
# - Docker containers
################################################################################

# Initialize detection arrays
declare -a findings

# Function to check if a command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Function to check Docker containers
check_docker() {
	if command_exists docker; then
		# Check for running OpenClaw containers
		if docker ps --format '{{.Names}}' 2>/dev/null | grep -qi openclaw; then
			container_names=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i openclaw | tr '\n' ', ' | sed 's/,$//')
			findings+=("Docker-Running:${container_names}")
		fi
		
		# Check for stopped OpenClaw containers
		if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qi openclaw; then
			all_containers=$(docker ps -a --format '{{.Names}}' 2>/dev/null | grep -i openclaw | wc -l | tr -d ' ')
			if [[ $all_containers -gt 0 ]]; then
				findings+=("Docker-Containers:${all_containers}")
			fi
		fi
	fi
}

# Function to check for CLI installation
check_cli() {
	# Check common npm global bin locations
	local npm_prefix=""
	
	if command_exists npm; then
		npm_prefix=$(npm prefix -g 2>/dev/null)
		if [[ -f "${npm_prefix}/bin/openclaw" ]]; then
			# Get version if possible
			local version=$("${npm_prefix}/bin/openclaw" --version 2>/dev/null | head -1)
			findings+=("CLI-NPM:${npm_prefix}/bin/openclaw")
			[[ -n "$version" ]] && findings+=("Version:${version}")
		fi
	fi
	
	# Check standard locations
	if [[ -f "/usr/local/bin/openclaw" ]]; then
		findings+=("CLI-Binary:/usr/local/bin/openclaw")
	fi
	
	# Check if openclaw command is available in PATH
	if command_exists openclaw && [[ ! " ${findings[@]} " =~ " CLI-" ]]; then
		local openclaw_path=$(which openclaw 2>/dev/null)
		findings+=("CLI-Path:${openclaw_path}")
	fi
}

# Function to check macOS app
check_macos_app() {
	if [[ -d "/Applications/OpenClaw.app" ]]; then
		# Get app version from Info.plist if available
		local app_version=""
		if [[ -f "/Applications/OpenClaw.app/Contents/Info.plist" ]]; then
			app_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "/Applications/OpenClaw.app/Contents/Info.plist" 2>/dev/null)
		fi
		findings+=("App:/Applications/OpenClaw.app")
		[[ -n "$app_version" ]] && findings+=("AppVersion:${app_version}")
	fi
	
	# Check user Applications folders
	for user_home in /Users/*; do
		[[ ! -d "$user_home" ]] && continue
		[[ "$user_home" == "/Users/Shared" ]] && continue
		
		if [[ -d "${user_home}/Applications/OpenClaw.app" ]]; then
			local username=$(basename "$user_home")
			findings+=("App-User:${username}")
		fi
	done
}

# Function to check LaunchAgents
check_launch_agents() {
	for user_home in /Users/*; do
		[[ ! -d "$user_home" ]] && continue
		[[ "$user_home" == "/Users/Shared" ]] && continue
		
		local username=$(basename "$user_home")
		local launch_agents_dir="${user_home}/Library/LaunchAgents"
		
		# Check current naming convention
		if [[ -f "${launch_agents_dir}/bot.molt.gateway.plist" ]]; then
			# Check if it's loaded
			local is_loaded=$(sudo -u "$username" launchctl list 2>/dev/null | grep -c "bot.molt.gateway")
			if [[ $is_loaded -gt 0 ]]; then
				findings+=("LaunchAgent-Active:${username}")
			else
				findings+=("LaunchAgent-Installed:${username}")
			fi
		fi
		
		# Check legacy naming convention
		if [[ -f "${launch_agents_dir}/com.openclaw.gateway.plist" ]]; then
			findings+=("LaunchAgent-Legacy:${username}")
		fi
		
		# Check for profile-based agents (bot.molt.*)
		local profile_agents=$(find "${launch_agents_dir}" -name "bot.molt.*.plist" 2>/dev/null | wc -l | tr -d ' ')
		if [[ $profile_agents -gt 0 ]]; then
			findings+=("LaunchAgent-Profiles:${username}:${profile_agents}")
		fi
	done
}

# Function to check configuration directories
check_config_dirs() {
	local found_configs=0
	
	for user_home in /Users/*; do
		[[ ! -d "$user_home" ]] && continue
		[[ "$user_home" == "/Users/Shared" ]] && continue
		
		local username=$(basename "$user_home")
		local config_dir="${user_home}/.openclaw"
		
		if [[ -d "$config_dir" ]]; then
			found_configs=$((found_configs + 1))
			
			# Check for main config file
			if [[ -f "${config_dir}/openclaw.json" ]]; then
				findings+=("Config:${username}")
				
				# Check workspace
				if [[ -d "${config_dir}/workspace" ]]; then
					findings+=("Workspace:${username}")
				fi
				
				# Check for credentials
				if [[ -f "${config_dir}/credentials/profiles.json" ]]; then
					findings+=("Credentials:${username}")
				fi
			fi
		fi
		
		# Check for workspace directory (could be separate)
		if [[ -d "${user_home}/openclaw/workspace" ]]; then
			findings+=("Workspace-Alt:${username}")
		fi
	done
	
	[[ $found_configs -gt 0 ]] && findings+=("ConfigDirs:${found_configs}")
}

# Function to check running processes
check_processes() {
	# Check for openclaw processes
	if pgrep -f "openclaw" >/dev/null 2>&1; then
		local process_count=$(pgrep -f "openclaw" | wc -l | tr -d ' ')
		findings+=("Process-Running:${process_count}")
		
		# Check if Gateway is running on default port
		if lsof -i :18789 >/dev/null 2>&1; then
			findings+=("Gateway-Port:18789")
		fi
	fi
	
	# Check for node processes that might be running openclaw
	if pgrep -f "node.*openclaw" >/dev/null 2>&1; then
		local node_count=$(pgrep -f "node.*openclaw" | wc -l | tr -d ' ')
		[[ $node_count -gt 0 ]] && findings+=("Node-Process:${node_count}")
	fi
}

# Function to check for source installation
check_source_install() {
	for user_home in /Users/*; do
		[[ ! -d "$user_home" ]] && continue
		[[ "$user_home" == "/Users/Shared" ]] && continue
		
		local username=$(basename "$user_home")
		
		# Check common locations for git clone
		for dir in "${user_home}/openclaw" "${user_home}/Documents/openclaw" "${user_home}/Projects/openclaw" "${user_home}/src/openclaw"; do
			if [[ -d "$dir" ]] && [[ -f "$dir/package.json" ]]; then
				# Verify it's actually openclaw by checking package.json
				if grep -q '"name": "openclaw"' "$dir/package.json" 2>/dev/null; then
					findings+=("Source:${username}:${dir}")
				fi
			fi
		done
	done
}

# Run all checks
check_docker
check_cli
check_macos_app
check_launch_agents
check_config_dirs
check_processes
check_source_install

# Format and return results
if [[ ${#findings[@]} -eq 0 ]]; then
	echo "<result>Not Installed</result>"
else
	# Join findings with semicolon separator
	result=$(IFS=';'; echo "${findings[*]}")
	echo "<result>${result}</result>"
fi

exit 0
