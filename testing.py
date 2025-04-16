array = [7, 4, 6, 8, 13, 10, 15, 9, 0, 12, 3, 5, 2, 11, 1, 14]

for start in range(16):
    path = []
    visited = set()
    current = start
    for _ in range(14):
        path.append(current)
        current = array[current]
        if current in visited:
            break
        visited.add(current)
    if len(path) == 14 and current == 15:
        suma = sum(array[i] for i in path)
        print(f"Inicio: {start}, Suma: {suma}, Camino: {path}")
