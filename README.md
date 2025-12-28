# Raku-Graph-RandomMaze
Raku package for random maze making using graphs.

## Usage

```raku
use Graph::RandomMaze;

# Rectangular maze (walls graph + corridors + solution path)
my %rect = random-maze(shape => 'rectangular', rows => 8, cols => 16, seed => 42);

# Hexagonal maze
my %hex = random-maze(shape => 'hexagonal', rows => 5, cols => 7);
```

The returned hash contains the carved wall graph (`walls`), the spanning tree used
for carving (`corridors`), optional shortest-path solution (`solution`), and
bookkeeping keys (`shape`, `dimensions`, `start`, `end`).
