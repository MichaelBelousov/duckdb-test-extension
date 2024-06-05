// cc -std=c++11 -o test.a -I stepcode/build/include -I stepcode/build/schemas/sdai_IFC4 \
//   -L stepcode/build/lib -lsdai_IFC4 -l stepeditor -l stepcore -l stepdai \
//   -Istepcode/build/include -Istepcode/include \
//   test.cpp

#include "cleditor/STEPfile.h"
#include <clstepcore/STEPattribute.h>
#include <clstepcore/sdai.h>

// FIXME: why is this necessary?
#include <cldai/sdaiEnum.h>

#include <SdaiIFC4.h>

int main() {
	auto cal = create_SdaiIfcworkcalendar();
	return (int) cal->predefinedtype_();
}
