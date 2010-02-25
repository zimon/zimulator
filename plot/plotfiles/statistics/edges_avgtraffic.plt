set key top left

set xrange [1:101]
set yrange [0:10]

set xlabel "Number of Edges"
set ylabel "Average Traffic per Net in KiB"

f(x)=a*x+b
fit f(x) '../../data/all_average.txt' using 5:19 via a,b

set title "Edges - Average Traffic per Net"

set output "stat_edges_avgtraffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using 5:19 title "All" lw 10 lc 1 with points, f(x) title "Approximated Function" lw 5 lc 3 with lines, "../../data/internet2_average.txt" using 5:19 title "Internet2" lw 25 lc 7 with points, "../../data/arpa_average.txt" using 5:19 title "Arpa72" lw 25 lc 3 with points
