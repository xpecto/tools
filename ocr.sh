#/bin/bash
# helper for creating searchable pdfs with
# tesseract and pdftk
# checks for special number-stamp on each page to seperate documents  into smaller chunks
# xpecto AG, elha, 2017/01/18

# working dir (gets created and destroyed)
base=/tmp/scan

rm -rf "$base"
mkdir "$base"

counter=1

# for each pdf
for pdf in *.pdf
do
	lastkey=NOTFOUND$counter

	counter=$((counter+1))

	# convert to image (single pages)
	convert -density 300 "$pdf" -type bilevel -compress lzw $base/%03d.tiff

	# barcode and ocr and move to key-folders
	for tiff in $base/*.tiff
	do
		key=`convert -density 300 $tiff -crop 253x579+36+252  -rotate 270 png:- 2>/dev/null | tesseract stdin stdout -psm 11 -c tessedit_char_whitelist=0123456789 -c textord_min_xheight=40 | grep -o '[89]0[0-9][0-9][0-9][0-9]'`
		
		if [ -z "$key" ]; then
			key=`convert -density 300 $tiff -crop 253x579+36+2935 -rotate 270 png:- 2>/dev/null | tesseract stdin stdout -psm 11 -c tessedit_char_whitelist=0123456789 -c textord_min_xheight=40 | grep -o '[89]0[0-9][0-9][0-9][0-9]'`
		fi
		if [ -z "$key" ]; then
			key=`convert -density 300 $tiff -crop 253x579+36+252  -rotate 270 -morphology erode '5x5:1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1' png:- 2>/dev/null | tesseract stdin stdout -psm 11 -c tessedit_char_whitelist=0123456789 -c textord_min_xheight=40 | grep -o '[89]0[0-9][0-9][0-9][0-9]'`
		fi
		if [ -z "$key" ]; then
			key=`convert -density 300 $tiff -crop 253x579+36+2935 -rotate 270 -morphology erode '5x5:1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1' png:- 2>/dev/null | tesseract stdin stdout -psm 11 -c tessedit_char_whitelist=0123456789 -c textord_min_xheight=40 | grep -o '[89]0[0-9][0-9][0-9][0-9]'`
		fi

		if [ -z "$key" ]; then
			key=$lastkey
		fi

		if [ ! -d "$base/$key" ]; then
			mkdir $base/$key
		fi

		target=$base/$key/$(basename "$tiff").pdf

		echo $pdf -- $key -- OCR $target
		tesseract -l deu $tiff "$target" pdf 1>/dev/null 2>&1 &
		
		# stay within folder
		lastkey=$key

	done

	wait
	
	# join pdfs and output with barcode.pdf
	for folder in "$base/"*
	do
		if [ -d "$folder" ]; then
			key=$(basename "$folder")
			echo $folder/*.pdf --> ./$key.pdf
			pdftk $folder/*.pdf cat output ./$key.pdf
		fi
	done

	rm -rf $base/*

done

rm -rf $base

echo "done"

