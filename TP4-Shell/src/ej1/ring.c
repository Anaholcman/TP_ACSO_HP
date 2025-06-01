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
	int start, n;
	int buffer[1];

	if (argc != 4){ printf("Uso: anillo <n> <c> <s> \n"); exit(0);}
    
    n = atoi(argv[1]);         
	buffer[0] = atoi(argv[2]);
	start = atoi(argv[3]);

    printf("Se crearán %i procesos, se enviará el caracter %i desde proceso %i \n", n, buffer[0], start);
    int pipes[n][2];
	// crea los pipes
	for (int i = 0; i< n; i++){
		if (pipe(pipes[i]) == -1) {
			perror("pipe");
			exit(1);
		}
	}
	// crea procesos hijos
	for (int i = 0; i< n; i++){
		pid_t pid = fork();
		printf("Proceso padre: fork devuelve pid=%d en iteración %d\n", pid, i);

		if (pid < 0) {
			perror("fork");
			exit(1);
		} else if (pid == 0){
			fflush(stdout);
			dup2(pipes[i][0], STDIN_FILENO);        
			dup2(pipes[(i+1)%n][1], STDOUT_FILENO);  

			closing(pipes, n);
			
			int num;
			
			while (read(STDIN_FILENO, &num, sizeof(int)) > 0) {
				printf("Hijo %d leyó: %d\n", i, num);
				num++;
				printf("Hijo %d manda: %d\n", i, num);
				write(STDOUT_FILENO, &num, sizeof(int));
				
			}
			close(STDOUT_FILENO);
			exit(0);
		} 
	}
	sleep(1);

	write(pipes[start][1], buffer, sizeof(int));
	close(pipes[start][1]);
	

	read(pipes[(start+n-1)%n][0], buffer, sizeof(int));
	printf("Resultado final: %d\n", buffer[0]);

	closing(pipes, n);
	for (int i = 0; i < n; i++) {wait(NULL); }
	return 0;
	
}

void closing(int pipes[][2], int n){
	for (int j = 0; j < n; j++) {
		if (pipes[j][0] != STDIN_FILENO) close(pipes[j][0]);
    if (pipes[j][1] != STDOUT_FILENO) close(pipes[j][1]);
	}
}
