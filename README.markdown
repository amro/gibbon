# gibbon

Gibbon is a simple API wrapper for interacting with [MailChimp API](http://www.mailchimp.com/api) 1.3.

[![Build Status](https://secure.travis-ci.org/amro/gibbon.png)](http://travis-ci.org/amro/gibbon)

##Installation

    $ gem install gibbon

##Requirements

A MailChimp account and API key. You can see your API keys [here](http://admin.mailchimp.com/account/api).

##Usage

There are a few ways to use Gibbon:

You can create an instance of the API wrapper:

    gb = Gibbon.new("your_api_key")

You can set your api_key globally and call class methods:

    Gibbon.api_key = "your_api_key"
    Gibbon.lists

You can also set the environment variable 'MC_API_KEY' and Gibbon will use it when you create an instance:

    u = Gibbon.new

Fetching data is as simple as calling API methods directly on the wrapper
object.  The API calls may be made with either camelcase or  underscore
separated formatting as you see in the "More Advanced Examples" section below.

Check the API [documentation](http://apidocs.mailchimp.com/api/1.3/) for details.

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

### Export API usage

In addition to the standard API you can make calls to the
[MailChimp Export API](http://apidocs.mailchimp.com/export/1.0/) using a GibbonExport object.  Given an existing
Gibbon object you can request a new GibbonExporter object:

    g = Gibbon.new(@api_key)
    gibbon_export = g.get_exporter

or you can construct a new object directly:

    gibbon_export = GibbonExport.new(@api_key)

Calling Export API functions is identical to making standard API calls but the
return value is an Enumerator which loops over the lines returned from the
Export API.  This is because the data returned from the Export API is a stream
of JSON objects rather than a single JSON array.

### Error handling

By default you are expected to handle errors returned by the APIs manually.  The
APIs will return a Hash with two keys "errors", a string containing some textual
information about the error, and "code", the numeric code of the error.

If you set the `throws_exceptions` boolean attribute for a given instance then
Gibbon will attempt to intercept the errors and raise an exception.

### Notes

As of 0.1.6, gibbon uses ActiveSupport::JSON.decode(). This means code that checked for weird API responses (like "true"
on a successful call to "listSubscribe" or similar) will need to be tweaked to handle the boolean JSON.decode() returns
as opposed to the string the MailChimp API returns. I understand the extra dependency might be a pain for some.

##Thanks

* [Justin Ip](https://github.com/ippy04)
* [elshimone](https://github.com/elshimone)
* [jlxw](https://github.com/jlxw)
* [Jon McCartie](https://github.com/jmccartie)
* [Calvin Yu](https://github.com/cyu)
* [Dave Worth](https://github.com/daveworth)
* [Mike Skalnik](https://github.com/skalnik)
* [Kristopher Murata](https://github.com/krsmurata)
* Rails for camelize gsub

##Copyrights

* Copyright (c) 2010 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2010 The Rocket Science Group.
