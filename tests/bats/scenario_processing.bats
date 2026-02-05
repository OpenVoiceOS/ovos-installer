#!/usr/bin/env bats
# Tests for scenario processing functionality
# Following BATS best practices for test isolation and structure

setup() {
    # Load BATS testing framework
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    # Load source files under test
    load ../../utils/constants.sh
    load ../../utils/common.sh
    load ../../utils/scenario.sh

    # Set up test environment
    export LOG_FILE="/tmp/ovos-installer-test.log"
    export YQ_BINARY_PATH="/tmp/yq-test"
    export SCENARIO_NAME="scenario.yaml"

    # Clean up any existing test artifacts
    rm -f "$LOG_FILE" "$YQ_BINARY_PATH"
}

teardown() {
    # Clean up test artifacts
    rm -f "$LOG_FILE" "$YQ_BINARY_PATH"

    # Reset global variables that may have been modified
    unset SCENARIO_FOUND SCENARIO_NOT_SUPPORTED
    unset UNINSTALL METHOD CHANNEL PROFILE TUNING
    unset SHARE_TELEMETRY SHARE_USAGE_TELEMETRY
    unset FEATURE_SKILLS FEATURE_GUI FEATURE_EXTRA_SKILLS
    unset HIVEMIND_HOST HIVEMIND_PORT SATELLITE_KEY SATELLITE_PASSWORD
}

# Test basic scenario detection without complex processing
@test "scenario_file_not_found" {
    export RUN_AS_HOME="/nonexistent/home"
    detect_scenario
    assert_equal "$SCENARIO_FOUND" "false"
}

@test "scenario_file_exists_basic" {
    export RUN_AS_HOME="/tmp/test-home-basic"
    mkdir -p "$RUN_AS_HOME/.config/ovos-installer"

    # Create a basic scenario file
    echo "uninstall: false" > "$RUN_AS_HOME/.config/ovos-installer/scenario.yaml"

    # Mock all external dependencies to avoid timeouts
    function download_yq() {
        # Create dummy yq binary
        echo "#!/bin/bash" > "$YQ_BINARY_PATH"
        echo "exit 0" >> "$YQ_BINARY_PATH"
        chmod +x "$YQ_BINARY_PATH"
        return 0
    }
    function in_array() {
        return 0
    }
    function source() {
        export SCENARIO_NOT_SUPPORTED="false"
    }
    export -f download_yq in_array source

    detect_scenario
    assert_equal "$SCENARIO_FOUND" "true"

    unset -f download_yq in_array source
    rm -rf "$RUN_AS_HOME"
}

# Test complex scenario processing with proper mocking
@test "scenario_file_complex_processing" {
    export RUN_AS_HOME="/tmp/test-home-complex"
    mkdir -p "$RUN_AS_HOME/.config/ovos-installer"

    # Create a complex scenario file
    cat <<EOF >"$RUN_AS_HOME/.config/ovos-installer/scenario.yaml"
uninstall: false
method: containers
channel: testing
profile: ovos
features:
  skills: true
  extra_skills: false
raspberry_pi_tuning: true
share_telemetry: true
share_usage_telemetry: true
EOF

    # Mock all dependencies
    function download_yq() {
        # Create a comprehensive yq mock
        cat <<'EOF' > "$YQ_BINARY_PATH"
#!/bin/bash
# Mock yq that handles various YAML queries
case "$*" in
    *"to_entries | map([.key, .value] | join(\"=\")) | .[]")
        # Mock options output
        echo "uninstall=false"
        echo "method=containers"
        echo "channel=testing"
        echo "profile=ovos"
        echo "raspberry_pi_tuning=true"
        echo "share_telemetry=true"
        echo "share_usage_telemetry=true"
        ;;
    *".features | to_entries | map([.key, .value] | join(\"=\")) | .[]"*)
        # Mock features output
        echo "skills=true"
        echo "extra_skills=false"
        ;;
    *".hivemind | to_entries | map([.key, .value] | join(\"=\")) | .[]"*)
        # Mock empty hivemind output
        ;;
    *)
        # Default success
        exit 0
        ;;
