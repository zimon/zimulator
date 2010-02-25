#set key top left
unset key

set xrange [2:15]
set yrange [0:35]

set xlabel "Number of Vertices"
set ylabel "Convergence Time in Seconds"

set title "Complete Topologies (Vertices - Time)"

set output "vertices_mesh_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/mesh_average.txt" using 2:9 title "average" lw 5 lc 4 with lines
