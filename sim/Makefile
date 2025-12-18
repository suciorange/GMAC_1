VCS_BIN=sim/simv
OUT_DIR=sim/out

.PHONY: vcs run clean

vcs:
	@mkdir -p $(OUT_DIR)
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -lca \
		-f sim/flist.f -top tb_mac_top -o $(VCS_BIN) \
		-l $(OUT_DIR)/vcs.log

run: vcs
	@./$(VCS_BIN) +DUMP=1 +SPEED=1G -l $(OUT_DIR)/run.log

clean:
	rm -rf sim/simv sim/simv.daidir sim/csrc sim/ucli.key sim/urgReport $(OUT_DIR)
