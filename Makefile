include noweb.mk

%.cpp: %.hpp
$(NOWEB)/MyCpp.cpp: $(NOWEB)/MyCpp.hpp
