#!/bin/bash

# Script to manually grant microphone permission to Yakety.app
# WARNING: This requires SIP (System Integrity Protection) to be disabled
# Use at your own risk!

echo "=== Grant Microphone Permission to Yakety ==="
echo ""
echo "⚠️  WARNING: This script requires SIP to be disabled!"
echo "⚠️  It directly modifies the TCC database."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run with sudo"
    echo "Usage: sudo $0"
    exit 1
fi

# Get the actual user's home directory (not root's)
USER_HOME=$(eval echo ~$SUDO_USER)
TCC_DB="$USER_HOME/Library/Application Support/com.apple.TCC/TCC.db"

# Check if TCC database exists
if [ ! -f "$TCC_DB" ]; then
    echo "❌ TCC database not found at: $TCC_DB"
    exit 1
fi

# Check current status
echo "Current microphone permissions for Yakety:"
sqlite3 "$TCC_DB" "SELECT client, auth_value,
    CASE auth_value
        WHEN 0 THEN 'Denied'
        WHEN 2 THEN 'Allowed'
        ELSE 'Unknown'
    END as status
    FROM access
    WHERE service='kTCCServiceMicrophone'
    AND client='com.yakety.app';" 2>/dev/null

echo ""
echo "Granting microphone permission to com.yakety.app..."

# Insert or update the permission
# auth_value: 0=denied, 2=allowed
# auth_reason: 4=user set
# flags: 1=user set (not system)
sqlite3 "$TCC_DB" "INSERT OR REPLACE INTO access (
    service,
    client,
    client_type,
    auth_value,
    auth_reason,
    auth_version,
    csreq,
    policy_id,
    indirect_object_identifier_type,
    indirect_object_identifier,
    indirect_object_code_identity,
    flags,
    last_modified
) VALUES (
    'kTCCServiceMicrophone',
    'com.yakety.app',
    0,
    2,
    4,
    1,
    NULL,
    NULL,
    0,
    'UNUSED',
    NULL,
    0,
    $(date +%s)
);" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Permission granted successfully!"

    # Kill tccd to force reload
    echo "Restarting privacy database daemon..."
    killall tccd 2>/dev/null

    echo ""
    echo "New status:"
    sqlite3 "$TCC_DB" "SELECT client,
        CASE auth_value
            WHEN 0 THEN 'Denied'
            WHEN 2 THEN 'Allowed'
            ELSE 'Unknown'
        END as status
        FROM access
        WHERE service='kTCCServiceMicrophone'
        AND client='com.yakety.app';" 2>/dev/null
else
    echo "❌ Failed to update permission"
    echo "Make sure SIP is disabled and try again"
fi

echo ""
echo "Done!"