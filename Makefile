.DEFAULT_GOAL := all

# global named targets
all: clear cyr lat test
cyr: cyr.num.generator.hfst cyr.num.analyzer.hfst
lat: lat.num.generator.hfst lat.num.analyzer.hfst
clear:
	rm -f *.hfst
	rm -f translit/*.hfst
	rm -f test.*

# transliterators
translit/cyr2lat.hfst: translit/lat2cyr.hfst
	hfst-invert $< -o $@
translit/lat2cyr.hfst: translit/translit.hfst
	hfst-repeat -f 1 $< -o $@
translit/translit.hfst: translit/fixes.hfst translit/correspondence.hfst
	hfst-compose $^ -o $@
translit/correspondence.hfst: translit/lat2cyr_correspondence
	hfst-strings2fst -j $< -o $@
translit/fixes.hfst: translit/lat2cyr_fixes
	hfst-strings2fst -j $< -o $@

# anylizer and generator
## cyr
cyr.num.generator.hfst: num.lexd
	lexd $< | hfst-txt2fst -o $@
cyr.num.analyzer.hfst: cyr.num.generator.hfst
	hfst-invert $< -o $@
## lat
lat.num.generator.hfst: cyr.num.generator.hfst translit/cyr2lat.hfst
	hfst-compose $^ -o $@
lat.num.analyzer.hfst: lat.num.generator.hfst
	hfst-invert $< -o $@

# create and run tests
test: check.cyr check.lat
check.cyr: cyr.num.generator.hfst test.cyr.txt
	bash compare.sh $^
check.lat: lat.num.generator.hfst test.lat.txt
	bash compare.sh $^
test.cyr.txt: tests/cyr.csv
	awk -F, '$$3 == "pass" {print $$1 ":" $$2}' $^ | sort -u > $@
test.lat.txt: tests/lat.csv
	awk -F, '$$3 == "pass" {print $$1 ":" $$2}' $^ | sort -u > $@