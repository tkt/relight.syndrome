#!/usr/bin/env python

import sys, os

vil = sys.argv[1]
os.system("ruby bin/createvil.rb")
os.system("ruby bin/addpl.rb %s" % vil)
os.system("ruby bin/update.rb %s" % vil)
