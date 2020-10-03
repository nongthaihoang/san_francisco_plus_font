# Custom Font Installer 
# by nongthaihoang @ xda

[ ! $MAGISKTMP ] && MAGISKTMP=$(magisk --path)/.magisk
[ -d $MAGISKTMP ] && ORIGDIR=$MAGISKTMP/mirror
FONTDIR=$MODPATH/fonts
SYSFONT=$MODPATH/system/fonts
PRDFONT=$MODPATH/system/product/fonts
SYSETC=$MODPATH/system/etc
SYSXML=$SYSETC/fonts.xml
MODPROP=$MODPATH/module.prop
mkdir -p $SYSFONT $SYSETC $PRDFONT

patch() {
	if [ -f $ORIGDIR/system/etc/fonts.xml ]; then
		if ! grep -q 'family >' /system/etc/fonts.xml; then
			find /data/adb/modules/ -type f -name fonts*xml -exec rm {} \;
			false | cp -i /system/etc/fonts.xml $SYSXML && ver !
		else
			false | cp -i $ORIGDIR/system/etc/fonts.xml $SYSXML 
		fi
	else
		abort "! $ORIGDIR/system/etc/fonts.xml: file not found"
	fi
	DEFFONT=$(sed -n '/"sans-serif">/,/family>/p' $SYSXML | grep '\-Regular.' | sed 's/.*">//;s/-.*//' | tail -1)
	[ $DEFFONT ] || abort "! Unknown default font"
	if ! grep -q 'family >' $SYSXML; then
		sed -i '/"sans-serif">/,/family>/H;1,/family>/{/family>/G}' $SYSXML
		sed -i ':a;N;$!ba;s/name="sans-serif"//2' $SYSXML
	fi
}

