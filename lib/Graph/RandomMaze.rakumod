use v6.d;

unit module Graph::RandomMaze;

use Graph;
use Graph::Classes;
use Math::Nearest;
use Data::Generators;

#==========================================================
# Random maze
#==========================================================

#| Create random mazes using rectangular or hexagonal grid graphs.
proto sub random-maze(|) is export {*}

my @expectedProperties = <type dimensions walls paths solution start end>;
multi sub random-maze(Str:D $p where $p.lc ∈ <props properties>) {
    return @expectedProperties;
}

multi sub random-maze(Int:D $rows, *%args) {
    return random-maze(:$rows, columns => $rows, |%args)
}

multi sub random-maze((Int:D $rows, Int:D $columns), *%args) {
    return random-maze(:$rows, :$columns, |%args)
}

multi sub random-maze(
    Int :n(:$rows) = 5,
    :m(:$columns) is copy = Whatever,
    Str :shape(:type(:$grid-layout)) = 'rectangular',
    :$weight-range = 1000,
    Bool :$include-solution = True,
    :props(:$properties) = 'walls') {

    if $columns.isa(Whatever) { $columns = $rows }
    die "The argument \$columns is expected to be a positive integer or Whatever." unless $columns ~~ Int:D;
    die "Rows and columns must be greater than 1." unless $rows > 1 && $columns > 1;

    my %res = do given $grid-layout.lc {
        when any(<rectangular rectangle rect grid>) {
            rectangular-maze($rows, $columns);
        }
        when any(<hexagonal hex>) {
            hexagonal-maze($rows, $columns);
        }
        default {
            die "Unknown maze grid layout '$grid-layout'. Use 'rectangular' or 'hexagonal'.";
        }
    }

    return do given $properties {
        when $_.isa(Whatever) { %res }

        when $_ ~~ Str:D && $_ ∈ @expectedProperties { %res{$_} }

        when $_ ~~ Str:D {
            die "When the properties spec is a string then it is expected to be one of \"{@expectedProperties.join('", "')}\"."
        }

        when $_ ~~ (Array:D | List:D | Seq:D) && $_.all ~~ Str:D {
            my @props = ($_ (&) @expectedProperties).keys;
            die 'No known properties are specified.' unless @props.elems > 0;
            %res.grep(*.key ∈ @props).Hash
        }

        default {
            die 'The properties argument is expected to be a string, a list of strings, or Whatever.'
        }
    }
}

our $random-labyrinth is export = &random-maze;

#==========================================================
# Rectangular maze
#==========================================================

sub rectangular-maze(Int:D $rows, Int:D $cols) {
    my $walls-grid = Graph::Grid.new($rows, $cols, prefix => 'w', :!directed);

    my $paths-grid = Graph::Grid.new($rows - 1, $cols - 1, :!directed);
    $paths-grid.vertex-coordinates = $paths-grid.vertex-coordinates.map({ $_.key => $_.value >>+>> 0.5 }).Hash;

    my $paths = Graph.new(
        $paths-grid.edges(:dataset).map({
            $_<weight> = random-real([10, 10_000]);
            $_
        })
    );

    $paths = $paths.find-spanning-tree;
    $paths.vertex-coordinates = $paths-grid.vertex-coordinates;

    my $walls = $walls-grid.clone;
    for $paths.edges -> $edge {
        my ($r1, $c1) = |$edge.key.split('_')».Int;
        my ($r2, $c2) = |$edge.value.split('_')».Int;

        if $r2 < $r1 || $c2 < $c1 {
            ($r1, $c1, $r2, $c2) = ($r2, $c2, $r1, $c1);
        }

        if $r1 == $r2 && $c1 < $c2 {
            $walls = $walls.edge-delete("w{$r2}_{$c2}" => "w{$r2+1}_{$c2}");
        }
        elsif $c1 == $c2 && $r1 < $r2 {
            $walls = $walls.edge-delete("w{$r2}_{$c2}" => "w{$r2}_{$c2+1}");
        }
    }

    my @solution = |$paths.find-shortest-path('0_0', "{$rows-2}_{$cols-2}");

    # "Open" start and end rectangular cells
    my @wall-vertexes = $walls.vertex-list.sort({ $_.substr(1).Int });
    my $start = @wall-vertexes.head;
    my $end = @wall-vertexes.tail;
    $walls.vertex-delete([$start, $end]);

    return %(
        :grid-layout('rectangular'),
        :dimensions([$rows, $cols]),
        :$walls,
        :$paths,
        :start(@solution.head),
        :end(@solution.tail),
        :@solution
    );
}

