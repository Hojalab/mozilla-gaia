#!/bin/bash

source ttk.inc.sh

langs=$(which_langs $*)
release=$(git rev-parse --abbrev-ref HEAD)

if [ x$release == x"master" ]; then
	release=""
	mozilla_repository=http://hg.mozilla.org/gaia-l10n
else
	mozilla_repository=http://hg.mozilla.org/releases/gaia-l10n/$release
fi

function update_hg_repo()
{
	(
	mkdir -p $base_dir/build/locales/$release
	cd $base_dir/build/locales/$release
	if [ -d $mozlang ]; then
		cd $mozlang;
		hg pull;
		hg update;
	else
		hg clone $mozilla_repository/$mozlang $mozlang
	fi
	)
}

for lang in $langs
do
	log_info "Building: $lang"
	if [ "$lang" == "templates" ]; then
		polang=$lang
		mozlang=en-US
		# Update en-US
		update_hg_repo
		
		# Make new template files
		rm $(find $translation_dir/$polang -name "*.pot")
		(cd $base_dir/build/locales/$release/$mozlang; moz2po $verbosity --exclude=".hgtags" --exclude="*.diff" -P . $translation_dir/$polang)
	else
		polang=$(get_language_pootle $lang)
		mozlang=$(get_language_upstream $lang)
		update_hg_repo
		# update against templates
		pot2po $verbosity -t $translation_dir/$polang $translation_dir/templates $translation_dir/$polang
		# new locale files
		po2moz $verbosity --exclude="obsolete" -t $base_dir/build/locales/$release/en-US $translation_dir/$polang $base_dir/build/locales/$release/$mozlang
	fi
done

langs=$(get_language_pootle $langs)
clean_po_location $translation_dir $langs
revert_unchanged_po_git $translation_dir $langs
