# Required packages (tested on Ubuntu 12.04):
# inkscape texlive-latex-base texlive-font-utils dia python-pygments

# Needed tools
INKSCAPE = inkscape
CTX      = context
DIA      = dia
EPSTOPDF = epstopdf

# Needed macros
UPPERCASE = $(shell echo $1 | tr "[:lower:]" "[:upper:]")

# List of slides for the different courses

SLIDES = \
	licensing	\
        about-us 	\
	sysdev-intro	\
	sysdev-dev-environment		\
	sysdev-toolchains-title		\
	sysdev-toolchains-definition	\
	sysdev-toolchains-c-libraries	\
	sysdev-toolchains-options	\
	sysdev-toolchains-obtaining	\
	sysdev-bootloaders-title	\
	sysdev-bootloaders-sequence	\
	sysdev-bootloaders-u-boot	\
	sysdev-linux-intro-title	\
	sysdev-linux-intro-features	\
	sysdev-linux-intro-versioning	\
	sysdev-linux-intro-sources	\
	sysdev-linux-intro-configuration\
	sysdev-linux-intro-compilation	\
	sysdev-linux-intro-cross-compilation	\
	sysdev-linux-intro-modules		\
	sysdev-root-filesystem-title		\
	sysdev-root-filesystem-principles	\
	sysdev-root-filesystem-contents 	\
	sysdev-root-filesystem-device-files	\
	sysdev-root-filesystem-virtual-fs	\
	sysdev-root-filesystem-minimal		\
	sysdev-busybox 			\
	sysdev-udev 			\
	sysdev-block-filesystems 	\
	sysdev-flash-filesystems 	\
	sysdev-embedded-linux 		\
	sysdev-application-development 	\
	sysdev-references 		\
	last-slides

# Output directory
OUTDIR   = $(PWD)/out

#
# === Picture lookup ===
#

# Function that computes the list of pictures of the extension given
# in $(2) from the directories in $(1), and transforms the filenames
# in .pdf in the output directory. This is used to compute the list of
# .pdf files that need to be generated from .dia or .svg files.
PICTURES_WITH_TRANSFORMATION = \
	$(patsubst %.$(2),$(OUTDIR)/%.pdf,$(foreach s,$(1),$(wildcard $(s)/*.$(2))))

# Function that computes the list of pictures of the extension given
# in $(2) from the directories in $(1). This is used for pictures that
# to not need any transformation, such as bitmap files in the .png or
# .jpg formats.
PICTURES_NO_TRANSFORMATION = \
	$(patsubst %,$(OUTDIR)/%,$(foreach s,$(1),$(wildcard $(s)/*.$(2))))

# Function that computes the list of pictures from the directories in
# $(1) and returns output filenames in the output directory.
PICTURES = \
	$(call PICTURES_WITH_TRANSFORMATION,$(1),svg) \
	$(call PICTURES_WITH_TRANSFORMATION,$(1),dia) \
	$(call PICTURES_NO_TRANSFORMATION,$(1),png)   \
	$(call PICTURES_NO_TRANSFORMATION,$(1),pdf)   \
	$(call PICTURES_NO_TRANSFORMATION,$(1),jpg)

# List of common pictures
COMMON_PICTURES   = $(call PICTURES,common)

default: slides.pdf

#
# === Compilation of slides ===
#

# This rule allows to build slides of the training. It is done in two
# parts with make calling itself because it is not possible to compute
# a list of prerequisites depending on the target name. See
# http://stackoverflow.com/questions/3381497/dynamic-targets-in-makefiles
# for details.
#
# The value of slide can be "full-kernel", "full-sysdev" (for the
# complete trainings) or the name of an individual chapter.
SLIDES_COMMON_BEFORE = common/slide-header.tex \
		       common/slide-title.tex
SLIDES_COMMON_AFTER  = common/slide-footer.tex

$(warning "SLIDES=$(SLIDES)")
# Compute the set of corresponding .tex files and pictures
SLIDES_TEX      = \
	$(SLIDES_COMMON_BEFORE) \
	$(foreach s,$(SLIDES),$(wildcard slides/$(s)/$(s).tex)) \
	$(SLIDES_COMMON_AFTER)
SLIDES_PICTURES = $(call PICTURES,$(foreach s,$(SLIDES),slides/$(s))) $(COMMON_PICTURES)

$(warning "SLIDES_TEX=$(SLIDES_TEX)")
slides.pdf: $(SLIDES_TEX) $(SLIDES_PICTURES)
	@mkdir -p $(OUTDIR)
# We generate a .tex file with \input{} directives (instead of just
# concatenating all files) so that when there is an error, we are
# pointed at the right original file and the right line in that file.
	rm -f $(OUTDIR)/$(basename $@).tex
	for f in $(filter %.tex,$^) ; do \
		echo -n "\input{../"          >> $(OUTDIR)/$(basename $@).tex ; \
		echo -n $$f | sed 's%\.tex%%' >> $(OUTDIR)/$(basename $@).tex ; \
		echo "}"                      >> $(OUTDIR)/$(basename $@).tex ; \
	done
	(cd $(OUTDIR); $(CTX) $(basename $@).tex)
	cat out/$@ > $@
#
# === Picture generation ===
#

.PRECIOUS: $(OUTDIR)/%.pdf

$(OUTDIR)/%.pdf: %.svg
	@printf "%-15s%-20s->%20s\n" INKSCAPE $(notdir $^) $(notdir $@)
	@mkdir -p $(dir $@)
ifeq ($(V),)
	$(INKSCAPE) -D -A $@ $< > /dev/null 2>&1
else
	$(INKSCAPE) -D -A $@ $<
endif

$(OUTDIR)/%.pdf: $(OUTDIR)/%.eps
	@printf "%-15s%-20s->%20s\n" EPSTOPDF $(notdir $^) $(notdir $@)
	@mkdir -p $(dir $@)
	$(EPSTOPDF) --outfile=$@ $^

.PRECIOUS: $(OUTDIR)/%.eps

$(OUTDIR)/%.eps: %.dia
	@printf "%-15s%-20s->%20s\n" DIA $(notdir $^) $(notdir $@)
	@mkdir -p $(dir $@)
	$(DIA) -e $@ -t eps $^

.PRECIOUS: $(OUTDIR)/%.pdf

$(OUTDIR)/%.pdf: %.pdf
	mkdir -p $(dir $@)
	@cp $^ $@

.PRECIOUS: $(OUTDIR)/%.png

$(OUTDIR)/%.png: %.png
	@mkdir -p $(dir $@)
	@cp $^ $@

.PRECIOUS: $(OUTDIR)/%.jpg

$(OUTDIR)/%.jpg: %.jpg
	mkdir -p $(dir $@)
	@cp $^ $@

#
# === Misc targets ===
#

clean:
	$(RM) -rf $(OUTDIR) *.pdf