#==========================================================
# Hexagonal maze
#==========================================================

sub hexagonal-maze(Int:D $rows, Int:D $cols) {
    my $walls-grid = Graph::HexagonalGrid.new($rows, $cols, prefix => 'w', :!directed);

    my $paths-grid = Graph::TriangularGrid.new($rows - 1, $cols - 1, :!directed);
    $paths-grid.vertex-coordinates = $paths-grid.vertex-coordinates.map({
        $_.key => $_.value >>+<< [sqrt(3), 1]
    }).Hash;

    my $paths = Graph.new(
        $paths-grid.edges(:dataset).map({
            $_<weight> = random-real([10, 10_000]);
            $_
        })
    );

    $paths = Graph.new($paths.find-spanning-tree.edges);
    $paths.vertex-coordinates = $paths-grid.vertex-coordinates;

    my &finder = nearest($walls-grid.vertex-coordinates.Array, method => 'KDTree');

    my $walls = $walls-grid.clone;
    for $paths.edges -> $edge {
        my @points = $paths-grid.vertex-coordinates{($edge.kv)};
        my @midpoint = |((@points[0] <<+>> @points[1]) >>/>> 2);
        my @closest = |&finder.nearest(@midpoint, 2, prop => <label>).flat;
        $walls = $walls.edge-delete(@closest[0] => @closest[1]);
    }

    my @ordered = $paths.vertex-list.sort(*.Int);
    my @solution = $paths.find-shortest-path(|@ordered[0, *-1]);

    # "Open" start and end hexagonal cells
    my @wall-vertexes = $walls.vertex-list.sort({ $_.substr(1).Int });
    my $start = @wall-vertexes.head;
    my $end = @wall-vertexes.tail;
    $walls.vertex-delete([$start, $end]);

    return %(
        :grid-layout('hexagonal'),
        :dimensions([$rows, $cols]),
        :$walls,
        :$paths,
        :start(@solution.head),
        :end(@solution.tail),
        :@solution,
    );
}

#==========================================================
# Display maze
#==========================================================

#| Displays graphs and output hashmaps of &random-maze.
proto sub display-maze($maze, *%opts) is export {*}

multi sub display-maze(Graph:D $maze, *%opts) {
    $maze.dot(|%opts):svg
}

multi sub display-maze(%maze, *%opts) {
    if (%maze<walls>:exists) && (%maze<paths>:exists) && (%maze<solution>:exists) {

        my $gSolution = %maze<paths>.subgraph(%maze<solution>);
        my $g = %maze<walls>.union($gSolution);
        my $highlight = $gSolution;
        $g.dot(:$highlight, |%opts):svg

    } elsif (%maze<paths>:exists) && (%maze<solution>:exists) {

        my $gSolution = %maze<paths>.subgraph(%maze<solution>);
        my $highlight = $gSolution;
        %maze<paths>.dot(:$highlight, |%opts):svg

    } elsif %maze<walls>:exists {

        display-maze(%maze<walls>, |%opts)

    } elsif %maze<paths>:exists {

        display-maze(%maze<paths>, |%opts)

    } else {
        die 'Do not know how to process the first argument. ' ~
            'If the first argument is a hashmap then at least one of the keys "walls" or "path" must be present.'
    }
}