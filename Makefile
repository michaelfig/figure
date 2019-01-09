BOOT = Configure.bat

check: $(BOOT)
	rm -rf testout
	mkdir testout
	@echo "1. Test stdout expansion produces the same file."
	$(SHELL) $(BOOT) '$$+' $(BOOT) > testout/1-$(BOOT)
	diff $(BOOT) testout/1-$(BOOT)
	@echo "2. Test inplace expansion produces the same file."
	cp $(BOOT) testout/2-$(BOOT)
	$(SHELL) $(BOOT) testout/2-$(BOOT)
	diff $(BOOT) testout/2-$(BOOT)
