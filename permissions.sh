#!/bin/bash

# Check permissions for Yakety in macOS TCC database

# Parse command line arguments
CLEAR=false
for arg in "$@"; do
    case $arg in
        clear)
            CLEAR=true
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [clear]"
            echo "  clear - Clear all permissions for Yakety"
            exit 1
            ;;
    esac
done

if [ "$CLEAR" = true ]; then
    echo "=== Clearing Yakety Permissions ==="
    echo ""
    
    # Re-run with sudo if not already root
    if [ "$EUID" -ne 0 ]; then
        echo "This requires sudo access. You may be prompted for your password."
        echo ""
        exec sudo "$0" "$@"
    fi
    
    # Clear permissions for yakety-cli
    echo "Clearing permissions for yakety-cli..."
    tccutil reset Accessibility yakety-cli 2>/dev/null
    tccutil reset ListenEvent yakety-cli 2>/dev/null
    tccutil reset Microphone yakety-cli 2>/dev/null
    
    # Clear permissions for Yakety.app (bundle ID: com.yakety.app)
    echo "Clearing permissions for Yakety.app..."
    tccutil reset Accessibility com.yakety.app 2>/dev/null
    tccutil reset ListenEvent com.yakety.app 2>/dev/null
    tccutil reset Microphone com.yakety.app 2>/dev/null
    
    echo ""
    echo "✅ All Yakety permissions have been cleared"
    exit 0
fi

echo "=== Checking Yakety Permissions ==="
echo ""

# Re-run with sudo if not already root
if [ "$EUID" -ne 0 ]; then
    echo "This requires sudo access to read the TCC database."
    echo "You may be prompted for your password."
    echo ""
    exec sudo "$0" "$@"
fi

# Define services to check
SERVICES=("kTCCServiceAccessibility:Accessibility" "kTCCServiceListenEvent:Input Monitoring" "kTCCServiceMicrophone:Microphone")

# Check system database
echo "📋 System Permissions (/Library):"
echo "---------------------------------"
for service_pair in "${SERVICES[@]}"; do
    IFS=':' read -r service name <<< "$service_pair"
    echo ""
    echo "$name:"
    found=false
    sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
        "SELECT client, auth_value FROM access WHERE service='$service' AND (client LIKE '%yakety%' OR client='com.yakety.app');" 2>/dev/null | \
    while IFS='|' read -r client auth_value; do
        if [ -n "$client" ]; then
            found=true
            status="❌ Denied"
            [ "$auth_value" = "2" ] && status="✅ Granted"
            echo "  $client: $status"
        fi
    done
    if [ "$found" = false ]; then
        # Check if any results were found
        result=$(sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
            "SELECT COUNT(*) FROM access WHERE service='$service' AND (client LIKE '%yakety%' OR client='com.yakety.app');" 2>/dev/null)
        [ "$result" = "0" ] || [ -z "$result" ] && echo "  No entries found"
    fi
done

# Check user database
echo ""
echo ""
echo "📱 User Permissions (~Library):"
echo "-------------------------------"
if [ -f "$HOME/Library/Application Support/com.apple.TCC/TCC.db" ]; then
    for service_pair in "${SERVICES[@]}"; do
        IFS=':' read -r service name <<< "$service_pair"
        echo ""
        echo "$name:"
        found=false
        sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
            "SELECT client, auth_value FROM access WHERE service='$service' AND (client LIKE '%yakety%' OR client='com.yakety.app');" 2>/dev/null | \
        while IFS='|' read -r client auth_value; do
            if [ -n "$client" ]; then
                found=true
                status="❌ Denied"
                [ "$auth_value" = "2" ] && status="✅ Granted"
                echo "  $client: $status"
            fi
        done
        if [ "$found" = false ]; then
            result=$(sqlite3 "$HOME/Library/Application Support/com.apple.TCC/TCC.db" \
                "SELECT COUNT(*) FROM access WHERE service='$service' AND (client LIKE '%yakety%' OR client='com.yakety.app');" 2>/dev/null)
            [ "$result" = "0" ] || [ -z "$result" ] && echo "  No entries found"
        fi
    done
else
    echo "  User TCC database not found"
fi

echo ""
echo ""
echo "💡 To clear permissions: ./permissions.sh clear"