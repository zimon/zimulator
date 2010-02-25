#set key top left
unset key

set xrange [3:51]
set yrange [0:35]

set xlabel "Number of Vertices"
set ylabel "Convergence Time in Seconds"

#f(x)=a*x+b
#fit f(x) '../data/star2_average.txt' using 2:9 via a,b

set title "Star2 Topologies (Vertices - Time)"

set output "vertices_star2_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/star2_average.txt" using 2:9 title "average" lw 5 lc 2 with lines
