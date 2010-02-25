set key top left

set xrange [1:16]
set yrange [0:35]

set xlabel "d + 0.21 * Vi"
set ylabel "Convergencetime in Seconds"

f(x)=a*x+b
fit f(x) '../../data/all_average.txt' using ($1+0.21*$4):9 via a,b

set title "Diameter, Inner Vertices - Time"

set output "stat_diameter_ivertices_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using ($1+0.21*$4):9 title "All" lw 10 lc 1 with points, f(x) title "Approximated Function" lw 5 lc 3 with lines
