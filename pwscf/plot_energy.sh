#!/bin/sh

/bin/grep  -a '!    total energy' *out | /usr/bin/awk '{print $5}' > /tmp/e_out
echo 'plot "/tmp/e_out"' > /tmp/gnuplot_command
echo 'pause -1 "\n\t push' \''q'\'' and '\'return\'' to exit...\n"' >> /tmp/gnuplot_command
/usr/bin/gnuplot /tmp/gnuplot_command

/bin/rm /tmp/e_out
/bin/rm /tmp/gnuplot_command
