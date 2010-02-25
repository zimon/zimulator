set key top right

set xrange [0:1]
set yrange [0:35]

set xlabel "Clustering Coefficient"
set ylabel "Convergence Time in Seconds"

f(x)=(1/x*a) + b
fit f(x) '../../data/all_average.txt' using 6:9 via a,b

set title "Clustering Coefficient - Time"

set output "stat_cc_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using 6:9 title "All" lw 10 lc 1 with points, f(x) title "Approximated Function" lw 5 lc 3 with lines, "../../data/internet2_average.txt" using 6:9 title "Internet2" lw 25 lc 7 with points, "../../data/arpa_average.txt" using 6:9 title "Arpa72" lw 25 lc 3 with points