headline() {
	cp $FONTDIR/hf/*ttf $SYSFONT
	sed -i "/\"sans-serif\">/,/family>/{s/$DEFFONT-M/M/;s/$DEFFONT-B/B/}" $SYSXML
}

body() {
	cp $FONTDIR/bf/*ttf $SYSFONT 
	sed -i "/\"sans-serif\">/,/family>/{s/$DEFFONT-T/T/;s/$DEFFONT-L/L/;s/$DEFFONT-R/R/;s/$DEFFONT-I/I/}" $SYSXML
}

condensed() {
	cp $FONTDIR/cf/*ttf $SYSFONT
	sed -i 's/RobotoC/C/' $SYSXML
}

mono() {
	cp $FONTDIR/mo/*ttf $SYSFONT
	sed -i 's/DroidSans//' $SYSXML
}

full() { headline; body; condensed; mono; }

rounded() {
	[ $HF -eq 2 ] && ( cp $FONTDIR/rd/hf/*ttf $SYSFONT; ver hfrnd )
	[ $BF -eq 2 ] && ( cp $FONTDIR/rd/bf/*ttf $SYSFONT; ver bfrnd )
}

text() {
	cp $FONTDIR/tx/bf/*ttf $SYSFONT
	ver bftxt
}

bold() {
	if [ $BOLD -eq 3 ]; then
		sed -i '/"sans-serif">/,/family>/{/400/d;/>Light\./{N;h;d};/MediumItalic/G;/>Black\./{N;h;d};/BoldItalic/G}' $SYSXML
		sed -i '/"sans-serif-condensed">/,/family>/{/400/d;/-Light\./{N;h;d};/MediumItalic/G}' $SYSXML
	else
		local x=/25 && [ $BOLD -eq 2 ] && x=/50
		local bf && [ $BF -eq 2 ] &&  cp $FONTDIR/bf/bd$x/Italic.ttf $SYSFONT && bf=/rd || { [ $BF -eq 3 ] && bf=/tx; }
		cp $FONTDIR$bf/bf/bd$x/*ttf $SYSFONT
	fi
	ver bld
}

legible() {
	local bf && [ $BF -eq 2 ] && bf=/rd || { [ $BF -eq 3 ] && bf=/tx; } 
	cp $FONTDIR$bf/bf/hl/*ttf $SYSFONT
	ver lgbl
}

tracking() {
	local bf && [ $BF -eq 2 ] && cp $FONTFIR/bf/tr/Italic.ttf $SYSFONT || { [ $BF -eq 3 ] && bf=/tx; }
	cp $FONTDIR$bf/bf/tr/*ttf $SYSFONT
	ver trk
}

clean_up() {
	rm -rf $FONTDIR $MODPATH/LICENSE $MODPATH/tools
	rmdir -p $PRDFONT $SYSETC
}

pixel() {
	if [ -f $ORIGDIR/product/fonts/GoogleSans-Regular.ttf ] || [ -f $ORIGDIR/system/product/fonts/GoogleSans-Regular.ttf ]; then
		local dest=$PRDFONT
	elif [ -f $ORIGDIR/system/fonts/GoogleSans-Regular.ttf ]; then
		local dest=$SYSFONT
	fi
	if [ $dest ]; then
		if [ $PART -eq 1 ]; then
			set BoldItalic Bold MediumItalic Medium
			for i do cp $SYSFONT/$i.ttf $dest/GoogleSans-$i.ttf; done
			[ $TRACK -eq 2 ] || [ $BF -eq 3 ] && local tr=/tr
			[ $HF -eq 2 ] && local hf=/rd
			cp $FONTDIR/bf$tr/Italic.ttf $dest/GoogleSans-Italic.ttf
			cp $FONTDIR$hf/bf$tr/Regular.ttf $dest/GoogleSans-Regular.ttf
			if [ $BOLD -ne 0 ]; then
				if [ $BOLD -eq 3 ]; then
					cp $dest/GoogleSans-Medium.ttf $dest/GoogleSans-Regular.ttf
					cp $dest/GoogleSans-MediumItalic.ttf $dest/GoogleSans-Italic.ttf
				else
					local x=/25 && [ $BOLD -eq 2 ] && x=/50
					cp $FONTDIR/bf/bd$x/Italic.ttf $dest/GoogleSans-Italic.ttf
					cp $FONTDIR$hf/bf/bd$x/Regular.ttf $dest/GoogleSans-Regular.ttf
				fi
			fi
		fi
		ver pxl
	else
		false
	fi
}

oxygen() {
	if grep -q OnePlus $SYSXML; then
		if [ -f $ORIGDIR/system/etc/fonts_base.xml ]; then
			local oosxml=$SYSETC/fonts_base.xml
			cp $SYSXML $oosxml
			sed -i "/\"sans-serif\">/,/family>/s/$DEFFONT/Roboto/" $oosxml
		fi
	elif [ -f $ORIGDIR/system/fonts/SlateForOnePlus-Regular.ttf ]; then
		set Black Bold Medium Regular Light Thin
		for i do cp $SYSFONT/$i.ttf $SYSFONT/SlateForOnePlus-$i.ttf; done
		cp $SYSFONT/Regular.ttf $SYSFONT/SlateForOnePlus-Book.ttf
		ver oos
	else
		false
	fi
}

miui() {
	if grep -q miui $SYSXML; then
		if [ $PART -eq 1 ]; then
			sed -i '/"mipro"/,/family>/{/700/s/MiLanProVF/Bold/;/stylevalue="400"/d}' $SYSXML
			sed -i '/"mipro-regular"/,/family>/{/700/s/MiLanProVF/Medium/;/stylevalue="400"/d}' $SYSXML
			sed -i '/"mipro-medium"/,/family>/{/400/s/MiLanProVF/Medium/;/700/s/MiLanProVF/Bold/;/stylevalue/d}' $SYSXML
			sed -i '/"mipro-demibold"/,/family>/{/400/s/MiLanProVF/Medium/;/700/s/MiLanProVF/Bold/;/stylevalue/d}' $SYSXML
			sed -i '/"mipro-semibold"/,/family>/{/400/s/MiLanProVF/Medium/;/700/s/MiLanProVF/Bold/;/stylevalue/d}' $SYSXML
			sed -i '/"mipro-bold"/,/family>/{/400/s/MiLanProVF/Bold/;/700/s/MiLanProVF/Black/;/stylevalue/d}' $SYSXML
			sed -i '/"mipro-heavy"/,/family>/{/400/s/MiLanProVF/Black/;/stylevalue/d}' $SYSXML
		fi	
		sed -i '/"mipro"/,/family>/{/400/s/MiLanProVF/Regular/;/stylevalue="340"/d}' $SYSXML
		sed -i '/"mipro-thin"/,/family>/{/400/s/MiLanProVF/Thin/;/700/s/MiLanProVF/Light/;/stylevalue/d}' $SYSXML
		sed -i '/"mipro-extralight"/,/family>/{/400/s/MiLanProVF/Thin/;/700/s/MiLanProVF/Light/;/stylevalue/d}' $SYSXML
		sed -i '/"mipro-light"/,/family>/{/400/s/MiLanProVF/Light/;/700/s/MiLanProVF/Regular/;/stylevalue/d}' $SYSXML
		sed -i '/"mipro-normal"/,/family>/{/400/s/MiLanProVF/Light/;/700/s/MiLanProVF/Regular/;/stylevalue/d}' $SYSXML
		sed -i '/"mipro-regular"/,/family>/{/400/s/MiLanProVF/Regular/;/stylevalue="340"/d}' $SYSXML
		ver miui
	else
		false
	fi
}

lg() {
	local lg=false
	if grep -q lg-sans-serif $SYSXML; then
		sed -i '/"lg-sans-serif">/,/family>/{/"lg-sans-serif">/!d};/"sans-serif">/,/family>/{/"sans-serif">/!H};/"lg-sans-serif">/G' $SYSXML
		lg=true
	fi
	if [ -f $ORIGDIR/system/etc/fonts_lge.xml ]; then
		false | cp -i $ORIGDIR/system/etc/fonts_lge.xml $SYSETC
		local lgxml=$SYSETC/fonts_lge.xml
		sed -i '/"default_roboto">/,/family>/{s/Roboto-T/T/;s/Roboto-L/L/;s/Roboto-R/R/;s/Roboto-I/I/}' $lgxml
		if [ $PART -eq 1 ]; then
			sed -i '/"default_roboto">/,/family>/{s/Roboto-M/M/;s/Roboto-B/B/}' $lgxml
			[ $BOLD -eq 3 ] && sed -i '/"default_roboto">/,/family>/{/400/d;/>Light\./{N;h;d};/MediumItalic/G}' $lgxml
		fi
		lg=true
	fi
	$lg && ver lg || false
}

samsung() {
	if grep -q Samsung $SYSXML; then
		sed -i 's/SECRobotoLight-//;s/SECCondensed-/Condensed-/' $SYSXML
		[ $PART -eq 1 ] && sed -i 's/SECRobotoLight-Bold/Medium/' $SYSXML
		ver sam
	else
		false
	fi
}

realme() {
	if grep -q COLOROS $SYSXML; then
		if [ -f $ORIGDIR/system/etc/fonts_base.xml ]; then
			local ruixml=$SYSETC/fonts_base.xml
			cp $SYSXML $ruixml
			sed -i "/\"sans-serif\">/,/family>/s/$DEFFONT/Roboto/" $ruixml
		fi
		ver rui
	else
		false
	fi
}

rom() { pixel || oxygen || miui || samsung || lg || realme; }

ver() { sed -i 3"s/$/-$1&/" $MODPROP; }

gsp() {
	local gsp=/data/adb/modules_update/googlesansplus
	[ -d $gsp ] || gsp=/sdcard
	if grep -q -e 'hf-' -e 'hf$' $gsp/module.prop; then
		mv $gsp/system/etc $MODPATH/system
		ver gsp
	else
		false
	fi
}

### SELECTIONS ###
OPTION=false
PART=1
HF=1
BF=1
BOLD=0
LEGIBLE=false
TRACK=1

. $MODPATH/tools/selector.sh

if [ $SEL ]; then
	OPTION=true	
	ui_print "  "
	ui_print "- CUSTOMIZATIONS -"
	sleep 0.5
fi

if $OPTION; then

	if ! gsp; then
		ui_print "  "
		ui_print "- HEADLINE font?"
		ui_print "  $KEY1 = Next Option; $KEY2 = OK"
		ui_print "  "
		ui_print "  1. Default"
		ui_print "  2. Rounded"
		ui_print "  "
		ui_print "  Select:"
		while :; do
			ui_print "  $HF"
			$SEL && HF=$((HF + 1)) || break
			[ $HF -gt 2 ] && HF=1
		done
		ui_print "  "
		ui_print "  Selected: $HF"
		sleep 0.4
	else
		PART=2
	fi

	ui_print "  "
	ui_print "- BODY font?"
	ui_print "  $KEY1 = Next Option; $KEY2 = OK"
	ui_print "  "
	ui_print "  1. Default"
	ui_print "  2. Rounded"
	ui_print "  3. Text"
	ui_print "  "
	ui_print "  Select:"
	while :; do
		ui_print "  $BF"
		$SEL && BF=$((BF + 1)) || break
		[ $BF -gt 3 ] && BF=1
	done
	ui_print "  "
	ui_print "  Selected: $BF"
	sleep 0.4

	ui_print "  "
	ui_print "- Use BOLD font?"
	ui_print "  $KEY1 = Yes; $KEY2 = No"
	ui_print "  "
	$SEL && { BOLD=1; ui_print "  Selected: Yes"; } ||  ui_print "  Selected: No"
	sleep 0.4

	if [ $BOLD -eq 1 ]; then
		ui_print "  "
		ui_print "- How much BOLD?"
		ui_print "  $KEY1 = Next Option; $KEY2 = OK"
		ui_print "  "
		ui_print "  1. Light"
		ui_print "  2. Medium"
		[ $HF -eq $BF ] && ui_print "  3. Strong"
		ui_print "  "
		ui_print "  Select:"
		while :; do
			ui_print "  $BOLD"
			$SEL && BOLD=$((BOLD + 1)) || break
			([ $BOLD -gt 2 ] && [ $HF -ne $BF ] || [ $BOLD -gt 3 ]) && BOLD=1
		done
		ui_print "  "
		ui_print "  Selected: $BOLD"
		sleep 0.4
	fi

	if [ $BOLD -eq 0 ]; then
		ui_print "  "
		ui_print "- Letter-Spacing?"
		ui_print "  $KEY1 = Next Option; $KEY2 = OK"
		ui_print "  "
		ui_print "  1. Default"
		[ $BF -eq 3 ] && ui_print "  2. Decrease"  || ui_print "  2. Increase"
		ui_print "  "
		ui_print "  Select:"
		while :; do
			ui_print "  $TRACK"
			$SEL && TRACK=$((TRACK + 1)) || break
			[ $TRACK -gt 2 ] && TRACK=1
		done
		ui_print "  "
		ui_print "  Selected: $TRACK"
		sleep 0.4
	fi

	if [ $BOLD -eq 0 ] && [ $TRACK -eq 1 ]; then
		ui_print "  "
		ui_print "- High Legibility?"
		ui_print "  $KEY1 = Yes; $KEY2 = No"
		ui_print "  "
		$SEL && { LEGIBLE=true; ui_print "  Selected: Yes"; } || ui_print "  Selected: No"	
		sleep 0.4
	fi

fi #OPTIONS

### INSTALLATION ###
ui_print "  "
ui_print "- Installing"
patch
[ $PART -eq 1 ] && full || ( body; condensed; mono; ver bf )
[ $HF -eq 2 ] || [ $BF -eq 2 ] && rounded
[ $BF -eq 3 ] && text
[ $BOLD -ne 0 ] && bold
$LEGIBLE && legible
[ $TRACK -ne 1 ] && tracking
rom

### CLEAN UP ###
ui_print "- Cleaning up"
clean_up