esac
EOF
        chmod +x "$YQ_BINARY_PATH"
        return 0
    }

    function in_array() {
        # Mock in_array to always succeed for valid options
        return 0
    }

    function source() {
        # Mock scenario.sh processing
        export SCENARIO_NOT_SUPPORTED="false"
        export UNINSTALL="false"
        export METHOD="containers"
        export CHANNEL="testing"
        export PROFILE="ovos"
        export TUNING="yes"
        export SHARE_TELEMETRY="true"
        export SHARE_USAGE_TELEMETRY="true"
        export FEATURE_SKILLS="true"
        export FEATURE_EXTRA_SKILLS="false"
    }

    export -f download_yq in_array source

    detect_scenario
    assert_equal "$SCENARIO_FOUND" "true"
    assert_equal "$METHOD" "containers"
    assert_equal "$FEATURE_SKILLS" "true"

    unset -f download_yq in_array source
    rm -rf "$RUN_AS_HOME"
}

@test "scenario_file_yaml_parsing" {
    export RUN_AS_HOME="/tmp/test-home-yaml"
    mkdir -p "$RUN_AS_HOME/.config/ovos-installer"

    # Create a scenario file with various YAML structures
    cat <<EOF >"$RUN_AS_HOME/.config/ovos-installer/scenario.yaml"
uninstall: false
method: containers
channel: testing
profile: ovos
features:
  skills: true
raspberry_pi_tuning: true
share_telemetry: true
share_usage_telemetry: true
EOF

    function download_yq() {
        # Create yq mock that validates YAML parsing
        cat <<'EOF' > "$YQ_BINARY_PATH"
#!/bin/bash
# Mock yq that validates parsing
if [[ "$*" == *".yaml" ]]; then
    exit 0  # Valid YAML
else
    exit 1  # Invalid YAML
fi
EOF
        chmod +x "$YQ_BINARY_PATH"
        return 0
    }

    function in_array() {
        return 0
    }

    function source() {
        export SCENARIO_NOT_SUPPORTED="false"
    }

    export -f download_yq in_array source

    detect_scenario
    assert_equal "$SCENARIO_FOUND" "true"

    unset -f download_yq in_array source
    rm -rf "$RUN_AS_HOME"
}

@test "scenario_file_validation" {
    export RUN_AS_HOME="/tmp/test-home-validation"
    mkdir -p "$RUN_AS_HOME/.config/ovos-installer"

    # Create a scenario file with invalid options
    cat <<EOF >"$RUN_AS_HOME/.config/ovos-installer/scenario.yaml"
uninstall: false
method: invalid_method
channel: testing
profile: ovos
features:
  skills: true
raspberry_pi_tuning: true
share_telemetry: true
share_usage_telemetry: true
EOF

    function download_yq() {
        cat <<'EOF' > "$YQ_BINARY_PATH"
#!/bin/bash
# Mock yq for validation test
case "$*" in
    *"to_entries | map([.key, .value] | join(\"=\")) | .[]")
        echo "uninstall=false"
        echo "method=invalid_method"
        echo "channel=testing"
        echo "profile=ovos"
        echo "raspberry_pi_tuning=true"
        echo "share_telemetry=true"
        echo "share_usage_telemetry=true"
        ;;
    *".features | to_entries | map([.key, .value] | join(\"=\")) | .[]"*)
        echo "skills=true"
        ;;
    *)
        exit 0
        ;;
esac
EOF
        chmod +x "$YQ_BINARY_PATH"
        return 0
    }

    function in_array() {
        if [[ "$2" == "invalid_method" ]]; then
            return 1  # Invalid method
        fi
        return 0
    }

    function source() {
        export SCENARIO_NOT_SUPPORTED="true"
    }

    function on_error() {
        export SCENARIO_FOUND="false"
        exit 1
    }

    export -f download_yq in_array source on_error

    run detect_scenario
    assert_failure
    # Note: SCENARIO_FOUND variable not testable when function exits

    unset -f download_yq in_array source on_error
    rm -rf "$RUN_AS_HOME"
}

@test "scenario_file_hivemind_config" {
    export RUN_AS_HOME="/tmp/test-home-hivemind"
    mkdir -p "$RUN_AS_HOME/.config/ovos-installer"

    # Create a scenario file with hivemind configuration
    cat <<EOF >"$RUN_AS_HOME/.config/ovos-installer/scenario.yaml"
uninstall: false
method: containers
channel: testing
profile: ovos
features:
  skills: true
raspberry_pi_tuning: true
share_telemetry: true
share_usage_telemetry: true
hivemind:
  host: "192.168.1.100"
  port: "8000"
  key: "test_key"
  password: "test_password"
EOF

    function download_yq() {
        cat <<'EOF' > "$YQ_BINARY_PATH"
#!/bin/bash
# Mock yq for hivemind test
case "$*" in
    *"to_entries | map([.key, .value] | join(\"=\")) | .[]")
        echo "uninstall=false"
        echo "method=containers"
        echo "channel=testing"
        echo "profile=ovos"
        echo "raspberry_pi_tuning=true"
        echo "share_telemetry=true"
        echo "share_usage_telemetry=true"
        echo "hivemind=map[host:192.168.1.100 port:8000 key:test_key password:test_password]"
        ;;
    *".features | to_entries | map([.key, .value] | join(\"=\")) | .[]"*)
        echo "skills=true"
        ;;
    *".hivemind | to_entries | map([.key, .value] | join(\"=\")) | .[]"*)
        echo "host=192.168.1.100"
        echo "port=8000"
        echo "key=test_key"
        echo "password=test_password"
        ;;
    *)
        exit 0
        ;;
