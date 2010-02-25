#set key top left
unset key

set xrange [9:17]
set yrange [0:35]

set xlabel "Number of Vertices"
set ylabel "Convergence Time in Seconds"

#f(x)=a*x+b
#fit f(x) '../data/const_vertices.txt' using 2:7 via a,b

set title "Selected Topologies (Vertices - Time)"

set output "vertices_selected_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/const_vertices_average.txt" using 2:9 title "average" lw 5 lc 3 with lines
