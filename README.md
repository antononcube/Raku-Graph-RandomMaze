# Raku Graph::RandomMaze

Raku package for random maze making using graphs.

The package provides the function `random-maze` the implementation of which is explained in [AA1]. 

**Remark:** Since the package "Graph", [AAp1], is used for the implementation the package name is
"Graph::RandomMaze".

## Usage

### Rectangular maze

```raku
use Graph::RandomMaze;

my %rect = random-maze(rows => 8, columns => 16, type => 'rectangular', properties => Whatever);
```
```
# {dimensions => [8 16], end => 6_14, paths => Graph(vertexes => 105, edges => 104, directed => False), solution => [0_0 1_0 1_1 1_2 0_2 0_3 0_4 1_4 2_4 2_5 3_5 3_4 3_3 4_3 5_3 5_4 5_5 6_5 6_6 6_7 6_8 5_8 5_9 5_10 5_11 6_11 6_12 5_12 5_13 6_13 6_14], start => 0_0, type => rectangular, walls => Graph(vertexes => 126, edges => 124, directed => False)}
```

```raku, eval=FALSE
my %opts = engine => 'neato', :8size, vertex-shape => 'point', edge-thickness => 12;
%rect<walls>.dot(|%opts):svg;
```

![](./docs/rectangular-maze.svg)

### Hexagonal maze

```raku
my %hex = random-maze(rows => 8, columns => 16, type => 'hexagonal', properties => Whatever);
```
```
# {dimensions => [8 16], end => 127, paths => Graph(vertexes => 128, edges => 127, directed => False), solution => [0 2 4 3 5 10 14 22 25 21 24 32 40 48 45 53 56 61 65 73 77 69 72 80 85 93 89 86 90 95 99 103 111 107 115 118 123 126 127], start => 0, type => hexagonal, walls => Graph(vertexes => 302, edges => 300, directed => False)}
```

```raku, eval=FALSE
%opts<edge-thickness> = 32;
%hex<walls>.dot(|%opts):svg;
```

![](./docs/hexagonal-maze.svg)

The returned hash contains:
- Carved wall graph (`walls`), 
- Spanning tree used for carving (`paths`), 
- Shortest-path solution (`solution`), 
- Bookkeeping keys (`shape`, `dimensions`, `start`, `end`)

----

## CLI

The package provides the Command Line Interface (CLI) script `random-maze` for making random mazes 
and exporting them in different formats. Here is the usage message:

```shell
random-maze --help
```
```
# Usage:
#   random-maze <rows> <columns> [--type=<Str>] [-t|--format|--to=<Str>] [--props|--properties=<Str>] [-o|--output=<Str>] [--engine=<Str>] -- Generates random mazes and exports to JSON, Raku, SVG, or Wolfram Language (WL) code or code files.
#   
#     <rows>                        Walls grid graph rows.
#     <columns>                     Walls grid graph columns.
#     --type=<Str>                  Type of graph grid to use. (One of 'rectangular' or 'hexagonal'.) [default: 'rectangular']
#     -t|--format|--to=<Str>        Format to convert to. (One of 'json', 'raku', 'svg', 'wl', 'Whatever'.) [default: 'Whatever']
#     --props|--properties=<Str>    Properties separated by comma. [default: 'walls']
#     -o|--output=<Str>             Output file; if an empty string then the result is printed to stdout. [default: '']
#     --engine=<Str>                Graphviz graph layout engine. [default: 'neato']
```

----


## References

[AA1] Anton Antonov,
["Day 24 – Maze Making Using Graphs"](https://raku-advent.blog/2025/12/24/day-24-maze-making-using-graphs/),
(2025),
[Raku Advent Calendar at WordPress](https://raku-advent.blog/).

[AAp1] Anton Antonov,
[Graph, Raku package](https://github.com/antononcube/Raku-Graph),
(2024-2025),
[GitHub/antononcube](https://github.com/antononcube).