set key top left

#set xrange [1:100]
set yrange [0:35]

set xlabel "Number of Inner Vertices"
set ylabel "Convergence Time in Seconds"

f(x)=a*x+b
fit f(x) '../../data/all_average.txt' using 4:9 via a,b

set title "Inner Vertices - Time"

set output "stat_ivertices_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using 4:9 title "All" lw 10 lc 1 with points, f(x) title "Approximated Function" lw 5 lc 3 with lines,"../../data/internet2_average.txt" using 4:9 title "Internet2" lw 25 lc 7 with points, "../../data/arpa_average.txt" using 4:9 title "Arpa72" lw 25 lc 3 with points
