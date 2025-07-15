#define _GNU_SOURCE  // For gethostname on Linux
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <pwd.h>
#include <errno.h>

// For gethostname
#ifdef __linux__
#include <sys/utsname.h>
#endif

#define MAX_CMD_LEN 1024
#define MAX_ARGS 64
#define EVOSHELL_VERSION "1.0.0"

// ANSI color codes
#define COLOR_RESET   "\033[0m"
#define COLOR_BLUE    "\033[34m"
#define COLOR_GREEN   "\033[32m"
#define COLOR_YELLOW  "\033[33m"
#define COLOR_RED     "\033[31m"
#define COLOR_CYAN    "\033[36m"

// Function prototypes
void print_prompt();
char *read_line();
char **parse_line(char *line);
int execute_command(char **args);
int builtin_cd(char **args);
int builtin_help(char **args);
int builtin_exit(char **args);
int builtin_version(char **args);
void welcome_message();

// Built-in commands
char *builtin_names[] = {
    "cd",
    "help",
    "exit",
    "version"
};

int (*builtin_functions[])(char **) = {
    &builtin_cd,
    &builtin_help,
    &builtin_exit,
    &builtin_version
};

int num_builtins() {
    return sizeof(builtin_names) / sizeof(char *);
}

void welcome_message() {
    printf("%s", COLOR_CYAN);
    printf("╔══════════════════════════════════════════════════════════════════╗\n");
    printf("║                          EvoShell v%s                           ║\n", EVOSHELL_VERSION);
    printf("║                   A Simple and Intuitive Shell                  ║\n");
    printf("║                                                                  ║\n");
    printf("║  Type 'help' for available commands or 'exit' to quit           ║\n");
    printf("╚══════════════════════════════════════════════════════════════════╝\n");
    printf("%s\n", COLOR_RESET);
}

void print_prompt() {
    char *username = getenv("USER");
    char hostname[256];
    char cwd[1024];
    
    if (gethostname(hostname, sizeof(hostname)) != 0) {
        strcpy(hostname, "unknown");
    }
    
    if (getcwd(cwd, sizeof(cwd)) == NULL) {
        strcpy(cwd, "unknown");
    }
    
    // Replace home directory path with ~
    char *home = getenv("HOME");
    if (home && strncmp(cwd, home, strlen(home)) == 0) {
        char temp[1024];
        snprintf(temp, sizeof(temp), "~%s", cwd + strlen(home));
        strcpy(cwd, temp);
    }
    
    printf("%s%s@%s%s:%s%s%s$ ", 
           COLOR_GREEN, username ? username : "user", hostname, COLOR_RESET,
           COLOR_BLUE, cwd, COLOR_RESET);
}

char *read_line() {
    char *line = malloc(MAX_CMD_LEN);
    if (!line) {
        fprintf(stderr, "evoshell: allocation error\n");
        exit(EXIT_FAILURE);
    }
    
    if (fgets(line, MAX_CMD_LEN, stdin) == NULL) {
        if (feof(stdin)) {
            printf("\n");
            exit(EXIT_SUCCESS);
        } else {
            perror("evoshell: getline");
            exit(EXIT_FAILURE);
        }
    }
    
    // Remove trailing newline
    line[strcspn(line, "\n")] = 0;
    
    return line;
}

char **parse_line(char *line) {
    int bufsize = MAX_ARGS;
    int position = 0;
    char **tokens = malloc(bufsize * sizeof(char*));
    char *token;
    
    if (!tokens) {
        fprintf(stderr, "evoshell: allocation error\n");
        exit(EXIT_FAILURE);
    }
    
    token = strtok(line, " \t\r\n\a");
    while (token != NULL) {
        tokens[position] = token;
        position++;
        
        if (position >= bufsize) {
            bufsize += MAX_ARGS;
            tokens = realloc(tokens, bufsize * sizeof(char*));
            if (!tokens) {
                fprintf(stderr, "evoshell: allocation error\n");
                exit(EXIT_FAILURE);
            }
        }
        
        token = strtok(NULL, " \t\r\n\a");
    }
    tokens[position] = NULL;
    return tokens;
}

int builtin_cd(char **args) {
    if (args[1] == NULL) {
        // No argument, change to home directory
        char *home = getenv("HOME");
        if (home == NULL) {
            fprintf(stderr, "evoshell: cd: HOME not set\n");
            return 1;
        }
        if (chdir(home) != 0) {
            perror("evoshell: cd");
            return 1;
        }
    } else {
        if (chdir(args[1]) != 0) {
            perror("evoshell: cd");
            return 1;
        }
    }
    return 0;
}

int builtin_help(char **args) {
    (void)args; // Suppress unused parameter warning
    printf("%sEvoShell Built-in Commands:%s\n\n", COLOR_YELLOW, COLOR_RESET);
    printf("  %scd [directory]%s   - Change the current directory\n", COLOR_GREEN, COLOR_RESET);
    printf("  %shelp%s             - Display this help message\n", COLOR_GREEN, COLOR_RESET);
    printf("  %sversion%s          - Display version information\n", COLOR_GREEN, COLOR_RESET);
    printf("  %sexit%s             - Exit the shell\n", COLOR_GREEN, COLOR_RESET);
    printf("\n%sAll other commands are passed to the system.%s\n", COLOR_CYAN, COLOR_RESET);
    return 0;
}

int builtin_exit(char **args) {
    (void)args; // Suppress unused parameter warning
    printf("%sGoodbye! Thanks for using EvoShell.%s\n", COLOR_CYAN, COLOR_RESET);
    exit(EXIT_SUCCESS);
}

int builtin_version(char **args) {
    (void)args; // Suppress unused parameter warning
    printf("%sEvoShell v%s%s\n", COLOR_CYAN, EVOSHELL_VERSION, COLOR_RESET);
    printf("A simple and intuitive shell written in C\n");
    printf("Built on %s %s\n", __DATE__, __TIME__);
    return 0;
}

int execute_command(char **args) {
    if (args[0] == NULL) {
        // Empty command
        return 1;
    }
    
    // Check for built-in commands
    for (int i = 0; i < num_builtins(); i++) {
        if (strcmp(args[0], builtin_names[i]) == 0) {
            return (*builtin_functions[i])(args);
        }
    }
    
    // Execute external command
    pid_t pid = fork();
    if (pid == 0) {
        // Child process
        if (execvp(args[0], args) == -1) {
            fprintf(stderr, "%sevoshell: %s: command not found%s\n", 
                    COLOR_RED, args[0], COLOR_RESET);
        }
        exit(EXIT_FAILURE);
    } else if (pid < 0) {
        // Fork failed
        perror("evoshell: fork");
    } else {
        // Parent process
        int status;
        do {
            waitpid(pid, &status, WUNTRACED);
        } while (!WIFEXITED(status) && !WIFSIGNALED(status));
    }
    
    return 1;
}

int main(int argc, char **argv) {
    (void)argc; // Suppress unused parameter warning
    (void)argv; // Suppress unused parameter warning
    
    char *line;
    char **args;
    int status;
    
    welcome_message();
    
    // Main shell loop
    do {
        print_prompt();
        line = read_line();
        args = parse_line(line);
        status = execute_command(args);
        
        free(line);
        free(args);
    } while (status);
    
    return EXIT_SUCCESS;
}
