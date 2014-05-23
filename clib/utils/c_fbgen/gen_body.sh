#!/bin/sh

for f in `seq 4 39`
do
  count=`grep -v value $f.txt | wc -l | tr -d ' '`
  echo "      else if(width == $f)"
  echo "         begin"
  i=0
  else=""
  for g in `cat $f.txt | grep -v value | sed "s/\([0-9A-F]*\)/$f'h\1/"`
  do
    echo "            ${else}if((index % ${count}) == $i) assign feedback = $g" | sed 's/\(.$\)/;/'
    else="else "
    i=$[$i+1]
  done
  echo "         end"
done
echo "      // synopsys translate_off"
echo "      else"
echo "        begin"
echo "          initial"
echo "            begin"
echo "              \$display(\"ERROR: LFSR feedback generator module %m does not support width %d.\", width);"
echo "              \$stop;"
echo "            end"
echo "        end"
echo "      // synopsys translate_on"
