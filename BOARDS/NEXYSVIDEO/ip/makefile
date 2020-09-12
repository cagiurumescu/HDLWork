
TARGET_IP=

clean:
ifeq ($(TARGET_IP),)
	# nothing to do
else
	cd $(TARGET_IP); find . ! -name *.xci -and ! -name *.prj -and ! -name *.xpr -type f | xargs rm -f
	cd $(TARGET_IP); find . ! -name . -type d | xargs rm -rf
endif
