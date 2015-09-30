#!/bin/bash

VAGRANT_DIR="/vagrant"
cd $VAGRANT_DIR

echo "configuring store settings"

    # "show_on_front:page"\
    # "page_on_front:5"\
for setting in \
    "blogname:TechnoTan Staging"\
    "blogdescription:The TechnoTan Staging Site"\
    "date_format:F j, Y"\
    "time_format:g:i a"\
    "links_updated_date_format: F j, Y g:i a"\
    "permalink_structure:/%postname%/"\
    "woocommerce_default_country:AU:WA"\
    "woocommerce_demo_store:yes"\
    "woocommerce_currency:AUD"\
    "woocommerce_currency_pos:left"\
    "woocommerce_price_thousand_sep:,"\
    "woocommerce_price_decimal_sep:."\
    "woocommerce_price_num_decimals:2"\
    "woocommerce_weight_unit:kg"\
    "woocommerce_dimension_unit:mm"\
; do
    key=${setting%%:*}
    value=${setting#*:}
    sudo -u vagrant wp option update $key "$value"
done

echo "deploying zipped plugins"
sudo apt-get -q -y install unzip
for type in "plugins" "themes"; do
    for file in $(ls zips/$type); do
        slug=${file%\.*}
        if [ ! -d "content/$type/$slug" ]; then
            mkdir "content/$type/$slug"
            unzip "zips/$type/$file" -d "content/$type"
            rm -rf "content/$type/__MACOSX"
        fi
    done
done


cd $VAGRANT_DIR/wp

# alias wpv="sudo -u vagrant wp"

echo "setting up languages"
sudo -u vagrant wp --quiet core language install en_AU
sudo -u vagrant wp --quiet core language activate en_AU

echo "setting up plugins"
sudo -u vagrant wp --quiet plugin activate woocommerce lasercommerce tansync
sudo -u vagrant wp --quiet plugin activate jetpack woocommerce-dynamic-pricing woocommerce-memberships

echo "setting up woocommerce"
# sudo -u vagrant wp eval-file ../woocommerce-setup.php
sudo -u vagrant wp eval "

    if (!is_plugin_active ( 'woocommerce/woocommerce.php') ){
        echo 'woocommerce not installed';
    }
    if (! get_option('_wc_installed_pages')) {
        WC_Install::create_pages();
        update_option( '_wc_installed_pages', true );
        echo 'installed woocommerce';
    } else {
        echo 'woocommerce already installed';
    }

"

echo "setting up themes"
sudo -u vagrant wp --quiet theme activate tanvas

echo "setting up users"
for user_string in \
    "wholesale:WN"\
    "wholesalepref:WP"\
    "distributor:DN" \
    "distributorpref:DP"\
; do
    user_id=${user_string%%:*}
    user_tier=${user_string#*:}
    if ! sudo -u vagrant wp --quiet user get $user_id --field=login; then
        sudo -u vagrant wp user create $user_id $user_id@example.com --role=customer --user_pass=$user_id
        sudo -u vagrant wp user meta update $user_id act_role "$user_tier"
    else
        :
    fi;
done
