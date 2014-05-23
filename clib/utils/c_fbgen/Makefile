c_fbgen.v: head body tail
	cat head body tail > c_fbgen.v

body: gen_body.sh *.txt
	./gen_body.sh > body

clean:
	rm -f c_fbgen.v body *~
