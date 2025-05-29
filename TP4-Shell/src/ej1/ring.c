#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2


void closing(int pipes[][2], int n);

int main(int argc, char **argv)
{	
	int start, status, n;
	int buffer[1];

	if (argc != 4){ printf("Uso: anillo <n> <c> <s> \n"); exit(0);}
    
    n = atoi(argv[1]);         
	buffer[0] = atoi(argv[2]);
	start = atoi(argv[3]);

    printf("Se crearán %i procesos, se enviará el caracter %i desde proceso %i \n", n, buffer[0], start);
    int pipes[n][2];

	for (int i = 0; i< n; i++){
		if (pipe(pipes[i]) == -1) {
			perror("pipe");
			exit(1);
		}
		pid_t pid = fork();
		if (pid < 0) {
			//perror("fork");
			exit(1);
		} else if (pid == 0){
			dup2(pipes[i][0], STDIN_FILENO);        
			dup2(pipes[(i+1)%n][1], STDOUT_FILENO);  

			closing(pipes, n);
			int num;
			while (read(STDIN_FILENO, &num, sizeof(int)) > 0) {
				num++;
				write(STDOUT_FILENO, &num, sizeof(int));
			}
			exit(0);
		} 
	}
	write(pipes[start][1], buffer, sizeof(int));
	read(pipes[(start+n-1)%n][0], buffer, sizeof(int));
	closing(pipes, n);
	for (int i = 0; i < n; i++) {wait(NULL); }
	
}


void closing(int pipes[][2], int n){
	for (int i = 0; i < n; i++) {
		close(pipes[i][0]);
		close(pipes[i][1]);
	}
}
