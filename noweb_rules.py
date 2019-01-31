#! /usr/bin/env python

from glob import iglob
from itertools import chain
import re

default_match = "%s: $(BUILD)/%%: %s\n\t$(NOTANGLE_RULE)"

def main():
  pattern = re.compile(r'\\noweboutput\{(.*?)\}')
  file_deps = {}
  for noweb_file in iglob("*.nw"):
    codefiles = list(chain(*map(lambda line: re.findall(pattern, line), open(noweb_file, 'r'))))
    codebuilds = ["$(BUILD)/" + f for f in codefiles]
    codeoutputs = [f + ".output" for f in codebuilds]
    noweb_pdf = "$(BUILD)/" + noweb_file.rsplit(".nw",1)[0] + ".pdf"
    if codefiles:
      print(default_match % (" ".join(codebuilds), noweb_file))
      print("%s: %s" % (noweb_pdf, " ".join(codeoutputs)))

if __name__ == "__main__":
  main()
