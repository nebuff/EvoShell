#!/bin/bash

# EvoShell Test Script
# Basic functionality tests

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
}

echo "EvoShell Test Suite"
echo "==================="

# Test 1: Check if the binary exists
print_test "Checking if evoshell binary exists..."
if [ -f "./evoshell" ]; then
    print_pass "Binary found"
else
    print_fail "Binary not found"
    exit 1
fi

# Test 2: Check if the binary is executable
print_test "Checking if binary is executable..."
if [ -x "./evoshell" ]; then
    print_pass "Binary is executable"
else
    print_fail "Binary is not executable"
    exit 1
fi

# Test 3: Basic compilation test
print_test "Testing compilation..."
if make clean && make; then
    print_pass "Compilation successful"
else
    print_fail "Compilation failed"
    exit 1
fi

echo ""
echo -e "${GREEN}All tests passed! EvoShell is ready to use.${NC}"
echo "To run EvoShell, execute: ./evoshell"
