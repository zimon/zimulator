set key top left

#set xrange [1:16]
#set yrange [0:35]

set xlabel "Number of Vertices"
set ylabel "Traffic in KiB"

set title "Mesh and Star2 Topologies (Vertices - Traffic)"

set output "vertices_star2_mesh-1_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/mesh-1_average.txt" using 2:18 title "Complete-1" lw 5 lc 18 with lines, "../data/star2_average.txt" using 2:18 title "Star2" lw 5 lc 2 with lines
