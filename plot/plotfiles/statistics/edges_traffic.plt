set key top left

set xrange [0:101]
set yrange [0:1000]

set xlabel "Number of Edges"
set ylabel "Traffic in KiB"

f(x)=a*x**2+b*x+c
fit f(x) '../../data/all_average.txt' using 5:18 via a,b,c

set title "Edges - Traffic"

set output "stat_edges_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using 5:18 title "All" lw 10 lc 1 with points, f(x) title "Approximated Function" lw 5 lc 3 with lines,"../../data/internet2_average.txt" using 5:18 title "Internet2" lw 25 lc 7 with points, "../../data/arpa_average.txt" using 5:18 title "Arpa72" lw 25 lc 3 with points
#, "../../data/star2_average.txt" using 5:18 title "star2" with lines 3
