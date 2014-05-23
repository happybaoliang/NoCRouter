MAX_SIZE=64

c_decode.v: head body tail
	cat head body tail > c_decode.v

body: gen_body
	./gen_body 2 $(MAX_SIZE) > body

gen_body: gen_body.cpp
	g++ -o gen_body gen_body.cpp

clean:
	rm -f c_decode.v body gen_body *~
