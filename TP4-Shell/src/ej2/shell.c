#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>

#define MAX_COMMANDS 200

void crear_pipes(int pipes[][2], int cantidad);
void cerrar_pipes(int pipes[][2], int cantidad);
void ejecutar_comando(char *comando);


int main() {

    char command[256];
    char *commands[MAX_COMMANDS];
    
    while (1) 
    {
        printf("Shell> ");
        fflush(stdout);
        fgets(command, sizeof(command), stdin);
        command[strcspn(command, "\n")] = '\0';
        int command_count = 0;

        char *token = strtok(command, "|");
        while (token != NULL) {
            commands[command_count++] = token;
            token = strtok(NULL, "|");
        }

        int pipes[MAX_COMMANDS - 1][2];
        crear_pipes(pipes, command_count -1);
        
        for (int i = 0; i < command_count; i++) {
            pid_t pid = fork();
            if (pid == -1){
                perror("fork");
                exit(1);
            }
            else if (pid == 0){
                if (i != 0){
                    dup2(pipes[i - 1][0], STDIN_FILENO);
                }
                if (i != command_count - 1){
                    dup2(pipes[i][1], STDOUT_FILENO);
                }
                cerrar_pipes(pipes, command_count);
                ejecutar_comando(commands[i]); 
            }
        }
        cerrar_pipes(pipes, command_count-1);
        for (int i = 0; i < command_count; i++) {
            wait(NULL);
        }  
    }
    return 0;
}

void crear_pipes(int pipes[][2], int cantidad){
    for (int i = 0; i < cantidad; i++) {
        if (pipe(pipes[i]) == -1) {
            perror("pipe");
            exit(1);
        }
    }
}

void cerrar_pipes(int pipes[][2], int cantidad){
    for (int i = 0; i < cantidad; i++) {
        close(pipes[i][0]);
        close(pipes[i][1]);
    }
}

void ejecutar_comando(char *comando) {
    char *args[20];
    int arg_count = 0;

    char *arg = strtok(comando, " ");
    while (arg != NULL && arg_count < 19) {
        args[arg_count++] = arg;
        arg = strtok(NULL, " ");
    }
    args[arg_count] = NULL;

    execvp(args[0], args);
    perror("execvp");
    exit(1);
}