set key top right

set xrange [1:81]
set yrange [0:35]

set xlabel "Number of circles"
set ylabel "Convergence Time in Seconds"

f(x)= a*x+b
fit f(x) '../../data/all_average.txt' using ($5-$2+1):9 via a,b

set title "Number of Circles - Time"

set output "stat_circles_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using ($5-$2+1):9 title "All" lw 10 lc 1 with points,  "../../data/internet2_average.txt" using ($5-$2+1):9 title "Internet2" lw 25 lc 7 with points, "../../data/arpa_average.txt" using ($5-$2+1):9 title "Arpa72" lw 25 lc 3 with points
