# gibbon

Gibbon is a simple API wrapper for interacting with [MailChimp API](http://www.mailchimp.com/api) 1.3.

##Installation

    $ gem install gibbon

##Requirements

A MailChimp account and API key. You can see your API keys [here](http://admin.mailchimp.com/account/api).

##Usage

Create an instance of the API wrapper:

    gb = Gibbon::API.new(api_key)

Fetching data is as simple as calling API methods directly on the wrapper object.
Check the API [documentation](http://www.mailchimp.com/api/1.3) for details.

### Fetching Campaigns

For example, to fetch your first 100 campaigns (page 0):

    campaigns = gb.campaigns({:start => 0, :limit => 100})

### Fetching Lists

Similarly, to fetch your first 100 lists:

    lists = gb.lists({:start => 0, :limit=> 100})

### More Advanced Examples

Getting batch member information for subscribers looks like this:

    info = gb.list_member_info({:id => list_id, :email_address => email_array})

or

    info = gb.listMemberInfo({:id => list_id, :email_address => email_array})

Fetch open and click detail for recipients of a particular campaign:

    email_stats = gb.campaign_email_stats_aim({:cid => campaign_id, :email_address => email_array})

or

    email_stats = gb.campaignEmailStatsAIM({:cid => campaign_id, :email_address => email_array})

### Other Stuff

Gibbon defaults to a 30 second timeout. You can optionally set your own timeout (in seconds) like so:

    gb.timeout = 5

### Notes

As of 0.1.6, gibbon uses ActiveSupport::JSON.decode(). This means code that checked for weird API responses (like "true"
on a successful call to "listSubscribe" or similar) will need to be tweaked to handle the boolean JSON.decode() returns
as opposed to the string the MailChimp API returns. I understand the extra dependency might be a pain for some.

##Thanks

* [Justin Ip](https://github.com/ippy04)
* [elshimone](https://github.com/elshimone)
* [jlxw](https://github.com/jlxw)
* [Jon McCartie](https://github.com/jmccartie)
* Rails for camelize gsub

##Copyrights

* Copyright (c) 2010 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2010 The Rocket Science Group.