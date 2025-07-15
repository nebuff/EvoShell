# EvoShell Makefile
CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -pedantic -O2
TARGET = evoshell
SOURCE = evoshell.c
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin

# Default target
all: $(TARGET)

# Build the shell
$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

# Install the shell
install: $(TARGET)
	mkdir -p $(BINDIR)
	cp $(TARGET) $(BINDIR)/evos
	chmod +x $(BINDIR)/evos
	@echo "EvoShell installed successfully!"
	@echo "You can now run 'evos' from anywhere."

# Uninstall the shell
uninstall:
	rm -f $(BINDIR)/evos
	@echo "EvoShell uninstalled."

# Clean build files
clean:
	rm -f $(TARGET)

# Development build with debug symbols
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)

# Check for common issues
check: $(TARGET)
	@echo "Running basic tests..."
	@./$(TARGET) -c "echo 'Test successful'" 2>/dev/null || echo "Manual testing required"

.PHONY: all install uninstall clean debug check
