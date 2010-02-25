set key top left

set xrange [1:900]
set yrange [0:1000]

set xlabel "0.09 * E^2 - 1.6 * E - 0.025 * V^2 + 2.6 * V"
set ylabel "Traffic in KiB"

set title "Edges, Vertices - Traffic"

f(x)=a*x+b
fit f(x) '../../data/all_average.txt' using (0.089883648*$5**2-1.5855689*$5-0.024827229*$2**2+2.6173149*$2):18 via a,b

set output "stat_edges_vertices_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40


plot "../../data/all_average.txt" using (0.089883648*$5**2-1.5855689*$5-0.024827229*$2**2+2.6173149*$2):18 title "All" lw 10 lc 1 with points, f(x) title "Approximated Function" lw 5 lc 3 with lines
