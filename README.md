# Digital Ocean Dynamic IP Bash Script

We love and highly recommend Digital Ocean for your hosting needs – they have a ton of features and are very fast!

One of the features they provide is the doctl command line utility which allows you to set almost anything you need remotely. A common use case we’ve come across is updating a dynamic IP. In order to do that, we wrote a bash script that you can run manually or schedule with cron.

**Project Homepage:** https://dustysun.com/dynamic-ip-update-for-digital-ocean/
## Digital Ocean API Access

Note that you will need to log in to your Digital Ocean account and create a read/write API key. When you log in, choose API from the left or use this link: https://cloud.digitalocean.com/account/api/

## Adding the doctl command line

You’ll need to have the doctl command installed on your system, which you can do by following the installation steps at the [project home page on GitHub]( https://github.com/digitalocean/doctl/blob/master/README.md).

Our script uses the default path of /snap/bin which would be the doctl path if you install from the Snap, but you can also set the path via the command line options.

## Script Options
There are three required options you must use when calling the script:

~~~~
–domain=<domain_name>
    The name of the domain where the A record lives that will be updated.

–hostname=<record_set>
    The name of the hostname set to update without the domain.

–accesstoken=<docker_api_key>
    Provide your docker API key here.
~~~~

There are also two optional settings:
~~~~
–email=<email_address>
    Optional: Enter an email where the log will be delivered. If no email is provided, the script will not attempt to send an email.

–doctlpath=<path_to_doctl>
    Optional: Enter the path where the doctl command is on your system. It defaults to /snap/bin.
~~~~

## Example Usage

`/opt/scripts/digitalocean-dynamic-ip.sh –domain=yourdomain.com –hostname=dynamichost –accesstoken=your_api_key_here –email=youremail@email.com`

## How to Use with Cron

If you’re on a Linux system, you can run this every 30 minutes (or whatever interval you like) with cron.

Open your crontab for editing with this command:

`sudo crontab -e`

Then add a line like this:

`*/30 * * * * /opt/scripts/digitalocean-dynamic-ip.sh --domain=yourdomain.com --hostname=dynamichost --accesstoken=your_api_key_here --email=youremail@email.com`

## How Did This Work For You?
Do you have any questions on this? Did it work for you? We’d love to hear your feedback! Please leave a comment below or send us an email at [support@dustysun.com](mailto:support@dustysun.com).

# Versions

* v1.1 - 2023-01-23 - Updates for compatibility with python 3.