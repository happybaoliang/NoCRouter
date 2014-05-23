MIN_SIZE=1
MAX_SIZE=64

c_select_1ofn.v: head body tail
	cat head body tail > c_select_1ofn.v

body: gen_body
	./gen_body $(MIN_SIZE) $(MAX_SIZE) > body

gen_body: gen_body.cpp
	g++ -o gen_body gen_body.cpp

clean:
	rm -f c_select_1ofn.v body gen_body *~
