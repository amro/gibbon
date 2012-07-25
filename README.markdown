# gibbon

Gibbon is a simple wrapper for MailChimp's [Primary and Export APIs](http://www.mailchimp.com/api).

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

You can also set the environment variable `MC_API_KEY` and Gibbon will use it when you create an instance:

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
    
Or, to fetch a list by name:

    list = gb.lists({:filters => {:list_name => list_name}})

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

In addition to the primary API, you can make calls to the [Export API](http://apidocs.mailchimp.com/export/1.0/) using an instance of GibbonExport.  Given an existing instance of Gibbon, you can request a new GibbonExporter object:

    g = Gibbon.new("your_api_key")
    gibbon_export = g.get_exporter

or you can construct a new object directly:

    gibbon_export = GibbonExport.new("your_api_key")

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

##Thanks

* [Justin Ip](https://github.com/ippy04)
* [elshimone](https://github.com/elshimone)
* [jlxw](https://github.com/jlxw)
* [Jon McCartie](https://github.com/jmccartie)
* [Calvin Yu](https://github.com/cyu)
* [Dave Worth](https://github.com/daveworth)
* [Mike Skalnik](https://github.com/skalnik)
* [Kristopher Murata](https://github.com/krsmurata)
* [Michael Klishin](https://github.com/michaelklishin)
* Rails for camelize gsub

##Copyright

* Copyright (c) 2010-2012 Amro Mousa. See LICENSE.txt for details.
* MailChimp (c) 2001-2012 The Rocket Science Group.
