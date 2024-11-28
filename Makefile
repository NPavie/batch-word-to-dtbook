include engine/make/enable-java-shell.mk

.PHONY : default
default : daisy-pipeline


ENGINE_VERSION := $(shell println(xpath(new File("engine/pom.xml"), "/*/*[local-name()='version']/text()"));)

ifeq ($(OS), WINDOWS)
zip_classifier := win
else ifeq ($(OS), MACOSX)
zip_classifier := mac
else
zip_classifier := linux
endif

daisy-pipeline : engine/target/assembly-$(ENGINE_VERSION)-$(zip_classifier).zip
	rm("$@");
	unzip(new File("$<"), new File("$(dir $@)"));
ifeq ($(OS), MACOSX)
	// FIXME: unzip() currently does not preserve file permissions \
	exec("chmod", "+x", "$@/jre/bin/java");
	exec("chmod", "+x", "$@/jre/lib/jspawnhelper");
endif

engine/target/assembly-$(ENGINE_VERSION)-$(zip_classifier).zip : \
		engine/pom.xml \
		$(shell Files.walk(Paths.get("engine/src")).filter(Files::isRegularFile).forEach(System.out::println);)
	exec("$(MAKE)", "-C", "engine", "zip-$(zip_classifier)",         \
	                                "--", "--without-osgi",          \
			                        "--without-updater",             \
			                        "--without-persistence");

clean :
	rm("daisy-pipeline");
	exec("$(MAKE)", "-C", "engine", "clean");


