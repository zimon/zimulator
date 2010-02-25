set key top right

set xrange [0:51]
set yrange [0:1000]

set xlabel "Number of Leaves"
set ylabel "Traffic in KiB"

f(x)=a*x+b
fit f(x) '../../data/all_average.txt' using 3:18 via a,b

set title "Leaves - Traffic"

set output "stat_leaves_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using 3:18 title "All" lw 10 lc 1 with points, "../../data/internet2_average.txt" using 3:18 title "Internet2" lw 25 lc 7 with points, "../../data/arpa_average.txt" using 3:18 title "Arpa72" lw 25 lc 3 with points
#, f(x) title "approximated function" lw 5 lc 3 with lines