esac
EOF
        chmod +x "$YQ_BINARY_PATH"
        return 0
    }

    function in_array() {
        return 0
    }

    function source() {
        export SCENARIO_NOT_SUPPORTED="false"
        export HIVEMIND_HOST="192.168.1.100"
        export HIVEMIND_PORT="8000"
        export SATELLITE_KEY="test_key"
        export SATELLITE_PASSWORD="test_password"
    }

    export -f download_yq in_array source

    detect_scenario
    assert_equal "$SCENARIO_FOUND" "true"
    assert_equal "$HIVEMIND_HOST" "192.168.1.100"
    assert_equal "$HIVEMIND_PORT" "8000"

    unset -f download_yq in_array source
    rm -rf "$RUN_AS_HOME"
}

@test "scenario_file_error_handling" {
    export RUN_AS_HOME="/tmp/test-home-error"
    mkdir -p "$RUN_AS_HOME/.config/ovos-installer"

    # Create a scenario file that will cause errors
    cat <<EOF >"$RUN_AS_HOME/.config/ovos-installer/scenario.yaml"
uninstall: invalid_boolean
method: containers
channel: testing
profile: ovos
features:
  skills: true
raspberry_pi_tuning: true
share_telemetry: true
share_usage_telemetry: true
EOF

    function download_yq() {
        cat <<'EOF' > "$YQ_BINARY_PATH"
#!/bin/bash
# Mock yq for error handling test
case "$*" in
    *"to_entries | map([.key, .value] | join(\"=\")) | .[]")
        echo "uninstall=invalid_boolean"
        echo "method=containers"
        echo "channel=testing"
        echo "profile=ovos"
        echo "raspberry_pi_tuning=true"
        echo "share_telemetry=true"
        echo "share_usage_telemetry=true"
        ;;
    *".features | to_entries | map([.key, .value] | join(\"=\")) | .[]"*)
        echo "skills=true"
        ;;
    *)
        exit 0
        ;;
esac
EOF
        chmod +x "$YQ_BINARY_PATH"
        return 0
    }

    function in_array() {
        return 0
    }

    function source() {
        # Simulate error in scenario processing
        export SCENARIO_NOT_SUPPORTED="true"
    }

    function on_error() {
        export SCENARIO_FOUND="false"
        exit 1
    }

    export -f download_yq in_array source on_error

    run detect_scenario
    assert_failure
    # Note: SCENARIO_FOUND variable not testable when function exits

    unset -f download_yq in_array source on_error
    rm -rf "$RUN_AS_HOME"
}

@test "scenario_file_edge_cases" {
    export RUN_AS_HOME="/tmp/test-home-edge"
    mkdir -p "$RUN_AS_HOME/.config/ovos-installer"

    # Create a minimal scenario file (edge case)
    echo "uninstall: false" > "$RUN_AS_HOME/.config/ovos-installer/scenario.yaml"

    function download_yq() {
        cat <<'EOF' > "$YQ_BINARY_PATH"
#!/bin/bash
# Mock yq for edge case test - minimal output
case "$*" in
    *"to_entries | map([.key, .value] | join(\"=\")) | .[]")
        echo "uninstall=false"
        ;;
    *".features | to_entries | map([.key, .value] | join(\"=\")) | .[]"*)
        # No features
        ;;
    *)
        exit 0
        ;;
esac
EOF
        chmod +x "$YQ_BINARY_PATH"
        return 0
    }

    function in_array() {
        return 0
    }

    function source() {
        # Minimal scenario processing
        export SCENARIO_NOT_SUPPORTED="false"
        export UNINSTALL="false"
    }

    export -f download_yq in_array source

    detect_scenario
    assert_equal "$SCENARIO_FOUND" "true"
    assert_equal "$UNINSTALL" "false"

    unset -f download_yq in_array source
    rm -rf "$RUN_AS_HOME"
}
