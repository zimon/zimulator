set key top left

set xrange [1:16]
set yrange [0:35]

set xlabel "1.036 * d + 0.186 * V"
set ylabel "Convergence Time in Seconds"

f(x)=a*x+b
fit f(x) '../../data/all_average.txt' using ($1*1.0365+0.186*$2):9 via a,b

set title "Diameter, Vertices - Time"

set output "stat_diameter_vertices_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using ($1*1.0365+0.186*$2):9 title "All" lw 10 lc 1 with points, f(x) title "Approximated Function" lw 5 lc 3 with lines
